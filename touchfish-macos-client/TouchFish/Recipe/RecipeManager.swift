import SwiftUI

struct RecipeManager {
    
    static var recipes: [String:Recipe] = [:]
    
    static private var internalRecipeList = [
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
            icon: Image(systemName: "mail.stack"),
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
    
    static func refresh() {
        recipes.removeAll()
        for recipe in internalRecipeList {
            recipes[recipe.bundleId] = recipe
        }
        Task {
            for recipe in await Storage.searchRecipe() {
                if !recipe.enabled {
                    continue
                }
                if internalRecipeList.map({$0.bundleId}).contains(recipe.bundleId) {
                    Log.warning("load recipe - ignore a recipe: bundledId conflicts with internal recipes, bundleId=\(recipe.bundleId)")
                    continue
                }
                if let existsRecipe = recipes[recipe.bundleId] {
                    if existsRecipe.version == recipe.version {
                        Log.warning("load recipe - ignore a recipe: duplicate version number, bundleId=\(recipe.bundleId)")
                    }
                    if existsRecipe.version < recipe.version {
                        recipes[recipe.bundleId] = recipe
                    }
                } else {
                    recipes[recipe.bundleId] = recipe
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
