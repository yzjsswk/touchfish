import Foundation
import Alamofire

struct DataServiceResponse<T: Codable>: Codable {
    
    let code: String
    let msg: String
    let data: T?
    
    func isOk() -> Bool {
        return self.code == "OK"
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
            if let fish = fishResp.toEntity() {
                return fish
            }
            Log.warning("SearchFishResp.getFish - ignore a fish: fishResp.toEntity return nil, fishResp.uid = \(fishResp.uid)")
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
    
    let uid: String
    let identity: String
    let fishType: String
    let fishData: String
    let dataInfo: DataInfo
    let description: String
    let tags: [String]
    let isMarked: Bool
    let isLocked: Bool
    let extraInfo: [String:String]
    let createTime: String
    let updateTime: String
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case identity = "identity"
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
    
    func toEntity() -> Fish? {
        guard let fishType = Fish.FishType(rawValue: self.fishType) else {
            Log.warning("FishResp.toEntity - return nil: no such fishType, fishResp.fishType=\(self.fishType), fishResp.uid=\(self.uid)")
            return nil
        }
        guard let fishData = Data(base64Encoded: self.fishData) else {
            Log.warning("FishResp.toEntity - return nil: decode fish data failed, fishResp.uid=\(self.uid)")
            return nil
        }
        let createTime = Functions.convertIsoDateToE8(self.createTime) ?? self.createTime
        let updateTime = Functions.convertIsoDateToE8(self.updateTime) ?? self.updateTime
        return Fish(
            uid: self.uid, identity: self.identity, fishType: fishType, fishData: fishData,
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

struct TopicResp: Codable {
    
    struct ExtraInfo: Codable {
        
        func toEntity() -> Topic.ExtraInfo {
            return Topic.ExtraInfo()
        }
        
    }
    
    let uid: String
    let topicType: String
    let subject: String
    let source: String
    let title: String
    let messages: [MessageResp]
    let extraInfo: TopicResp.ExtraInfo
    let createTime: String
    let updateTime: String
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case topicType = "topic_type"
        case subject = "subject"
        case source = "source"
        case title = "title"
        case messages = "messages"
        case extraInfo = "extra_info"
        case createTime = "create_time"
        case updateTime = "update_time"
    }
    
    func toEntity() -> Topic? {
        guard let topicType = Topic.TopicType(rawValue: self.topicType) else {
            Log.warning("TopicResp.toEntity - return nil: no such topicType, topicResp.topicType=\(self.topicType), topicResp.uid=\(self.uid)")
            return nil
        }
        let messages = self.messages.compactMap { messageResp in
            if let message = messageResp.toEntity() {
                return message
            }
            Log.warning("TopicResp.toEntity - ignore a message: messageResp.toEntity return nil, messageResp.uid = \(messageResp.uid)")
            return nil
        }
        let createTime = Functions.convertIsoDateToE8(self.createTime) ?? self.createTime
        let updateTime = Functions.convertIsoDateToE8(self.updateTime) ?? self.updateTime
        return Topic(
            uid: self.uid, topicType: topicType, subject: self.subject, source: self.source, title: self.title,
            messages: messages, extraInfo: self.extraInfo.toEntity(), createTime: createTime, updateTime: updateTime
        )
    }
    
}

struct MessageResp: Codable {
    
    struct ExtraInfo: Codable {
        
        func toEntity() -> Message.ExtraInfo {
            return Message.ExtraInfo()
        }
        
    }
    
    let uid: String
    let level: String
    let title: String
    let body: String
    let hasRead: Bool
    let extraInfo: MessageResp.ExtraInfo
    let createTime: String
    let updateTime: String
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case level = "level"
        case title = "title"
        case body = "body"
        case hasRead = "has_read"
        case extraInfo = "extra_info"
        case createTime = "create_time"
        case updateTime = "update_time"
    }
    
    func toEntity() -> Message? {
        guard let level = Message.Level(rawValue: self.level) else {
            Log.warning("MessageResp.toEntity - return nil: no such level, messageResp.level=\(self.level), messageResp.uid=\(self.uid)")
            return nil
        }
        let createTime = Functions.convertIsoDateToE8(self.createTime) ?? self.createTime
        let updateTime = Functions.convertIsoDateToE8(self.updateTime) ?? self.updateTime
        return Message(
            uid: self.uid, level: level, title: self.title, body: self.body,
            hasRead: self.hasRead, extraInfo: self.extraInfo.toEntity(),
            createTime: createTime, updateTime: updateTime
        )
    }
}

struct DataService {
    
    static var urlPrefix: String {
        guard let dataServiceConfig = Config.enableDataServiceConfig else {
            return ""
        }
        return "http://\(dataServiceConfig.host):\(dataServiceConfig.port)"
    }
    
    static func tryConnect(host: String, port: String, timeoutSecond: TimeInterval = 60) async -> Int? {
        let url = "http://\(host):\(port)/heartbeat"
        guard let url = URL(string: url) else {
            Log.error("DataService.tryConnect - failed: url invalid, url=\(url)")
            return nil
        }
        let startTime = Date()
        let res = await AF.request(URLRequest(url: url, timeoutInterval: timeoutSecond)).serializingDecodable(DataServiceResponse<NoDataResp>.self).result
        let endTime = Date()
        let timeCost = Int(endTime.timeIntervalSince(startTime)*1000)
        switch res {
        case .success(_):
            return timeCost
        case .failure(let err):
            Log.warning("DataService.tryConnect - failed, url=\(url), err=\(err)")
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
        createAfter: Int64? = nil,
        createBefore: Int64? = nil,
        updateAfter: Int64? = nil,
        updateBefore: Int64? = nil,
        pageNum: Int? = 0,
        pageSize: Int? = 10
    ) async -> Result<DataServiceResponse<SearchFishResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/search"
        let para: [String:Any?] = [
            "fuzzy": fuzzy,
            "identitys": identitys,
            "fish_types": fishTypes?.map { $0.rawValue },
            "desc": description,
            "tags": tags,
            "is_marked": isMarked,
            "is_locked": isLocked,
            "create_after": createAfter,
            "create_before": createBefore,
            "update_after": updateAfter,
            "update_before": updateBefore,
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
        isLocked: Bool? = nil,
        createAfter: Int64? = nil,
        createBefore: Int64? = nil,
        updateAfter: Int64? = nil,
        updateBefore: Int64? = nil
    ) async -> Result<DataServiceResponse<[String]>, AFError> {
        let url = DataService.urlPrefix + "/fish/delect"
        let para: [String:Any?] = [
            "fuzzy": fuzzy,
            "identitys": identitys,
            "fish_types": fishTypes?.map { $0.rawValue },
            "desc": description,
            "tags": tags,
            "is_marked": isMarked,
            "is_locked": isLocked,
            "create_after": createAfter,
            "create_before": createBefore,
            "update_after": updateAfter,
            "update_before": updateBefore,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func pickFish(uid: String) async -> Result<DataServiceResponse<FishResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/pick/\(uid)"
        return await AF.request(url).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func pickFishByIdentity(identity: String) async -> Result<DataServiceResponse<FishResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/pick_by_identity/\(identity)"
        return await AF.request(url).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func addFish(
        fishType: Fish.FishType, fishData: Data, description: String?, tags: [String]?,
        isMarked: Bool?, isLocked: Bool?, extraInfo: [String:String]?
    ) async -> Result<DataServiceResponse<String>, AFError> {
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
        uid: String, description: String? = nil, tags: [String]? = nil, extraInfo: [String:String]? = nil
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/modify"
        let para: [String:Any?] = [
            "uid": uid,
            "desc": description,
            "tags": tags,
            "extra_info": extraInfo,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func expireFish(
        uids: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/expire"
        let para: [String:Any?] = [
            "uids": uids,
            "skip_if_not_exists": skipIfNotExists,
            "skip_if_locked": skipIfLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func markFish(
        uids: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/mark"
        let para: [String:Any?] = [
            "uids": uids,
            "skip_if_not_exists": skipIfNotExists,
            "skip_if_locked": skipIfLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func unMarkFish(
        uids: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/unmark"
        let para: [String:Any?] = [
            "uids": uids,
            "skip_if_not_exists": skipIfNotExists,
            "skip_if_locked": skipIfLocked,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func lockFish(
        uids: [String], skipIfNotExists: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/lock"
        let para: [String:Any?] = [
            "uids": uids,
            "skip_if_not_exists": skipIfNotExists,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func unLockFish(
        uids: [String], skipIfNotExists: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/unlock"
        let para: [String:Any?] = [
            "uids": uids,
            "skip_if_not_exists": skipIfNotExists,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func pinFish(
        uids: [String], skipIfNotExists: Bool = true, skipIfLocked: Bool = true
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/fish/pin"
        let para: [String:Any?] = [
            "uids": uids,
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
    
    static func createTopic(
        topicType: Topic.TopicType, subject: String, source: String, title: String, extraInfo: Topic.ExtraInfo
    ) async -> Result<DataServiceResponse<String>, AFError> {
        let url = DataService.urlPrefix + "/topic/create"
        let para: [String:Any?] = [
            "topic_type": topicType.rawValue,
            "subject": subject,
            "source": source,
            "title": title,
            "extra_info": [:],
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func removeTopic(subject: String) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/topic/remove/\(subject)"
        return await AF.request(url, method: .post).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func listTopic() async -> Result<DataServiceResponse<[TopicResp]>, AFError> {
        let url = DataService.urlPrefix + "/topic/list"
        return await AF.request(url).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func sendMessage(
        topicSubject: String, level: Message.Level, title: String, body: String, hasRead: Bool, extraInfo: Message.ExtraInfo
    ) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/message/send"
        let para: [String:Any?] = [
            "topic_subject": topicSubject,
            "level": level.rawValue,
            "title": title,
            "body": body,
            "has_read": hasRead,
            "extra_info": [:],
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
    static func readMessage(topicUid: String, messageUid: String) async -> Result<DataServiceResponse<NoDataResp>, AFError> {
        let url = DataService.urlPrefix + "/message/read"
        let para: [String:Any?] = [
            "topic_uid": topicUid,
            "message_uid": messageUid,
        ]
        return await AF.request(
            url, method: .post, parameters: para.compactMapValues { $0 }, encoding: JSONEncoding.default
        ).serializingDecodable(DataServiceResponse.self).result
    }
    
}
