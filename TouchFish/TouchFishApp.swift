import SwiftUI
import Carbon.HIToolbox.Events

class TouchFishApp {

    /**
        appSupportPath: /Users/bytedance/Library/Application Support/TouchFish/
         - log/: record log
         - resource/: image file etc.
         - config.json: user configuration (to do)
         - data.db: fish data
     */
    static let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TouchFish")
    static let logPath = TouchFishApp.appSupportPath.appendingPathComponent("log")
    static let resourcePath = TouchFishApp.appSupportPath.appendingPathComponent("resource")
    static let dbPath = TouchFishApp.appSupportPath.appendingPathComponent("data.db")
    
    static var statusBar: StatusBar! // todo: icon, preference action, menu keyshortcut
    static var mainWindow: MainWindow!
    
    static func start() {
        if !FileManager.default.fileExists(atPath: TouchFishApp.appSupportPath.path) {
            try! FileManager.default.createDirectory(at: TouchFishApp.appSupportPath, withIntermediateDirectories: false, attributes: nil)
        }
        if !FileManager.default.fileExists(atPath: TouchFishApp.logPath.path) {
            try! FileManager.default.createDirectory(at: TouchFishApp.logPath, withIntermediateDirectories: false, attributes: nil)
        }
        if !FileManager.default.fileExists(atPath: TouchFishApp.resourcePath.path) {
            try! FileManager.default.createDirectory(at: TouchFishApp.resourcePath, withIntermediateDirectories: false, attributes: nil)
        }
        if !FileManager.default.fileExists(atPath: TouchFishApp.dbPath.path) {
            let DBFileTemplate = Bundle.main.url(forResource: "data", withExtension: "db")!
            try! FileManager.default.copyItem(atPath: DBFileTemplate.path, toPath: TouchFishApp.dbPath.path)
        }
        LogManager.prepare()
        Cache.start()
        TouchFishApp.statusBar = StatusBar() // need init here because static member will not be compute before it been used
        TouchFishApp.mainWindow = MainWindow()
        Monitor.start(type: .showOrHideMainWindowWhenKeyShortCutPressed)
        Monitor.start(type: .openFishRepositoryWhenKeyShortCutPressed)
        Monitor.start(type: .hideMainWindowWhenClickOutside)
        Monitor.start(type: .saveFishWhenClipboardChanges)
        Monitor.start(type: .localKeyBoardPressedAsyncEvent)
        TouchFishApp.activate()
    }
    
    static func activate() {
        LogManager.updateLogFile()
        TouchFishApp.mainWindow.show()
    }
    
    static func deactivate() {
        TouchFishApp.mainWindow.hide()
        NSApp.hide(nil)
    }
    
    static func quit() {
        NSApp.terminate(nil)
    }

}
