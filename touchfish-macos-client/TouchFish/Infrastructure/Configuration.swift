import SwiftUI

var Config = Configuration.it

struct Configuration: Codable {
    
    static var it = read()
    
    static func read() -> Configuration {
        if !FileManager.default.fileExists(atPath: TouchFishApp.configPath.path) {
            let defaultConfig = Configuration()
            _ = defaultConfig.save()
            return defaultConfig
        }
        do {
            let configData = try Data(contentsOf: TouchFishApp.configPath)
            return try JSONDecoder().decode(Configuration.self, from: configData)
        } catch {
            Log.error("read config - use default configuration: read config file failed, path=\(TouchFishApp.configPath.path), err=\(error)")
            return Configuration()
        }
    }
    
    func save() -> Bool {
        do {
            try JSONEncoder().encode(self).write(to: TouchFishApp.configPath)
            return true
        } catch {
            Log.error("save config - failed, err=\(error)")
            return false
        }
    }
    
    // configurations
    
    // basic
    enum TFLanguage: String, Codable, CaseIterable, Identifiable {
        
        case English
        
        var id: String { self.rawValue }
        
    }
    var language: TFLanguage = .English
    var appActiveKeyShortcut = KeyboardShortcut(keyCode: 49, modifiers: [.option], events: [.keyDown])
    
    struct DataServerConfig: Codable {
        var name: String
        var host: String
        var port: String
    }
    var dataServiceConfigs: [DataServerConfig] = [DataServerConfig(name: "local", host: "127.0.0.1", port: "56173")]
    var enableDataServiceConfigName = "local"
    var enableDataServiceConfig: DataServerConfig? {
        for config in dataServiceConfigs {
            if config.name == enableDataServiceConfigName {
                return config
            }
        }
        return nil
    }
    
    struct RecipeServerConfig: Codable {
        var name: String
        var host: String
        var port: String
        var enable: Bool
    }
    var recipeServiceConfigs: [RecipeServerConfig] = []
    var enableRecipes: [String] = []
    var recipeSettings: [String:[String:String]] = [:]
    var recipeOrders: [String] = []
    
    var hideQuickExecutionWindowWhenClickOutSideEnable = true
    var paraFieldEnable = false
    var fishSideEnable = false
    var topicSideEnable = false
    
    // fish repository
    var fishRepositoryActiveKeyShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.command, .option], events: [.keyDown])
    var textFishDetailPreviewLength = 1000
    var autoImportedFromClipboard = true
    var fastPasteToFrontmostApplication = false

}
