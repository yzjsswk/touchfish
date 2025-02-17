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
    var name: String
    var description: String?
    var icon: String? // system:xxx fish:xxx
    var command: String?
    var autoExecute: Bool
    var settings: [Recipe.Parameter]?
    var parameters: [Recipe.Parameter]?
    var actions: [RecipeAction]?
    var color: String?
    
    enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case author = "author"
        case version = "version"
        case name = "name"
        case description = "description"
        case icon = "icon"
        case command = "command"
        case autoExecute = "auto_execute"
        case settings
        case parameters = "parameters"
        case actions = "actions"
        case color = "color"
    }
    
    func toRecipe(host: String, port: String) -> Recipe? {
        return Recipe(
            host: host,
            port: port,
            bundleId: self.bundleId,
            author: self.author,
            version: self.version,
            name: self.name,
            description: self.description,
            icon: self.icon?.icon ?? Image(systemName: "questionmark"),
            command: self.command,
            autoExecute: self.autoExecute,
            settings: self.settings ?? [],
            parameters: self.parameters ?? [],
            actions: self.actions ?? [],
            color: self.color?.linearGradient ?? Constant.userDefinedRecipeDefaultIemColor
        )
    }
    
}

struct RecipeExecuteResult: Codable {
    
    enum RecipeExecuteStatus: String, Codable {
        case Success
        case Fail
        case Running
    }
    
    var bundleId: String
    var command: String
    var args: [String]
    var stdout: String
    var stderr: String
    var status: RecipeExecuteStatus
    var timeCost: Int
    
    enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case command = "command"
        case args = "args"
        case stdout = "stdout"
        case stderr = "stderr"
        case status = "status"
        case timeCost = "time_cost"
    }
    
}

struct RecipeService {
    
    let host: String
    let port: String
    
    var urlPrefix: String {
        return "http://\(host):\(port)"
    }
    
    func tryConnect(timeoutSecond: TimeInterval = 60) async -> Int? {
        let url = "http://\(host):\(port)/heartbeat"
        guard let url = URL(string: url) else {
            Log.error("RecipeService.tryConnect - failed: url invalid, url=\(url)")
            return nil
        }
        let startTime = Date()
        let res = await AF.request(URLRequest(url: url, timeoutInterval: timeoutSecond)).serializingDecodable(RecipeServiceResponse<NoDataResp>.self).result
        let endTime = Date()
        let timeCost = Int(endTime.timeIntervalSince(startTime)*1000)
        switch res {
        case .success(_):
            return timeCost
        case .failure(let err):
            Log.warning("RecipeService.tryConnect - failed, url=\(url), err=\(err)")
            return nil
        }
    }
    
    func listRecipe() async -> Result<RecipeServiceResponse<[RecipeResp]>, AFError> {
        let url = urlPrefix + "/recipe/list"
        return await AF.request(url).serializingDecodable(RecipeServiceResponse.self).result
    }
    
    func executeRecipe(
        bundleId: String, command: String, arguments: [String], query: String, parameters: [String:String], settings: [String:String]
    ) async -> Result<RecipeServiceResponse<String>, AFError> {
        Log.debug("execute recipe: bundleId=\(bundleId), query=\(query), parameters=\(parameters), settings=\(settings)")
        Metrics.recipeUsageCount[bundleId, default: 0] += 1
        Metrics.save()
        let url = urlPrefix + "/recipe/execute"
        let para: [String:Any?] = [
            "bundle_id": bundleId,
            "command": command,
            "args": arguments,
            "context": [
                "query": query,
                "parameters": parameters,
                "settings": settings,
            ],
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(RecipeServiceResponse.self).result
    }
    
    func fetchExecuteResult(executeUid: String) async -> Result<RecipeServiceResponse<RecipeExecuteResult>, AFError> {
//        Log.debug("fetch execute result: executeUid=\(executeUid)")
        let url = urlPrefix + "/recipe/fetch_result/\(executeUid)"
        return await AF.request(url).serializingDecodable(RecipeServiceResponse.self).result
    }
            
}
