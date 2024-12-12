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
    
    func execute() {
        for action in actions {
            action.execute(host: host, port: port)
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
    
    func execute(host: String?, port: String?) {
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
            guard let host = host else {
                Log.warning("run recipe action: skip shell action: host=nil, bundleId=\(bundleId)")
                return
            }
            guard let port = port else {
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
                let startTime = Date()
        //        let executeResultText = Functions.runCommand(cmd: script.executor, args: argments)
//                let executeResultText = AppleScriptRunner.doShellScript(cmd: cmd, args: argments)
                let executeResultText = await Storage.executeRecipe(host: host, port: port, bundleId: bundleId, command: cmd, arguments: arguments)
                let endTime = Date()
                let timeCost = Int(endTime.timeIntervalSince(startTime)*1000)
                if RecipeManager.activeRecipe?.type == .View {
                    var view: UserDefinedRecipeView
                    if let executeResultText = executeResultText {
                        view = UserDefinedRecipeView.parse(jsonText: executeResultText)
                    } else {
                        view = UserDefinedRecipeView(type: .empty)
                    }
                    view.timeCost = timeCost
                    let v = view
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .UserDefinedRecipeViewChanged, object: nil, userInfo: ["view":v])
                    }
                }
                Log.debug("execute shell command: \(cmd) \(arguments), timeCost=\(timeCost)")
            }
        }
    }
    
}

struct UserDefinedRecipeView: Codable {
    
    var type: UserDefinedRecipeViewType
    var defaultItemIcon: String?
    var items: [UserDefinedRecipeViewItem] = []
    var errorMessage: String?
    var timeCost: Int?
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case defaultItemIcon = "default_item_icon"
        case items = "items"
        case errorMessage = "error_message"
        case timeCost = "time_cost"
    }

    enum UserDefinedRecipeViewType: String, Codable {
        case empty
        case error
        case text
        case list1
        case list2
    }
    
    struct UserDefinedRecipeViewItem: Codable {
        var title: String
        var description: String?
        var icon: String?
        var tags: [String]?
        var actions: [RecipeAction]?
    }
    
    static func parse(jsonText: String) -> UserDefinedRecipeView {
        if jsonText.count == 0 {
            return UserDefinedRecipeView(type: .empty)
        }
        guard let data = jsonText.data(using: .utf8) else {
            return UserDefinedRecipeView(type: .error, errorMessage: "Decoded Failed: \n\n \(jsonText)")
        }
        guard let result = try? JSONDecoder().decode(UserDefinedRecipeView.self, from: data) else {
            return UserDefinedRecipeView(type: .error, errorMessage: "Decoded Failed: \n\n \(jsonText)")
        }
        return result
    }
    
}

