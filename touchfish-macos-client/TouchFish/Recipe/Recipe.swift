import SwiftUI

struct Recipe {
    
    var host: String
    var port: String
    var bundleId: String
    var author: String
    var version: Int
    var name: String
    var description: String?
    var icon: Image
    var command: String?
    var autoExecute: Bool
    var settings: [Parameter] = []
    var parameters: [Parameter] = []
    var actions: [RecipeAction] = []
    var color: LinearGradient
    var order: Int
    
    struct Parameter: Codable {
        
        enum ParameterType: String, Codable {
            case Text
            case Number
            case Bool
        }
        
        enum ParameterInputer: String, Codable {
            case SingleLineEdit
            case MultLineEdit
            case Choice
            case Check
            case Slide
        }
        
        var name: String
        var type: ParameterType
        var description: String?
        var inputer: ParameterInputer
        var separator: String?
        var options: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case name
            case type = "para_type"
            case description = "desc"
            case inputer
            case separator
            case options
        }
        
    }
    
}

enum RecipeAction: Codable {
    
    case RunShellCommand(command: String, arguments: [String], refreshView: Bool)
    case CopyToClipboard(content: String)
    case BackToMenu
    case HideTouchFish
    case OpenUrl(url: String)
    case ActiveExternalApp(bundleId: String)
    case SetParameter(name: String, value: String)
    
    enum CodingKeys: String, CodingKey {
        case type
        case cmd
        case args
        case refreshView = "refresh_view"
        case content
        case url
        case bundleId = "bundle_id"
        case name
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .RunShellCommand(let command, let arguments, let refreshView):
            try container.encode("run", forKey: .type)
            try container.encode(command, forKey: .cmd)
            try container.encode(arguments, forKey: .args)
            try container.encode(refreshView, forKey: .refreshView)
        case .CopyToClipboard(let content):
            try container.encode("copy", forKey: .type)
            try container.encode(content, forKey: .content)
        case .BackToMenu:
            try container.encode("back", forKey: .type)
        case .HideTouchFish:
            try container.encode("hide", forKey: .type)
        case .OpenUrl(let url):
            try container.encode("open_url", forKey: .type)
            try container.encode(url, forKey: .url)
        case .ActiveExternalApp(let bundleId):
            try container.encode("active_app", forKey: .type)
            try container.encode(bundleId, forKey: .bundleId)
        case .SetParameter(let name, let value):
            try container.encode("set_para", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "run":
            let command = try container.decode(String.self, forKey: .cmd)
            let arguments = try container.decode([String].self, forKey: .args)
            let refreshView = try container.decode(Bool.self, forKey: .refreshView)
            self = .RunShellCommand(command: command, arguments: arguments, refreshView: refreshView)
        case "copy":
            let content = try container.decode(String.self, forKey: .content)
            self = .CopyToClipboard(content: content)
        case "back":
            self = .BackToMenu
        case "hide":
            self = .HideTouchFish
        case "open_url":
            let url = try container.decode(String.self, forKey: .url)
            self = .OpenUrl(url: url)
        case "active_app":
            let bundleId = try container.decode(String.self, forKey: .bundleId)
            self = .ActiveExternalApp(bundleId: bundleId)
        case "set_para":
            let name = try container.decode(String.self, forKey: .name)
            let value = try container.decode(String.self, forKey: .value)
            self = .SetParameter(name: name, value: value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "invalid recipe action type: \(type)")
        }
    }
    
}
