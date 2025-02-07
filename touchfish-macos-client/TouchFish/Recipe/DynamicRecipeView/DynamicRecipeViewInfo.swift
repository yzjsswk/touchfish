import SwiftUI

struct DynamicRecipeViewInfo: Codable {
    
    struct Operation: Codable {
        var name: String
        var actions: [RecipeAction]
    }
    
    var items: [ViewItem]
    var data: [Data] = []
    var operations: [Operation] = []
    var enableSelect = false
    
    enum CodingKeys: String, CodingKey {
        case items
        case data
        case operations
        case enableSelect = "enable_select"
    }
    
    enum ViewItem: Codable {
        
        enum Size: String, Codable {
            case Adaptive
            case Small
            case Medium
            case Large
        }
        
        enum HoverEffect: String, Codable {
            case Background
            case Description
            case Expand
        }
        
        struct Property: Codable {
            var name: String
            var value: String
        }
        
        case Info(
            title: String,
            body: String?,
            value: String? = nil,
            selectable: Bool = false
        )
        case Warn(
            title: String,
            body: String?,
            value: String? = nil,
            selectable: Bool = false
        )
        case Error(
            title: String,
            body: String?,
            value: String? = nil,
            selectable: Bool = false
        )
        case Strip(
            size: Size = .Adaptive,
            title: String,
            description: String?,
            iconPattern: String?,
            tags: [String] = [],
            hoverEffects: [HoverEffect] = [],
            operation: Operation? = nil,
            value: String? = nil,
            selectable: Bool = true
        )
        case TextCard(
            size: Size = .Adaptive,
            title: String,
            description: String?,
            iconPattern: String?,
            tags: [String] = [],
            body: String = "",
            properties: [Property] = [],
            showProperties: Bool = false,
            operations: [Operation] = [],
            value: String? = nil,
            selectable: Bool = true
        )
        case ImageCard(
            size: Size = .Adaptive,
            title: String,
            description: String?,
            iconPattern: String?,
            tags: [String] = [],
            imagePatterns: [String] = [],
            properties: [Property] = [],
            showProperties: Bool = false,
            operations: [Operation] = [],
            value: String? = nil,
            selectable: Bool = true
        )
        
        enum CodingKeys: String, CodingKey {
            case type
            case size
            case title
            case body
            case description
            case iconPattern = "icon"
            case tags
            case hoverEffects = "hover_effects"
            case properties
            case showProperties = "show_properties"
            case operation
            case operations
            case imagePatterns = "images"
            case value
            case selectable
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .Info(let title, let body, let value, let selectable):
                try container.encode("info", forKey: .type)
                try container.encode(title, forKey: .title)
                try container.encode(body, forKey: .body)
                try container.encode(value, forKey: .value)
                try container.encode(selectable, forKey: .selectable)
            case .Warn(let title, let body, let value, let selectable):
                try container.encode("warn", forKey: .type)
                try container.encode(title, forKey: .title)
                try container.encode(body, forKey: .body)
                try container.encode(value, forKey: .value)
                try container.encode(selectable, forKey: .selectable)
            case .Error(let title, let body, let value, let selectable):
                try container.encode("error", forKey: .type)
                try container.encode(title, forKey: .title)
                try container.encode(body, forKey: .body)
                try container.encode(value, forKey: .value)
                try container.encode(selectable, forKey: .selectable)
            case .Strip(
                let size, let title, let description, let iconPattern, let tags,
                let hoverEffects, let operation, let value, let selectable
            ):
                try container.encode("strip", forKey: .type)
                try container.encode(size, forKey: .size)
                try container.encode(title, forKey: .title)
                try container.encode(description, forKey: .description)
                try container.encode(iconPattern, forKey: .iconPattern)
                try container.encode(tags, forKey: .tags)
                try container.encode(hoverEffects, forKey: .hoverEffects)
                try container.encode(operation, forKey: .operation)
                try container.encode(value, forKey: .value)
                try container.encode(selectable, forKey: .selectable)
            case .TextCard(
                let size, let title, let description, let iconPattern, let tags,
                let body, let properties, let showProperties, let operations,
                let value, let selectable
            ):
                try container.encode("text_card", forKey: .type)
                try container.encode(size, forKey: .size)
                try container.encode(title, forKey: .title)
                try container.encode(description, forKey: .description)
                try container.encode(iconPattern, forKey: .iconPattern)
                try container.encode(tags, forKey: .tags)
                try container.encode(body, forKey: .body)
                try container.encode(properties, forKey: .properties)
                try container.encode(showProperties, forKey: .showProperties)
                try container.encode(operations, forKey: .operations)
                try container.encode(value, forKey: .value)
                try container.encode(selectable, forKey: .selectable)
            case .ImageCard(
                let size, let title, let description, let iconPattern, let tags,
                let imagePatterns, let properties, let showProperties, let operations,
                let value, let selectable
            ):
                try container.encode("image_card", forKey: .type)
                try container.encode(size, forKey: .size)
                try container.encode(title, forKey: .title)
                try container.encode(description, forKey: .description)
                try container.encode(iconPattern, forKey: .iconPattern)
                try container.encode(tags, forKey: .tags)
                try container.encode(imagePatterns, forKey: .imagePatterns)
                try container.encode(properties, forKey: .properties)
                try container.encode(showProperties, forKey: .showProperties)
                try container.encode(operations, forKey: .operations)
                try container.encode(value, forKey: .value)
                try container.encode(selectable, forKey: .selectable)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "info":
                let title = try container.decode(String.self, forKey: .title)
                let body = try container.decode(String?.self, forKey: .body)
                let value = try container.decode(String?.self, forKey: .value)
                let selectable = try container.decode(Bool.self, forKey: .selectable)
                self = .Info(title: title, body: body, value: value, selectable: selectable)
            case "warn":
                let title = try container.decode(String.self, forKey: .title)
                let body = try container.decode(String?.self, forKey: .body)
                let value = try container.decode(String?.self, forKey: .value)
                let selectable = try container.decode(Bool.self, forKey: .selectable)
                self = .Warn(title: title, body: body, value: value, selectable: selectable)
            case "error":
                let title = try container.decode(String.self, forKey: .title)
                let body = try container.decode(String?.self, forKey: .body)
                let value = try container.decode(String?.self, forKey: .value)
                let selectable = try container.decode(Bool.self, forKey: .selectable)
                self = .Error(title: title, body: body, value: value, selectable: selectable)
            case "strip":
                let size = try container.decode(Size.self, forKey: .size)
                let title = try container.decode(String.self, forKey: .title)
                let description = try container.decode(String?.self, forKey: .description)
                let iconPattern = try container.decode(String?.self, forKey: .iconPattern)
                let tags = try container.decode([String].self, forKey: .tags)
                let hoverEffects = try container.decode([HoverEffect].self, forKey: .hoverEffects)
                let operation = try container.decode(Operation?.self, forKey: .operation)
                let value = try container.decode(String?.self, forKey: .value)
                let selectable = try container.decode(Bool.self, forKey: .selectable)
                self = .Strip(
                    size: size, title: title, description: description,
                    iconPattern: iconPattern, tags: tags, hoverEffects: hoverEffects,
                    operation: operation, value: value, selectable: selectable
                )
            case "text_card":
                let size = try container.decode(Size.self, forKey: .size)
                let title = try container.decode(String.self, forKey: .title)
                let description = try container.decode(String?.self, forKey: .description)
                let iconPattern = try container.decode(String?.self, forKey: .iconPattern)
                let tags = try container.decode([String].self, forKey: .tags)
                let body = try container.decode(String.self, forKey: .body)
                let properties = try container.decode([Property].self, forKey: .properties)
                let showProperties = try container.decode(Bool.self, forKey: .showProperties)
                let operations = try container.decode([Operation].self, forKey: .operations)
                let value = try container.decode(String?.self, forKey: .value)
                let selectable = try container.decode(Bool.self, forKey: .selectable)
                self = .TextCard(
                    size: size, title: title, description: description, iconPattern: iconPattern,
                    tags: tags, body: body, properties: properties, showProperties: showProperties,
                    operations: operations, value: value, selectable: selectable
                )
            case "image_card":
                let size = try container.decode(Size.self, forKey: .size)
                let title = try container.decode(String.self, forKey: .title)
                let description = try container.decode(String?.self, forKey: .description)
                let iconPattern = try container.decode(String?.self, forKey: .iconPattern)
                let tags = try container.decode([String].self, forKey: .tags)
                let imagePatterns = try container.decode([String].self, forKey: .imagePatterns)
                let properties = try container.decode([Property].self, forKey: .properties)
                let showProperties = try container.decode(Bool.self, forKey: .showProperties)
                let operations = try container.decode([Operation].self, forKey: .operations)
                let value = try container.decode(String?.self, forKey: .value)
                let selectable = try container.decode(Bool.self, forKey: .selectable)
                self = .ImageCard(
                    size: size, title: title, description: description, iconPattern: iconPattern,
                    tags: tags, imagePatterns: imagePatterns, properties: properties, showProperties: showProperties,
                    operations: operations, value: value, selectable: selectable
                )
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "invalid view item type: \(type)")
            }
        }
        
//        var id: String {
//            switch self {
//            case .Info(let title, let body, let value, let selectable):
//                return "info\(title)"
//            case .Warn(let title, let body, let value, let selectable):
//                return "warn\(title)"
//            case .Error(let title, let body, let value, let selectable):
//                return "error\(title)"
//            case .Strip(
//                let size, let title, let description, let iconPattern, let tags,
//                let operation, let value, let selectable
//            ):
//                return "strip\(title)"
//            case .TextCard(
//                let size, let title, let description, let iconPattern, let tags,
//                let body, let properties, let showProperties, let operations,
//                let value, let selectable
//            ):
//                return "text_card\(title)"
//            case .ImageCard(
//                let size, let title, let description, let iconPattern, let tags,
//                let imagePatterns, let properties, let showProperties, let operations,
//                let value, let selectable
//            ):
//                return "image_card\(title)"
//            }
//        }

    }
    
    static func empty() -> DynamicRecipeViewInfo {
        return DynamicRecipeViewInfo(items: [])
    }
    
    static func error(title: String, detail: String) -> DynamicRecipeViewInfo {
        return DynamicRecipeViewInfo(items: [.Error(title: title, body: detail)])
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

struct DynamicRecipeViewInfoJsonText: Codable {
    
    var data: [String] = []
    var items: [DynamicRecipeViewInfo.ViewItem] = []
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case items = "items"
    }
    
    static func parse(from jsonText: String) -> DynamicRecipeViewInfo {
        if jsonText.count == 0 {
            return DynamicRecipeViewInfo(items: [])
        }
        guard let data = jsonText.data(using: .utf8) else {
            return DynamicRecipeViewInfo.error(
                title: "Decode View Failed",
                detail: "Failed to decode view, please make sure the format is correct.\nraw=\(String(jsonText.prefix(2000)))"
            )
        }
        let prettyJsonText: String?
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    prettyJsonText = String(data: prettyJsonData, encoding: .utf8)
            } else {
                prettyJsonText = nil
            }
        } catch {
            prettyJsonText = nil
        }
        guard let result = try? JSONDecoder().decode(DynamicRecipeViewInfoJsonText.self, from: data) else {
            return DynamicRecipeViewInfo.error(
                    title: "Decode View Failed",
                    detail: "Failed to decode view, please make sure the format is correct.\n\(String((prettyJsonText ?? jsonText).prefix(2000)))"
            )
        }
        var decodedData: [Data] = []
        for (i, d) in result.data.enumerated() {
            guard let cur = Data(base64Encoded: d) else {
                return DynamicRecipeViewInfo.error(
                        title: "Decode View Failed",
                        detail: "Failed to decode data in view, please make sure the data is a base64 encoded string, index=\(i)\ndata=\(d.prefix(2000))"
                )
            }
            decodedData.append(cur)
        }
        return DynamicRecipeViewInfo(items: result.items, data: decodedData)
    }
    
}
