import SwiftUI

// todo: file name and class name -> Configuration; global name -> Config

let CONFIG = Config.it

struct Config: Codable {
    
    static let it = readFromFile()
    
    static let configPath = TouchFishApp.appSupportPath.appendingPathComponent("config.json")
    
    static func readFromFile() -> Config {
        if FileManager.default.fileExists(atPath: Config.configPath.path) {
            do {
                let configData = try Data(contentsOf: Config.configPath)
                return try JSONDecoder().decode(Config.self, from: configData)
            } catch {
                Log.error("Error when read config file, path=\(Config.configPath.path), error=\(error)")
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Configuration Error"
                alert.informativeText = "Something is wrong with your configuration file at: \(Config.configPath.path).\n\n Use default configuration."
                alert.runModal()
                return Config()
            }
        }
        Log.warning("config file \(Config.configPath.path) not found, use default configuration.")
        return Config()
    }
    
    func save() {
        do {
            try JSONEncoder().encode(self).write(to: Config.configPath)
        } catch {
            fatalError("Failed to write the configuration. Error: \n\(error)")
        }
    }
    
    // configuration
    
    var workPath: URL = TouchFishApp.appSupportPath
    var appActiveKeyShortcut: KeyboardShortcut = KeyboardShortcut(key: Key(keyCode: 49), modifiers: [.option], events: [.keyDown])
    var fishRepositoryActiveKeyShortcut: KeyboardShortcut = KeyboardShortcut(key: Key(keyCode: 9), modifiers: [.command,.option], events: [.keyDown])
    var maximumWidth: CGFloat = 775
    var maximumHeight: CGFloat = 600
    var mainBackgroundColor: String = "#ECEEF1"
    var promptBarBackgroundColor: String = "D8D8DB"
    var selectedItemBackgroundColor: String = "#502A70"
    var mainWidth: CGFloat = 800
    var mainHeight: CGFloat = 600
    var promptBarHeight: CGFloat = 40
    var webURLItemHeight: CGFloat = 50
    var processItemWidth: CGFloat = 240
    var processItemHeight: CGFloat = 40
    var fishItemHeight: CGFloat = 24
    var fishItemPreviewLength: Int = 40
    var fileSaveLimitInterval: TimeInterval = 60
    var fileSaveLimitCount: Int = 5
}
