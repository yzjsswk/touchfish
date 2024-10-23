import SwiftUI

struct Recipe {
    
    var location: URL?
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
    var enabled: Bool = true
    
    enum RecipeType: String, Codable {
        case task
        case view
        case commit
    }
    
    struct Parameter: Codable {
        var name: String
        var separator: String?
    }
    
    func execute() {
        for action in actions {
            action.execute()
        }
    }
    
    struct RecipeJson: Codable {
        
        var bundleId: String
        var author: String
        var version: Int
        var type: RecipeType
        var name: String
        var description: String?
        var icon: String? // system:xxx fish:xxx
        var command: String?
        var parameters: [Parameter]?
        var actions: [RecipeAction]?
        var color: String?
        var order: Int?
        var enabled: Bool?
        
        static func parse(recipePath: URL) -> Recipe? {
            guard let recipeJsonData = try? Data(contentsOf: recipePath) else {
                return nil
            }
            guard let recipeJson = try? JSONDecoder().decode(RecipeJson.self, from: recipeJsonData) else {
                return nil
            }
            return Recipe(
                location: recipePath.deletingLastPathComponent(),
                bundleId: recipeJson.bundleId,
                author: recipeJson.author,
                version: recipeJson.version,
                type: recipeJson.type,
                name: recipeJson.name,
                description: recipeJson.description,
                icon: recipeJson.icon?.icon ?? Image(systemName: "frying.pan"),
                command: recipeJson.command,
                parameters: recipeJson.parameters ?? [],
                actions: recipeJson.actions ?? [],
                color: recipeJson.color?.linearGradient ?? Constant.userDefinedRecipeDefaultIemColor,
                order: recipeJson.order ?? 0,
                enabled: recipeJson.enabled ?? true
            )
        }
        
    }
    
}

struct RecipeAction: Codable {
    
    var type: ActionType
    var arguments: [Argument] = []
    
    enum ActionType: String, Codable {
        case back
        case hide
        case copy
        case open
        case shell
    }
    
    struct Argument: Codable {
        var type: ArgumentType
        var value: String?
        
        enum ArgumentType: String, Codable {
            case plain
            case para
            case commandBarText
            case file
            case context
        }
        
        func getValue() -> String {
            switch type {
            case .plain:
                return value ?? ""
            case .para:
                if let value = value {
                    return RecipeManager.activeRecipeOriginalArg[value, default: ""]
                }
                return ""
            case .commandBarText:
                return CommandManager.commandText
            case .file:
                if let value = value, let location = RecipeManager.activeRecipe?.location {
                    return location.appendingPathComponent(value).path
                }
                return ""
            case .context:
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
        case .back:
            RecipeManager.goToRecipe(recipeId: nil)
        case .hide:
            TouchFishApp.deactivate()
        case .copy:
            if let data = arguments.first?.getValue().data(using: .utf8) {
                Functions.copyDataToClipboard(data: data, type: .Text)
            } else {
                Log.warning("run recipe action: skip copy action: to copy data=nil, recipe=\(RecipeManager.activeRecipe?.bundleId ?? "nil")")
            }
        case .open:
            if let arg = arguments.first?.getValue(), arg.count > 0 {
                // todo: browser config
                AppleScriptRunner.openWebUrl(with: "Google Chrome", url: arg)
            }
        case .shell:
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
                Log.warning("run recipe action: skip shell action: cmd=nil, recipe=\(RecipeManager.activeRecipe?.bundleId ?? "nil")")
                return
            }
            DispatchQueue.global(qos: .userInteractive).async {
                let startTime = Date()
        //        let executeResultText = Functions.runCommand(cmd: script.executor, args: argments)
                let executeResultText = AppleScriptRunner.doShellScript(cmd: cmd, args: argments)
                let endTime = Date()
                let timeCost = Int(endTime.timeIntervalSince(startTime)*1000)
                if RecipeManager.activeRecipe?.type == .view {
                    var view: UserDefinedRecipeView
                    if let executeResultText = executeResultText {
                        view = UserDefinedRecipeView.parse(jsonText: executeResultText)
                    } else {
                        view = UserDefinedRecipeView(type: .empty)
                    }
                    view.timeCost = timeCost
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .UserDefinedRecipeViewChanged, object: nil, userInfo: ["view":view])
                    }
                }
                if let executeResultData = executeResultText?.data(using: .utf8) {
                    do {
                        let message = try JSONDecoder().decode(RecipeSendMessageInfo.self, from: executeResultData)
                        MessageCenter.send(level: message.level, title: message.title, content: message.content, source: message.source)
                    } catch {
                        // do nothing
                    }
                }
                Log.debug("execute shell command: \(cmd) \(argments), timeCost=\(timeCost)")
            }
        }
    }
    
}

struct RecipeSendMessageInfo: Codable {
    
    var level: MessageCenter.Message.MessageLevel
    var content: String
    var title: String?
    var source: String?
    
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

struct RecipeManager {
    
    static var recipes: [String:Recipe] = [:]
    
    static func refresh() {
        recipes.removeAll()
        for recipe in internalRecipeList {
            recipes[recipe.bundleId] = recipe
        }
        for dir in Config.recipeDirectorys {
            for fileURL in Functions.getAllFiles(in: dir) {
                if !(fileURL.lastPathComponent == "recipe.json") {
                    continue
                }
                guard let recipe = Recipe.RecipeJson.parse(recipePath: fileURL) else {
                    Log.warning("load recipe - ignore a recipe: RecipeJson.parse return nil, path=\(fileURL.path)")
                    continue
                }
                if !recipe.enabled {
                    continue
                }
                if internalRecipeList.map({$0.bundleId}).contains(recipe.bundleId) {
                    Log.warning("load recipe - ignore a recipe: bundledId conflicts with internal recipes, bundleId=\(recipe.bundleId), path=\(fileURL.path)")
                    continue
                }
                if let existsRecipe = recipes[recipe.bundleId] {
                    if existsRecipe.version == recipe.version {
                        Log.warning("load recipe - ignore a recipe: duplicate version number, bundleId=\(recipe.bundleId), ignored path = \(fileURL.path)")
                    }
                    if existsRecipe.version < recipe.version {
                        recipes[recipe.bundleId] = recipe
                    }
                } else {
                    recipes[recipe.bundleId] = recipe
                }
            }
        }
    }
    
    static var orderedRecipeList: [Recipe] {
        return recipes.values.sorted(by: {
            if $0.order == $1.order {
                return $0.bundleId < $1.bundleId
            }
            return $0.order < $1.order
        })
    }
    
    static private var activeRecipeId: String? = nil
    static private var activeRecipeArguments: [String:String] = [:]
    static private var activeRecipeArgumentsAddOrder: [String] = []
    
    static var activeRecipe: Recipe? {
        guard let activeRecipeId = activeRecipeId else {
            return nil
        }
        return recipes[activeRecipeId]
    }
    
    static var activeRecipeOriginalArg: [String:String] {
        return activeRecipeArguments
    }
    
    static var activeRecipeArg: [String:[String]] {
        var ret: [String:[String]] = [:]
        guard let args = activeRecipe?.parameters else {
            return ret
        }
        for arg in args {
            if let value = activeRecipeArguments[arg.name] {
                if let separator = arg.separator {
                    ret[arg.name] = value.split(separator: separator).map{ String($0) }
                } else {
                    ret[arg.name] = [value]
                }
            }
        }
        return ret
    }
    
    static var activeRecipeAddOrderArg: [(String, String)] {
        var ret: [(String, String)] = []
        for k in activeRecipeArgumentsAddOrder {
            if let v = activeRecipeArguments[k] {
                ret.append((k, v))
            }
        }
        return ret
    }
    
    static var activeRecipeOrderedValue: [String] {
        if let activeRecipe = activeRecipe {
            return activeRecipe.parameters.map { activeRecipeArguments[$0.name, default: ""] }
        }
        return []
    }
 
    static func goToRecipe(recipeId: String?) {
        activeRecipeId = recipeId
        activeRecipeArguments.removeAll()
        activeRecipeArgumentsAddOrder.removeAll()
        NotificationCenter.default.post(name: .RecipeStatusChanged, object: nil)
    }
    
    static func addArg(key: String, value: String) {
        if let validArgs = activeRecipe?.parameters.map({$0.name}),
           validArgs.contains(key),
           !activeRecipeArguments.keys.contains(key) {
            activeRecipeArguments[key] = value
            activeRecipeArgumentsAddOrder.append(key)
            NotificationCenter.default.post(name: .RecipeStatusChanged, object: nil)
        }
    }
    
    static func delArg(key: String) {
        activeRecipeArguments.removeValue(forKey: key)
        activeRecipeArgumentsAddOrder.removeAll {$0 == key}
        NotificationCenter.default.post(name: .RecipeStatusChanged, object: nil)
    }
    
    static func delLastArg() {
        if let lastKey = activeRecipeArgumentsAddOrder.last {
            activeRecipeArguments.removeValue(forKey: lastKey)
            activeRecipeArgumentsAddOrder.removeLast()
            NotificationCenter.default.post(name: .RecipeStatusChanged, object: nil)
        }
    }
    
    static private var internalRecipeList = [
        Recipe(
            bundleId: "com.touchfish.FishRepository",
            author: "yzjsswk",
            version: 0,
            type: .view,
            name: "Fish Repository",
            description: "master your information",
            icon: Image(systemName: "fish"),
            command: "fish",
            parameters: [
                Recipe.Parameter(name: "identity"),
                Recipe.Parameter(name: "type", separator: ","),
                Recipe.Parameter(name: "tag", separator: ","),
                Recipe.Parameter(name: "marked"),
                Recipe.Parameter(name: "locked"),
                Recipe.Parameter(name: "sort")
            ],
            color: Constant.internalRecipeItemColor,
            order: -600
        ),
        Recipe(
            bundleId: "com.touchfish.AddFish",
            author: "yzjsswk",
            version: 0,
            type: .view,
            name: "Add Fish",
            icon: Image(systemName: "plus.square"),
            command: "add",
            color: Constant.internalRecipeItemColor,
            order: -500
        ),
        Recipe(
            bundleId: "com.touchfish.Setting",
            author: "yzjsswk",
            version: 0,
            type: .view,
            name: "Setting",
            icon: Image(systemName: "gearshape"),
            command: "set",
            color: Constant.internalRecipeItemColor,
            order: -400
        ),
        Recipe(
            bundleId: "com.touchfish.MessageCenter",
            author: "yzjsswk",
            version: 0,
            type: .view,
            name: "Message Center",
            icon: Image(systemName: "ellipsis.message"),
            command: "msg",
            parameters: [
                Recipe.Parameter(name: "level")
            ],
            color: Constant.internalRecipeItemColor,
            order: -300
        ),
        Recipe(
            bundleId: "com.touchfish.Statistics",
            author: "yzjsswk",
            version: 0,
            type: .view,
            name: "Statistics",
            icon: Image(systemName: "chart.line.uptrend.xyaxis.circle.fill"),
            command: "stats",
            color: Constant.internalRecipeItemColor,
            order: -200
        ),
        Recipe(
            bundleId: "com.touchfish.RecipeStore",
            author: "yzjsswk",
            version: 0,
            type: .view,
            name: "Recipe Store",
            icon: Image(systemName: "books.vertical"),
            command: "store",
            color: Constant.internalRecipeItemColor,
            order: -100
        ),
    ]
    
}

