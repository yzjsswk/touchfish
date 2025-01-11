import SwiftUI

struct RecipeManager {
    
    struct RecipeSetting: Codable {
        var serverName: String
        var bundleId: String
        var enable: Bool
        var order: Int
    }
    
    static var recipes: [String:Recipe] = [:]
    static var allRecipes: [String:[Recipe]] = [:]
    static var allRecipesList: [(String, [Recipe])] {
        allRecipes
        .map { ($0.key, $0.key == "Internal" ? $0.value : $0.value.sorted { $0.bundleId < $1.bundleId }) }
        .sorted { $0.0 == "Internal" ? true : $0.0 < $1.0 }
    }
    
    static func isEnable(serverName: String, bundleId: String) -> Bool {
        if serverName == "Internal" {
            return true
        }
        if let setting = RecipeManager.recipeSetting["\(serverName).\(bundleId)"] {
            return setting.enable
        }
        return false
    }
    
    static func canEditSetting(serverName: String, bundleId: String) -> Bool {
        if serverName == "Internal" {
            return false
        }
        let key = "\(serverName).\(bundleId)"
        if let setting = recipeSetting[key], setting.enable {
            return true
        }
        for (s, rl) in allRecipes {
            if s == serverName {
                continue
            }
            for r in rl {
                if r.bundleId == bundleId && isEnable(serverName: s, bundleId: bundleId) {
                    return false
                }
            }
        }
        return true
    }
    
    static var recipeSetting: [String:RecipeSetting] = [:]
    
    static var internalRecipeList = [
        Recipe(
            bundleId: "com.touchfish.RecipeManage",
            author: "yzjsswk",
            version: 0,
            type: .View,
            name: "Recipe Manage",
            icon: Image(systemName: "books.vertical"),
            command: "recipe",
            color: Constant.internalRecipeItemColor,
            order: -600
        ),
        Recipe(
            bundleId: "com.touchfish.Topics",
            author: "yzjsswk",
            version: 0,
            type: .View,
            name: "Topics",
            icon: Image(systemName: "list.bullet.rectangle"),
            command: "topic",
            parameters: [
                Recipe.Parameter(name: "type")
            ],
            color: Constant.internalRecipeItemColor,
            order: -500
        ),
        Recipe(
            bundleId: "com.touchfish.Setting",
            author: "yzjsswk",
            version: 0,
            type: .View,
            name: "Setting",
            icon: Image(systemName: "gearshape"),
            command: "set",
            color: Constant.internalRecipeItemColor,
            order: -400
        ),
        Recipe(
            bundleId: "com.touchfish.Statistics",
            author: "yzjsswk",
            version: 0,
            type: .View,
            name: "Statistics",
            icon: Image(systemName: "chart.line.uptrend.xyaxis.circle.fill"),
            command: "stats",
            color: Constant.internalRecipeItemColor,
            order: -300
        ),
        Recipe(
            bundleId: "com.touchfish.FishRepository",
            author: "yzjsswk",
            version: 0,
            type: .View,
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
                Recipe.Parameter(name: "passed"),
                Recipe.Parameter(name: "sort")
            ],
            color: Constant.internalRecipeItemColor,
            order: -200
        ),
        Recipe(
            bundleId: "com.touchfish.AddFish",
            author: "yzjsswk",
            version: 0,
            type: .View,
            name: "Add Fish",
            icon: Image(systemName: "plus.square"),
            command: "add",
            color: Constant.internalRecipeItemColor,
            order: -100
        ),
    ]
    
    static func readRecipeSetting() {
        recipeSetting = [:]
        if !FileManager.default.fileExists(atPath: TouchFishApp.recipesPath.path) {
            return
        }
        do {
            let data = try Data(contentsOf: TouchFishApp.recipesPath)
            recipeSetting = try JSONDecoder().decode([String:RecipeSetting].self, from: data)
        } catch {
            Log.error("read recipe setting - failed: read recipe setting file failed, path=\(TouchFishApp.recipesPath.path), err=\(error)")
        }
    }
    
    static func saveRecipeSetting() {
        do {
            try JSONEncoder().encode(self.recipeSetting).write(to: TouchFishApp.recipesPath)
        } catch {
            Log.error("save recipe setting - failed, err=\(error)")
        }
    }
    
    static func refresh() {
        readRecipeSetting()
        recipes.removeAll()
        allRecipes.removeAll()
        for recipe in internalRecipeList {
            recipes[recipe.bundleId] = recipe
        }
        allRecipes["Internal"] = internalRecipeList
        Task {
            for server in Config.recipeServiceConfigs {
                if !server.enable {
                    continue
                }
                if server.name == "Internal" {
                    Log.warning("load recipe - ignore recipe server: server name can not be `Internal`")
                    continue
                }
                for recipe in await Storage.searchRecipe(host: server.host, port: server.port) {
                    allRecipes[server.name, default: []].append(recipe)
                    if let setting = recipeSetting["\(server.name).\(recipe.bundleId)"], setting.enable {
                        if recipes.keys.contains(recipe.bundleId) {
                            Log.warning("load recipe - ignore a recipe: bundleId conflicts, bundleId=\(recipe.bundleId), host=\(String(describing: recipe.host)), port=\(String(describing: recipe.port))")
                        } else {
                            var recipe = recipe
                            recipe.host = server.host
                            recipe.port = server.port
                            recipe.order = setting.order
                            recipes[recipe.bundleId] = recipe
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .RecipeRefreshed, object: nil)
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
    
}
