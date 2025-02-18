import SwiftUI

struct RecipeManager {
    
    static var allRecipes: [String:[Recipe]] = [:]
    static var allRecipesList: [(String, [Recipe])] {
        allRecipes
        .map { ($0.key, $0.value.sorted { $0.bundleId < $1.bundleId }) }
        .sorted { $0.0 < $1.0 }
    }
    static var recipes: [String:Recipe] = [:]
    static var orderedRecipeList: [Recipe] {
        var ret: [Recipe] = []
        for bundleId in Config.recipeOrders {
            if let recipe = recipes[bundleId] {
                ret.append(recipe)
            }
        }
        for recipe in recipes.values.sorted(by: { $0.bundleId < $1.bundleId }) {
            if !ret.contains(where: { $0.bundleId == recipe.bundleId }) {
                ret.append(recipe)
            }
        }
        return ret
    }
    
    static func isEnable(bundleId: String) -> Bool {
        return Config.enableRecipes.contains(bundleId)
    }
    
    static func enable(bundleId: String) -> Bool {
        if Config.enableRecipes.contains(bundleId) {
            return true
        }
        Config.enableRecipes.append(bundleId)
        return Config.save()
    }
    
    static func disable(bundleId: String) -> Bool {
        if !Config.enableRecipes.contains(bundleId) {
            return true
        }
        Config.enableRecipes.removeAll(where: { $0 == bundleId })
        return Config.save()
    }
    
    static func refresh() {
        recipes.removeAll()
        allRecipes.removeAll()
        Task {
            for server in Config.recipeServiceConfigs {
                if !server.enable {
                    continue
                }
                for var recipe in await Storage.searchRecipe(host: server.host, port: server.port) {
                    if let settedCommand = Config.recipeCommands[recipe.bundleId] {
                        recipe.command = settedCommand
                    }
                    var existedBundleId: [String] = []
                    if existedBundleId.contains(recipe.bundleId) {
                        // todo: when refresh too fast, this task may execute multiple, causing warning
                        Log.warning("refresh recipe list - ignore a recipe: bundleId conflicts, bundleId=\(recipe.bundleId), host=\(recipe.host), port=\(recipe.port)")
                        continue
                    }
                    allRecipes[server.name, default: []].append(recipe)
                    existedBundleId.append(recipe.bundleId)
                    if isEnable(bundleId: recipe.bundleId) {
                        recipes[recipe.bundleId] = recipe
                    }
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .RecipeRefreshed, object: nil)
            }
        }
    }
    
}
