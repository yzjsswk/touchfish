import SwiftUI

struct Recipe {
    
    var host: String? = nil
    var port: String? = nil
    var bundleId: String
    var author: String
    var version: Int
    var name: String
    var description: String?
    var icon: Image
    var command: String?
    var autoExecute: Bool
    var settings: [Parameter] = []
    var parameters: [Parameter] = []
    var actions: [RecipeAction] = []
    var color: LinearGradient
    var order: Int
    
    struct Parameter: Codable {
        
        enum ParameterType: String, Codable {
            case Text
            case Number
            case Bool
        }
        
        enum ParameterInputer: String, Codable {
            case SingleLineEdit
            case MultLineEdit
            case Choice
            case Check
            case Slide
        }
        
        var name: String
        var type: ParameterType
        var description: String?
        var inputer: ParameterInputer
        var separator: String?
        var options: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case name = "name"
            case type = "para_type"
            case description = "desc"
            case inputer = "inputer"
            case separator = "separator"
            case options = "options"
        }
        
    }
    
    func execute() {
        for action in actions {
            action.execute()
        }
    }
    
}

enum RecipeAction: Codable {
    
    case RunShellCommand(command: String, arguments: [String], refreshView: Bool)
    case CopyToClipboard(content: String)
    case BackToMenu
    case HideTouchFish
    case OpenUrl(url: String)
    case ActiveExternalApp(bundleId: String)
    case SetParameter(name: String, value: String)
    
    enum CodingKeys: String, CodingKey {
        case type
        case cmd
        case args
        case refreshView = "refresh_view"
        case content
        case url
        case bundleId = "bundle_id"
        case name
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .RunShellCommand(let command, let arguments, let refreshView):
            try container.encode("run", forKey: .type)
            try container.encode(command, forKey: .cmd)
            try container.encode(arguments, forKey: .args)
            try container.encode(refreshView, forKey: .refreshView)
        case .CopyToClipboard(let content):
            try container.encode("copy", forKey: .type)
            try container.encode(content, forKey: .content)
        case .BackToMenu:
            try container.encode("back", forKey: .type)
        case .HideTouchFish:
            try container.encode("hide", forKey: .type)
        case .OpenUrl(let url):
            try container.encode("open_url", forKey: .type)
            try container.encode(url, forKey: .url)
        case .ActiveExternalApp(let bundleId):
            try container.encode("active_app", forKey: .type)
            try container.encode(bundleId, forKey: .bundleId)
        case .SetParameter(let name, let value):
            try container.encode("set_para", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "run":
            let command = try container.decode(String.self, forKey: .cmd)
            let arguments = try container.decode([String].self, forKey: .args)
            let refreshView = try container.decode(Bool.self, forKey: .refreshView)
            self = .RunShellCommand(command: command, arguments: arguments, refreshView: refreshView)
        case "copy":
            let content = try container.decode(String.self, forKey: .content)
            self = .CopyToClipboard(content: content)
        case "back":
            self = .BackToMenu
        case "hide":
            self = .HideTouchFish
        case "open_url":
            let url = try container.decode(String.self, forKey: .url)
            self = .OpenUrl(url: url)
        case "active_app":
            let bundleId = try container.decode(String.self, forKey: .bundleId)
            self = .ActiveExternalApp(bundleId: bundleId)
        case "set_para":
            let name = try container.decode(String.self, forKey: .name)
            let value = try container.decode(String.self, forKey: .value)
            self = .SetParameter(name: name, value: value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "invalid recipe action type: \(type)")
        }
    }

    func execute() {
        switch self {
        case .RunShellCommand(let command, let arguments, let refreshView):
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
            let context = RecipeExecuteContext(
                query: CommandManager.commandText,
                parameters: RecipeManager.activeRecipeOriginalArg,
                settings: [:]
            )
            Task {
                let executeTime = Date()
                let result = await RecipeService(host: host, port: port).executeRecipe(bundleId: bundleId, command: command, arguments: arguments, context: context)
                let info: DynamicRecipeViewInfo
                var executeUid: String? = nil
                switch result {
                case .success(let resp):
                    if !resp.isOk() {
                        Log.error("request recipe server to execute shell recipe action - fail: resp is not ok, resp.code=\(resp.code), host=\(host), port=\(port), bundleId=\(bundleId), command=\(command)")
                        info = DynamicRecipeViewInfo.error(
                            title: "Commit Recipe Failed",
                            detail: "response from server is not ok, host=\(host), port=\(port), resp.code=\(resp.code) \n resp.msg=\(resp.msg)"
                        )
                    } else {
                        executeUid = resp.data
                        if executeUid != nil {
                            info = DynamicRecipeViewInfo.empty()
                        } else {
                            info = DynamicRecipeViewInfo.error(
                                title: "Lose Recipe Task",
                                detail: "server did not return a recipe execute uid"
                            )
                        }
                    }
                case .failure(let err):
                    Log.error("request recipe server to execute shell recipe action - fail: request recipe server failed, host=\(host), port=\(port), err=\(err), bundleId=\(bundleId), command=\(command)")
                    info = DynamicRecipeViewInfo.error(
                        title: "Network Error",
                        detail: "failed to request recipe server when commiting recipe task, host=\(host), port=\(port) \n err=\(err)"
                    )
                }
                if info.items.count > 0 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .DynamicRecipeViewChanged, object: nil, userInfo: ["info":info, "executeTime":executeTime]
                        )
                    }
                }
                if let executeUid = executeUid {
                    Task {
                        await fetchExecuteResult(host: host, port: port, executeUid: executeUid, executeTime: executeTime, refreshView: refreshView, fetchCount: 0)
                    }
                }
            }
        case .CopyToClipboard(let content):
            if let data = content.data(using: .utf8) {
                Functions.copyDataToClipboard(data: data, type: .Text)
            } else {
                Log.warning("run recipe action: skip copy action: got copy data=nil, recipe=\(RecipeManager.activeRecipe?.bundleId ?? "nil")")
            }
        case .BackToMenu:
            RecipeManager.goToRecipe(recipeId: nil)
        case .HideTouchFish:
            TouchFishApp.deactivate()
        case .OpenUrl(let url):
            // todo: browser config
            AppleScriptRunner.openWebUrl(with: "Google Chrome", url: url)
        case .ActiveExternalApp(let bundleId):
            AppleScriptRunner.showApplication(app: bundleId)
        case .SetParameter(let name, let value):
            RecipeManager.modifyArg(key: name, value: value)
        }
    }
    
}

func fetchExecuteResult(host: String, port: String, executeUid: String, executeTime: Date, refreshView: Bool, fetchCount: Int) async {
    let info: DynamicRecipeViewInfo
    var timeCost: Int? = nil
    var refresh = true
    let result = await RecipeService(host: host, port: port).fetchExecuteResult(executeUid: executeUid)
    switch result {
    case .success(let resp):
        if !resp.isOk() {
            info = DynamicRecipeViewInfo.error(
                    title: "Fetch Result Failed",
                    detail: "response from server is not ok, host=\(host), port=\(port), executeUid=\(executeUid), resp.code=\(resp.code) \n resp.msg=\(resp.msg)"
            )
        } else {
            if let data = resp.data {
                timeCost = data.timeCost
                if data.status == .Fail {
                    info = DynamicRecipeViewInfo.error(
                            title: "Execute Failed",
                            detail: "recipe executing failed, host=\(host), port=\(port), executeUid=\(executeUid) \n stderr=\(data.stderr.prefix(3000))"
                    )
                } else {
                    info = DynamicRecipeViewInfoJsonText.parse(from: data.stdout)
                }
                if data.status == .Running {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        Task {
                            await fetchExecuteResult(host: host, port: port, executeUid: executeUid, executeTime: executeTime, refreshView: refreshView, fetchCount: fetchCount+1)
                        }
                    }
                    if fetchCount % 5 == 0 {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
                            NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
                        NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                    }
                }
            } else {
                if fetchCount < 300 {
                    info = DynamicRecipeViewInfo.empty()
                    refresh = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + getRefreshInterval(fetchCount: fetchCount)) {
                        Task {
                            await fetchExecuteResult(host: host, port: port, executeUid: executeUid, executeTime: executeTime, refreshView: refreshView, fetchCount: fetchCount+1)
                        }
                    }
                } else {
                    info = DynamicRecipeViewInfo.error(
                        title: "Fetch Result Failed",
                        detail: "there is still no data in response after trying 300 times, host=\(host), port=\(port), executeUid=\(executeUid) \n resp.msg=\(resp.msg)"
                    )
                }
            }
        }
    case .failure(let err):
        Log.error("request recipe server to fetch execute result - fail: request recipe server failed, host=\(host), port=\(port), err=\(err), executeUid=\(executeUid)")
        info = DynamicRecipeViewInfo.error(
            title: "Network Error",
            detail: "failed to request recipe server whening fetch execute result, host=\(host), port=\(port) executeUid=\(executeUid) \n err=\(err)"
        )
    }
    if !refresh || !refreshView {
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
