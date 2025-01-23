import AppKit

struct Topic {
    
    static var unreadMsgCount = 0
    
    let uid: String
    let subject: String
    let source: String
    let title: String
    let messages: [Message]
    let extraInfo: [String:String]
    let createTime: String
    let updateTime: String
    
    var infoCount: Int {
        return messages.filter { $0.level == .Info }.count
    }
    
    var warningCount: Int {
        return messages.filter { $0.level == .Warning }.count
    }
    
    var errorCount: Int {
        return messages.filter { $0.level == .Error }.count
    }
    
    var unreadCount: Int {
        return messages.filter { !$0.hasRead }.count
    }
    
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
    let extraInfo: [String:String]
    let createTime: String
    let updateTime: String
    
}

