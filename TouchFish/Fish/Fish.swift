import AppKit
import SwiftUI

enum FishType: String, CaseIterable {
    case text
    case image
}

extension FishType {
    var index: Int? {
        return FishType.allCases.firstIndex { $0 == self }
    }
}

enum Source: String, CaseIterable {
    case clipboard
    case manual
    case process
    case system
}

extension Source {
    var index: Int? {
        return Source.allCases.firstIndex { $0 == self }
    }
}

struct Fish {
    
    var id: Int
    var identity: String
    var type: FishType
    var source: Source
    var value: String
    var description: String
    var tag: [String]
    var isMarked: Bool
    var extraInfo: ExtraInfo
    var createTime: String
    var updateTime: String
    
    var itemPreview: String {
        switch type {
        case .text:
            return extraInfo.linePreview ?? "..."
        case .image:
            return "[image\(id)]"
        }
    }
    
    var sourceAppIcon: Image {
        if let sourceAppIconIdentity = extraInfo.sourceAppIconIdentity, let sourceAppIcon = Storage.getImageByIdentity(identity: sourceAppIconIdentity) {
            return Image(nsImage: sourceAppIcon)
        }
        return Image(systemName: "fish")
    }
    
    func copyToClipboard() {
        switch self.type {
        case .text:
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setData(self.value.data(using: .utf8), forType: .string)
        case .image:
            if let image = Storage.getImageByIdentity(identity: self.identity) {
                NSPasteboard.general.declareTypes([.tiff], owner: nil)
                NSPasteboard.general.setData(image.tiffRepresentation, forType: .tiff)
            } else {
                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setData(self.value.data(using: .utf8), forType: .string)
            }
        }
    }
    
}

struct ExtraInfo: Codable {
    
    static func load(from jsonStr: String) -> ExtraInfo? {
        if jsonStr.isEmpty {
            return ExtraInfo()
        }
        let decoder = JSONDecoder()
        let data = jsonStr.data(using: .utf8)
        if let data = data {
            do {
                return try decoder.decode(ExtraInfo.self, from: data)
            } catch {
                Log.error("extra info decode error: \(error)")
            }
        }
        return nil;
    }
    
    func toJsonString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            Log.error("extra info encode error: \(error)")
        }
        return nil
    }
    
    mutating func fillTextInfo(_ value: String, _ description: String?) {
        let linePreviewText = description ?? value
        let firstLine = linePreviewText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n", omittingEmptySubsequences: false).first ?? ""
        linePreview = firstLine.count < Config.it.fishItemPreviewLength ? String(firstLine) : firstLine.prefix(Config.it.fishItemPreviewLength - 3)+"..."
        charCount = value.count
        wordCount = value.split(separator: " ", omittingEmptySubsequences: false).count
        rowCount = value.split(separator: "\n").count
    }
    
    mutating func fillImageInfo(_ image: NSImage) {
        height = Int(image.size.height)
        width = Int(image.size.width)
        if let tiffRepresentation = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) {
            let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: NSNumber(value: 1.0)]
            if let imageData = bitmapImage.representation(using: .png, properties: properties) {
                let imageSize = Double(imageData.count) / 1024.0 // 图片大小以 KB 为单位
                size = Int(imageSize)
            }
        }
    }
    
    var sourceAppIconIdentity: String?
    var linePreview: String?
    var charCount: Int?
    var wordCount: Int?
    var rowCount: Int?
    var height: Int?
    var width: Int?
    var size: Int?
}

