import AppKit
import SwiftUI

class Fish {
    
    enum FishType: String, CaseIterable {
        case Text
        case Image
        case Other
    }
    
    struct DataInfo: Codable {
        let byteCount: Int?
        let charCount: Int?
        let wordCount: Int?
        let rowCount: Int?
        let width: Int?
        let height: Int?
    }
    
    let uid: String
    let identity: String
    let fishType: FishType
    let fishData: Data
    let dataInfo: DataInfo
    let description: String
    let tags: [String]
    let isMarked: Bool
    let isLocked: Bool
    let extraInfo: [String:String]
    let createTime: String
    let updateTime: String
    
    let textData: String?
    let imageData: NSImage?
    
    init(
        uid: String, identity: String, fishType: FishType, fishData: Data,
        dataInfo: DataInfo, description: String, tags: [String], isMarked: Bool, isLocked: Bool,
        extraInfo: [String:String], createTime: String, updateTime: String
    ) {
        self.uid = uid
        self.identity = identity
        self.fishType = fishType
        self.fishData = fishData
        self.dataInfo = dataInfo
        self.description = description
        self.tags = tags
        self.isMarked = isMarked
        self.isLocked = isLocked
        self.extraInfo = extraInfo
        self.createTime = createTime
        self.updateTime = updateTime
        var textData: String? = nil
        var imageData: NSImage? = nil
        switch fishType {
        case .Text:
            textData = String(data: fishData, encoding: .utf8)
        case .Image:
            imageData = NSImage(data: fishData)
        default:
            break
        }
        self.textData = textData
        self.imageData = imageData
    }
    
    func withMark(isMarked: Bool) -> Fish {
        Fish(
            uid: self.uid, identity: self.identity, fishType: self.fishType, fishData: self.fishData, dataInfo: self.dataInfo,
            description: self.description, tags: self.tags, isMarked: isMarked, isLocked: self.isLocked, extraInfo: self.extraInfo,
            createTime: self.createTime, updateTime: self.updateTime
        )
    }
    
    func withLock(isLocked: Bool) -> Fish {
        Fish(
            uid: self.uid, identity: self.identity, fishType: self.fishType, fishData: self.fishData, dataInfo: self.dataInfo,
            description: self.description, tags: self.tags, isMarked: self.isMarked, isLocked: isLocked, extraInfo: self.extraInfo,
            createTime: self.createTime, updateTime: self.updateTime
        )
    }
    
    var defaultLinePreview: String {
        return "\(self.fishType.rawValue):\(self.uid)"
    }
    
    var linePreview: String {
        var ret: String = self.defaultLinePreview
        switch self.fishType {
        case .Text:
            if self.description.count > 0 {
                ret = Functions.getLinePreview(self.description)
                break
            }
            if let textData = self.textData {
                ret = Functions.getLinePreview(textData)
            }
        case .Image:
            if self.description.count > 0 {
                ret = Functions.getLinePreview(self.description)
            }
        default:
            if self.description.count > 0 {
                ret = Functions.getLinePreview(self.description)
            }
        }
        return ret
    }
    
    var fishIcon: Image {
        switch self.fishType {
        case .Text:
            return Image(systemName: "doc.plaintext")
        case .Image:
            return Image(systemName: "photo")
        default:
            return Image(systemName: "fish")
        }
    }
    
    func copyToClipboard() {
        Functions.copyDataToClipboard(data: self.fishData, type: self.fishType)
    }
    
}
