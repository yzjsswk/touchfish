import Foundation
import Alamofire

struct DataServiceResponse<T: Codable>: Codable {
    
    let status: String
    let data: T?
    
    func isOk() -> Bool {
        return self.status == "Ok"
    }
    
}

struct NoDataResp: Codable {}

struct SearchFishResp: Codable {
    let totalCount: Int
    let pageNum: Int
    let pageSize: Int
    let data: [FishResp]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageNum = "page_num"
        case pageSize = "page_size"
        case data = "data"
    }
    
    func getFish() -> [Fish]? {
        return self.data.compactMap { fishResp in
            if let fish = fishResp.toFish() {
                return fish
            }
            Log.warning("SearchFishResp.getFish - ignore a fish: fishResp.toFish return nil, fishResp.identity = \(fishResp.identity)")
            return nil
        }
    }
    
}

struct FishResp: Codable {
    
    struct DataInfo: Codable {
        let byte_count: Int?
        let char_count: Int?
        let word_count: Int?
        let row_count: Int?
        let width: Int?
        let height: Int?
        
        func toDataInfo() -> Fish.DataInfo {
            Fish.DataInfo(
                byteCount: self.byte_count, charCount: self.char_count, wordCount: self.word_count,
                rowCount: self.row_count, width: self.width, height: self.height
            )
        }
    }
    
    let identity: String
    let count: Int
    let fishType: String
    let fishData: String
    let dataInfo: DataInfo
    let description: String
    let tags: [String]
    let isMarked: Bool
    let isLocked: Bool
    let extraInfo: String
    let createTime: String
    let updateTime: String
    
    enum CodingKeys: String, CodingKey {
        case identity = "identity"
        case count = "count"
        case fishType = "fish_type"
        case fishData = "fish_data"
        case dataInfo = "data_info"
        case description = "desc"
        case tags = "tags"
        case isMarked = "is_marked"
        case isLocked = "is_locked"
        case extraInfo = "extra_info"
        case createTime = "create_time"
        case updateTime = "update_time"
    }
    
    func toFish() -> Fish? {
        guard let fishType = Fish.FishType(rawValue: self.fishType) else {
            Log.warning("FishResp.toFish - return nil: no such fishType, fishResp.fishType=\(self.fishType), fishResp.identity=\(self.identity)")
            return nil
        }
        guard let fishData = Data(base64Encoded: self.fishData) else {
            Log.warning("FishResp.toFish - return nil: decode fish data failed, fishResp.identity=\(self.identity)")
            return nil
        }
        guard let extraInfo = Fish.ExtraInfo.from_json_string(json_str: extraInfo) else {
            Log.warning("FishResp.toFish - return nil: parse extra info failed, fishResp.extraInfo=\(self.extraInfo), fishResp.identity=\(self.identity)")
            return nil
        }
        let createTime = Functions.convertIsoDateToE8(self.createTime) ?? self.createTime
        let updateTime = Functions.convertIsoDateToE8(self.updateTime) ?? self.updateTime
        return Fish(
            identity: self.identity, count: self.count, fishType: fishType, fishData: fishData,
            dataInfo: self.dataInfo.toDataInfo(), description: self.description, tags: self.tags,
            isMarked: self.isMarked, isLocked: self.isLocked, extraInfo: extraInfo,
            createTime: createTime, updateTime: updateTime
        )
    }
    
}

struct CountFishResp: Codable {
    
    let activeCount: Int
    let expiredCount: Int
    let typeCount: [String:Int]
    let tagCount: [String:Int]
    let markedCount: Int
    let unmarkedCount: Int
    let lockedCount: Int
    let unlockedCount: Int
    let dayCount: [String:Int]
    
    enum CodingKeys: String, CodingKey {
        case activeCount = "count__active"
        case expiredCount = "count__expired"
        case typeCount = "count__by_type"
        case tagCount = "count__by_tag"
        case markedCount = "count__marked"
        case unmarkedCount = "count__unmarked"
        case lockedCount = "count__locked"
        case unlockedCount = "count__unlocked"
        case dayCount = "count__by_day"
    }
    
}

struct DataService {
    
    static var urlPrefix: String {
        guard let dataServiceConfig = Config.enableDataServiceConfig else {
            return ""
        }
        return "http://\(dataServiceConfig.host):\(dataServiceConfig.port)"
    }
    
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
            Log.warning("DataService.tryConnect - failed, host=\(host), port = \(port), err=\(err)")
            return nil
        }
    }
    
    static func searchFish(
        fuzzy: String? = nil,
        identitys: [String]? = nil,
        fishTypes: [Fish.FishType]? = nil,
        description: String? = nil,
        tags: [String]? = nil,
        isMarked: Bool? = nil,
        isLocked: Bool? = nil,
        pageNum: Int? = 1,
        pageSize: Int? = 10
    ) async -> Result<DataServiceResponse<SearchFishResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/search"
        let para: [String:Any?] = [
            "fuzzy": fuzzy,
            "identity": identitys,
            "fish_type": fishTypes?.map { $0.rawValue },
            "desc": description,
            "tags": tags,
            "is_marked": isMarked,
            "is_locked": isLocked,
            "page_num": pageNum,
            "page_size": pageSize,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func delectFish(
        fuzzy: String? = nil,
        identitys: [String]? = nil,
        fishTypes: [Fish.FishType]? = nil,
        description: String? = nil,
        tags: [String]? = nil,
        isMarked: Bool? = nil,
        isLocked: Bool? = nil
    ) async -> Result<DataServiceResponse<[String]>, AFError> {
        let url = DataService.urlPrefix + "/fish/delect"
        let para: [String:Any?] = [
            "fuzzy": fuzzy,
            "identity": identitys,
            "fish_type": fishTypes?.map { $0.rawValue },
            "desc": description,
            "tags": tags,
            "is_marked": isMarked,
            "is_locked": isLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func pickFish(identity: String) async -> Result<DataServiceResponse<FishResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/pick/\(identity)"
        return await AF.request(url).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func addFish(
        fishType: Fish.FishType, fishData: Data, description: String?, tags: [String]?,
        isMarked: Bool?, isLocked: Bool?, extraInfo: String?
    ) async -> Result<DataServiceResponse<FishResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/add"
        let data = fishData.base64EncodedString()
        let para: [String:Any?] = [
            "fish_type": fishType.rawValue,
            "fish_data": data,
            "desc": description,
            "tags": tags,
            "is_marked": isMarked,
            "is_locked": isLocked,
            "extra_info": extraInfo,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func modifyFish(
        identity: String, description: String? = nil, tags: [String]? = nil, extraInfo: String? = nil
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/modify"
        let para: [String:Any?] = [
            "identity": identity,
            "desc": description,
            "tags": tags,
            "extra_info": extraInfo,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func expireFish(
        identitys: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/expire"
        let para: [String:Any?] = [
            "identitys": identitys,
            "skip_if_not_exists": skipIfNotExists,
            "skip_if_locked": skipIfLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func markFish(
        identitys: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/mark"
        let para: [String:Any?] = [
            "identitys": identitys,
            "skip_if_not_exists": skipIfNotExists,
            "skip_if_locked": skipIfLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func unMarkFish(
        identitys: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/unmark"
        let para: [String:Any?] = [
            "identitys": identitys,
            "skip_if_not_exists": skipIfNotExists,
            "skip_if_locked": skipIfLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func lockFish(
        identitys: [String], skipIfNotExists: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/lock"
        let para: [String:Any?] = [
            "identitys": identitys,
            "skip_if_not_exists": skipIfNotExists,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func unLockFish(
        identitys: [String], skipIfNotExists: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/unlock"
        let para: [String:Any?] = [
            "identitys": identitys,
            "skip_if_not_exists": skipIfNotExists,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func pinFish(
        identitys: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/pin"
        let para: [String:Any?] = [
            "identitys": identitys,
            "skip_if_not_exists": skipIfNotExists,
            "skip_if_locked": skipIfLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
        
    static func countFish() async -> Result<DataServiceResponse<CountFishResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/count"
        return await AF.request(url).serializingDecodable(DataServiceResponse.self).result
    }
    
}



