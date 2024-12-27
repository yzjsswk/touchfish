import SwiftUI

struct DynamicRecipeViewInfo: Codable {
    
    var type: ViewType
    var data: [Data] = []
    var items: [ViewItem] = []

    enum ViewType: String, Codable {
        case Empty
        case Error
        case Text
        case List
        case Card
    }
    
    struct ViewItem: Codable {
        
        struct Property: Codable {
            var name: String
            var value: String
        }
        
        struct Operation: Codable {
            var name: String
            var actions: [RecipeAction]
        }
        
        var data: [Data] = []
        var title: String
        var description: String?
        var iconPattern: String?
        var tags: [String] = []
        var images: [String] = []
        var properties: [Property] = []
        var operations: [Operation] = []
        
        enum CodingKeys: String, CodingKey {
            case title = "title"
            case description = "description"
            case iconPattern = "icon"
            case tags = "tags"
            case images = "images"
            case properties = "properties"
            case operations = "operations"
        }
        
        var icon: Image? {
            guard let pattern = iconPattern else {
                return nil
            }
            guard let image = patternToImage(pattern: pattern) else {
                return Image(systemName: "doc.plaintext")
            }
            return image
        }
        
        func patternToImage(pattern: String) -> Image? {
            let words = pattern.components(separatedBy: "??").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if let icon = words[0].icon {
                return icon
            }
            if words[0].hasPrefix("data:") {
                guard let idx = Int(String(words[0].dropFirst(5))) else {
                    return nil
                }
                if data.count > idx {
                    guard let nsImage = NSImage(data: data[idx]) else {
                        return nil
                    }
                    return Image(nsImage: nsImage)
                }
            }
            if words.count < 2 {
                return nil
            }
            if let icon = words[1].icon {
                return icon
            }
            if words[1].hasPrefix("data:") {
                guard let idx = Int(String(words[1].dropFirst(5))) else {
                    return nil
                }
                if data.count > idx {
                    guard let nsImage = NSImage(data: data[idx]) else {
                        return nil
                    }
                    return Image(nsImage: nsImage)
                }
            }
            return nil
        }
        
    }
    
}


struct DynamicRecipeViewInfoJsonText: Codable {
    
    var type: DynamicRecipeViewInfo.ViewType
    var data: [String] = []
    var items: [DynamicRecipeViewInfo.ViewItem] = []
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case data = "data"
        case items = "items"
    }
    
    static func parse(from jsonText: String) -> DynamicRecipeViewInfo {
        if jsonText.count == 0 {
            return DynamicRecipeViewInfo(type: .Empty)
        }
        guard let data = jsonText.data(using: .utf8) else {
            return DynamicRecipeViewInfo(
                type: .Error,
                items: [DynamicRecipeViewInfo.ViewItem(
                        title: "Recipe output parsing failed, please make sure the output format is correct.",
                        description: String(jsonText.prefix(2000))
                )]
            )
        }
        guard let result = try? JSONDecoder().decode(DynamicRecipeViewInfoJsonText.self, from: data) else {
            return DynamicRecipeViewInfo(
                type: .Error,
                items: [DynamicRecipeViewInfo.ViewItem(
                        title: "Recipe output parsing failed, please make sure the output format is correct.",
                        description: String(jsonText.prefix(2000))
                )]
            )
        }
        var decodedData: [Data] = []
        for (i, d) in result.data.enumerated() {
            guard let cur = Data(base64Encoded: d) else {
                return DynamicRecipeViewInfo(
                    type: .Error,
                    items: [DynamicRecipeViewInfo.ViewItem(
                            title: "Failed to parse data in result, please make sure the data is a base64 encoded string.",
                            description: "pos=\(i), data=\(d.prefix(2000))"
                    )]
                )
            }
            decodedData.append(cur)
        }
        var items: [DynamicRecipeViewInfo.ViewItem] = []
        for var item in result.items {
            item.data = decodedData
            items.append(item)
        }
        return DynamicRecipeViewInfo(
            type: result.type,
            data: decodedData,
            items: items
        )
    }
    
}
