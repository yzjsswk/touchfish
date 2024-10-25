import Foundation
import SwiftUI
import YFuncSwift

class CommandManager {
    
    static private let commandCommitFlag = Character(" ")
    
    static var commandText = ""
    
    static func update(_ commandBarText: String) -> String {
        guard let (commandPart, suffixPart) =  commandBarText.splitOnce(separator: commandCommitFlag) else {
            return commandBarText
        }
        if RecipeManager.activeRecipe == nil {
            for recipe in RecipeManager.recipes.values {
                if let command = recipe.command, commandPart == command {
                    RecipeManager.goToRecipe(recipeId: recipe.bundleId)
                    return suffixPart
                }
            }
        }
        if let activeRecipe = RecipeManager.activeRecipe,
           let (argmentName, argmentValue) = commandPart.splitOnce(separator: Character(":")) {
            for arg in activeRecipe.parameters.map({$0.name}) {
                if arg != argmentName {
                    continue
                }
                if RecipeManager.activeRecipeArg.keys.contains(arg) {
                    return commandBarText
                }
                RecipeManager.addArg(key: argmentName, value: argmentValue)
                return suffixPart
            }
        }
        return commandBarText
    }
    
    static func removeCell() {
        if RecipeManager.activeRecipeArg.count > 0 {
            RecipeManager.delLastArg()
        } else {
            RecipeManager.goToRecipe(recipeId: nil)
        }
    }
    
}
