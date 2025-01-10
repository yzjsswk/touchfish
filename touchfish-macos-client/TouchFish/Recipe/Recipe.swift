import SwiftUI

struct Recipe {
    
    var host: String? = nil
    var port: String? = nil
    var bundleId: String
    var author: String
    var version: Int
    var type: RecipeType
    var name: String
    var description: String?
    var icon: Image
    var command: String?
    var parameters: [Parameter] = []
    var actions: [RecipeAction] = []
    var color: LinearGradient
    var order: Int
    
    enum RecipeType: String, Codable {
        case Task
        case View
        case Commit
    }
    
    struct Parameter: Codable {
        var name: String
        var separator: String?
    }
    
    var isInternal: Bool {
        for recipe in RecipeManager.internalRecipeList {
            if bundleId == recipe.bundleId {
                return true
            }
        }
        return false
    }
    
    func execute() {
        for action in actions {
            action.execute()
        }
    }
    
}

struct RecipeAction: Codable {
    
    var type: ActionType
    var arguments: [Argument] = []
    
    enum CodingKeys: String, CodingKey {
        case type = "action_type"
        case arguments = "arguments"
    }
    
    enum ActionType: String, Codable {
        case Back
        case Hide
        case Copy
        case Open
        case Show
        case Shell
    }
    
    struct Argument: Codable {
        var type: ArgumentType
        var value: String?
        
        enum CodingKeys: String, CodingKey {
            case type = "arg_type"
            case value = "value"
        }
        
        enum ArgumentType: String, Codable {
            case Plain
            case Para
            case CommandBarText
            case Context
        }
        
        func getValue() -> String {
            switch type {
            case .Plain:
                return value ?? ""
            case .Para:
                if let value = value {
                    return RecipeManager.activeRecipeOriginalArg[value, default: ""]
                }
                return ""
            case .CommandBarText:
                return CommandManager.commandText
            case .Context:
                if let value = value {
                    if value == "host" {
                        return Config.enableDataServiceConfig?.host ?? ""
                    }
                    if value == "port" {
                        return Config.enableDataServiceConfig?.port ?? ""
                    }
                    if value == "support_path" {
                        return TouchFishApp.appSupportPath.path
                    }
                    return ""
                }
                return ""
            }
        }
        
    }
    
    func execute() {
        switch type {
        case .Back:
            RecipeManager.goToRecipe(recipeId: nil)
        case .Hide:
            TouchFishApp.deactivate()
        case .Copy:
            if let data = arguments.first?.getValue().data(using: .utf8) {
                Functions.copyDataToClipboard(data: data, type: .Text)
            } else {
                Log.warning("run recipe action: skip copy action: to copy data=nil, recipe=\(RecipeManager.activeRecipe?.bundleId ?? "nil")")
            }
        case .Open:
            if let arg = arguments.first?.getValue(), arg.count > 0 {
                // todo: browser config
                AppleScriptRunner.openWebUrl(with: "Google Chrome", url: arg)
            }
        case .Show:
            if let arg = arguments.first?.getValue(), arg.count > 0 {
                AppleScriptRunner.showApplication(app: arg)
            }
        case .Shell:
            guard let bundleId = RecipeManager.activeRecipe?.bundleId else {
                Log.warning("run recipe action: skip shell action: bundleId=nil")
                return
            }
            guard let host = RecipeManager.activeRecipe?.host else {
                Log.warning("run recipe action: skip shell action: host=nil, bundleId=\(bundleId)")
                return
            }
            guard let port = RecipeManager.activeRecipe?.port else {
                Log.warning("run recipe action: skip shell action: port=nil, bundleId=\(bundleId)")
                return
            }
            var cmd: String? = nil
            var argments: [String] = []
            for (index, argument) in arguments.enumerated() {
                if index == 0 {
                    cmd = argument.getValue()
                } else {
                    argments.append(argument.getValue())
                }
            }
            guard let cmd = cmd else {
                Log.warning("run recipe action: skip shell action: cmd=nil, bundleId=\(bundleId)")
                return
            }
            let arguments = argments
            Task {
                let executeTime = Date()
                let result = await RecipeService(host: host, port: port).executeRecipe(bundleId: bundleId, command: cmd, arguments: arguments)
                let info: DynamicRecipeViewInfo
                var executeUid: String? = nil
                switch result {
                case .success(let resp):
                    if !resp.isOk() {
                        Log.error("request recipe server to execute shell recipe action - fail: resp is not ok, resp.code=\(resp.code), host=\(host), port=\(port), bundleId=\(bundleId), command=\(cmd)")
                        info = DynamicRecipeViewInfo(
                            type: .Error,
                            items: [DynamicRecipeViewInfo.ViewItem(
                                    title: "Failed to start executing recipe task.",
                                    description: String(resp.msg.prefix(2000))
                            )]
                        )
                    } else {
                        executeUid = resp.data
                        if executeUid != nil {
                            info = DynamicRecipeViewInfo(type: .Empty)
                        } else {
                            info = DynamicRecipeViewInfo(
                                type: .Error,
                                items: [DynamicRecipeViewInfo.ViewItem(
                                        title: "Lose task.",
                                        description: "server did not return a recipe execute uid"
                                )]
                            )
                        }
                    }
                case .failure(let err):
                    Log.error("request recipe server to execute shell recipe action - fail: request recipe server failed, host=\(host), port=\(port), err=\(err), bundleId=\(bundleId), command=\(cmd)")
                    info = DynamicRecipeViewInfo(
                        type: .Error,
                        items: [DynamicRecipeViewInfo.ViewItem(
                                title: "Request server failed.",
                                description: "host=\(host), port=\(port) \n err=\(err)"
                        )]
                    )
                }
                if info.type != .Empty {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .DynamicRecipeViewChanged, object: nil, userInfo: ["info":info, "executeTime":executeTime]
                        )
                    }
                }
                if let executeUid = executeUid {
                    Task {
                        await fetchExecuteResult(host: host, port: port, executeUid: executeUid, executeTime: executeTime, fetchCount: 0)
                    }
                }
            }
        }
    }
    
}

func fetchExecuteResult(host: String, port: String, executeUid: String, executeTime: Date, fetchCount: Int) async {
    let info: DynamicRecipeViewInfo
    var timeCost: Int? = nil
    var refresh = true
    let result = await RecipeService(host: host, port: port).fetchExecuteResult(executeUid: executeUid)
    switch result {
    case .success(let resp):
        if !resp.isOk() {
            info = DynamicRecipeViewInfo(
                type: .Error,
                items: [DynamicRecipeViewInfo.ViewItem(
                        title: "Fetch execute result failed.",
                        description: "host=\(host), port=\(port), executeUid=\(executeUid) \n err=\(resp.msg)"
                )]
            )
        } else {
            if let data = resp.data {
                timeCost = data.timeCost
                if data.status == .Fail {
                    info = DynamicRecipeViewInfo(
                        type: .Error,
                        items: [DynamicRecipeViewInfo.ViewItem(
                                title: "Recipe execute failed.",
                                description: "host=\(host), port=\(port), executeUid=\(executeUid) \n err=\(data.stderr.prefix(2000))"
                        )]
                    )
                } else {
                    info = DynamicRecipeViewInfoJsonText.parse(from: data.stdout)
                }
                if data.status == .Running {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        Task {
                            await fetchExecuteResult(host: host, port: port, executeUid: executeUid, executeTime: executeTime, fetchCount: fetchCount+1)
                        }
                    }
                }
            } else {
                if fetchCount < 300 {
                    info = DynamicRecipeViewInfo(type: .Empty)
                    refresh = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + getRefreshInterval(fetchCount: fetchCount)) {
                        Task {
                            await fetchExecuteResult(host: host, port: port, executeUid: executeUid, executeTime: executeTime, fetchCount: fetchCount+1)
                        }
                    }
                } else {
                    info = DynamicRecipeViewInfo(
                        type: .Error,
                        items: [DynamicRecipeViewInfo.ViewItem(
                                title: "Fetch execute result failed.",
                                description: "host=\(host), port=\(port), executeUid=\(executeUid) \n err=no data in resp"
                        )]
                    )
                }
            }
        }
    case .failure(let err):
        Log.error("request recipe server to fetch execute result - fail: request recipe server failed, host=\(host), port=\(port), err=\(err), executeUid=\(executeUid)")
        info = DynamicRecipeViewInfo(
            type: .Error,
            items: [DynamicRecipeViewInfo.ViewItem(
                    title: "Fetch execute result failed.",
                    description: "host=\(host), port=\(port), executeUid=\(executeUid) \n err=\(err)"
            )]
        )
    }
    if !refresh {
        return
    }
    if let timeCost = timeCost {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .DynamicRecipeViewChanged, object: nil, userInfo: ["info":info, "executeTime":executeTime, "timeCost":timeCost]
            )
        }
    } else {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .DynamicRecipeViewChanged, object: nil, userInfo: ["info":info, "executeTime":executeTime]
            )
        }
    }
    
}

func getRefreshInterval(fetchCount: Int) -> Double {
    if fetchCount < 6 {
        return 0.05 // 50 ms * 6, 300ms
    }
    if fetchCount < 10 {
        return 0.1 // 100 ms * 4, 1s
    }
    if fetchCount < 15 {
        return 0.2 // 200 ms * 5, 2s
    }
    if fetchCount < 31 {
        return 0.5 // 500 ms * 16, 10s
    }
    if fetchCount < 81 {
        return 1 // 1s * 50, 1min
    }
    return 2
}
