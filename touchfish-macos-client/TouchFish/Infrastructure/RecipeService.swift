import Foundation
import Alamofire
import SwiftUI

struct RecipeServiceResponse<T: Codable>: Codable {
    
    let code: String
    let msg: String
    let data: T?
    
    func isOk() -> Bool {
        return self.code == "OK"
    }
    
}

struct RecipeResp: Codable {
    
    var bundleId: String
    var author: String
    var version: Int
    var type: Recipe.RecipeType
    var name: String
    var description: String?
    var icon: String? // system:xxx fish:xxx
    var command: String?
    var parameters: [Recipe.Parameter]?
    var actions: [RecipeAction]?
    var color: String?
    var order: Int?
    var enabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case author = "author"
        case version = "version"
        case type = "recipe_type"
        case name = "name"
        case description = "description"
        case icon = "icon"
        case command = "command"
        case parameters = "parameters"
        case actions = "actions"
        case color = "color"
        case order = "order"
        case enabled = "enabled"
    }
    
    func toRecipe() -> Recipe? {
        return Recipe(
            bundleId: self.bundleId,
            author: self.author,
            version: self.version,
            type: self.type,
            name: self.name,
            description: self.description,
            icon: self.icon?.icon ?? Image(systemName: "frying.pan"),
            command: self.command,
            parameters: self.parameters ?? [],
            actions: self.actions ?? [],
            color: self.color?.linearGradient ?? Constant.userDefinedRecipeDefaultIemColor,
            order: self.order ?? 0,
            enabled: self.enabled ?? true
        )
    }
    
}

struct RecipeService {
    
    static var urlPrefix = ""
    
    static func tryConnect(host: String, port: String) async -> Int? {
        let url = "http://\(host):\(port)"
        let startTime = Date()
        let res = await AF.request(url).serializingDecodable(Int.self).result
        let endTime = Date()
        let timeCost = Int(endTime.timeIntervalSince(startTime)*1000)
        switch res {
        case .success(_):
            return timeCost
        case .failure(let err):
            Log.warning("RecipeService.tryConnect - failed, host=\(host), port = \(port), err=\(err)")
            return nil
        }
    }
    
    static func listRecipe() async -> Result<RecipeServiceResponse<[RecipeResp]>, AFError> {
        let url = RecipeService.urlPrefix + "/recipe/list"
        return await AF.request(url).serializingDecodable(RecipeServiceResponse.self).result
    }
    
    static func executeRecipe(
        bundleId: String, command: String, arguments: [String]
    ) async -> Result<RecipeServiceResponse<String>, AFError> {
        let url = RecipeService.urlPrefix + "/recipe/execute"
        let para: [String:Any?] = [
            "bundle_id": bundleId,
            "command": command,
            "args": arguments,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(RecipeServiceResponse.self).result
    }
            
}



