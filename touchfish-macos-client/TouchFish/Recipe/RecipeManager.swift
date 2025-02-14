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
        Task {
            for server in Config.recipeServiceConfigs {
                if !server.enable {
                    continue
                }
                for recipe in await Storage.searchRecipe(host: server.host, port: server.port) {
                    allRecipes[server.name, default: []].append(recipe)
                    if let setting = recipeSetting["\(server.name).\(recipe.bundleId)"], setting.enable {
                        if recipes.keys.contains(recipe.bundleId) {
                            // todo: when refresh too fast, this task may execute multiple, causing warning
                            Log.warning("load recipe - ignore a recipe: bundleId conflicts, bundleId=\(recipe.bundleId), host=\(recipe.host), port=\(recipe.port)")
                        } else {
                            var recipe = recipe
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
    
}
