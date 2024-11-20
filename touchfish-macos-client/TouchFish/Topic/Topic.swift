import AppKit

struct Topic {
    
    enum TopicType: String {
        case Info
        case Warning
        case Error
    }
    
    struct ExtraInfo: Codable {
        
    }
    
    let uid: String
    let topicType: TopicType
    let subject: String
    let source: String
    let title: String
    let messages: [Message]
    let extraInfo: ExtraInfo
    let createTime: String
    let updateTime: String
}

struct Message {
    
    enum Level: String {
        case Info
        case Warning
        case Error
    }
    
    struct ExtraInfo: Codable {
        
    }
    
    let uid: String
    let level: Level
    let title: String
    let body: String
    let hasRead: Bool
    let extraInfo: ExtraInfo
    let createTime: String
    let updateTime: String
    
}

