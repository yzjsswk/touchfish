import SwiftUI

struct MessageCenter {
    
    struct Message: Codable {
        
        enum MessageLevel: String, Codable {
            case info
            case warning
            case error
        }
        
        var uid: String
        var time: String
        var level: MessageLevel
        var content: String
        var hasRead: Bool = false
        var title: String?
        var source: String?
        
    }
    
    static var messages: [Message] = [] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .MessageCenterHasUpdated, object: nil)
            }
        }
    }
    static var showCount: Int = 10
    static var showLevel: Message.MessageLevel? = nil
    static var showLevelMessageCount: Int {
        if let showLevel = showLevel {
            return messages.sorted(by: { $0.time > $1.time }).filter({ $0.level == showLevel }).count
        }
        return messages.count
    }
    static var shouldShowingMessages: [Message] {
        if let showLevel = showLevel {
            return Array(messages.sorted(by: { $0.time > $1.time }).filter({ $0.level == showLevel }).prefix(showCount))
        }
        return Array(messages.sorted(by: { $0.time > $1.time }).prefix(showCount))
    }
    
    static var unreadCount: Int {
        return messages.filter({ !$0.hasRead }).count
    }
    
    static func send(level: Message.MessageLevel, title: String? = nil, content: String, source: String? = nil) {
        messages.append(
            Message(
                uid: UUID().uuidString,
                time: Functions.getCurrentDateString(format: "yyyy-MM-dd HH:mm:ss"),
                level: level,
                content: content,
                title: title,
                source: source
            )
        )
        saveToFile()
    }
    
    static func read(uid: String) {
        if let idx = messages.firstIndex(where: { $0.uid==uid }) {
            messages[idx].hasRead = true
        }
    }
    
    static func remove(uid: String) {
        messages.removeAll(where: { $0.uid == uid })
        saveToFile()
    }
    
    static func removeAllHasRead() {
        messages.removeAll(where: { $0.hasRead })
        saveToFile()
    }
    
    static func readFromFile() {
        if !FileManager.default.fileExists(atPath: TouchFishApp.messagePath.path) {
            return
        }
        do {
            let messageData = try Data(contentsOf: TouchFishApp.messagePath)
            messages = try JSONDecoder().decode([Message].self, from: messageData)
        } catch {
            Log.error("read message file - failed, path=\(TouchFishApp.messagePath.path), err=\(error)")
        }
    }
    
    static func saveToFile() {
        do {
            try JSONEncoder().encode(messages).write(to: TouchFishApp.messagePath)
        } catch {
            Log.error("save message to file - failed, err=\(error)")
        }
    }
    
}
