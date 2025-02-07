import SwiftUI

class TouchFishApp {
    
    static let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TouchFish")
    static let logPath = appSupportPath.appendingPathComponent("log")
    static let configPath = appSupportPath.appendingPathComponent("config")
    static let metricsPath = appSupportPath.appendingPathComponent("metrics")
    static let recipesPath = appSupportPath.appendingPathComponent("recipes")
    
    static var quickExecutionWindow: QuickExecutionWindow!
    
    static func start() {
        createAppSupportPathIfNotExists()
        SwiftyBeaverLogger.startConsoleLogging(minLevel: .verbose)
        SwiftyBeaverLogger.startFileLogging(minLevel: .verbose, logFileUrl: logPath.appendingPathComponent("log"))
        Monitor.start(type: .showOrHideMainWindowWhenKeyShortCutPressed)
        Monitor.start(type: .openFishRepositoryWhenKeyShortCutPressed)
        Monitor.start(type: .hideMainWindowWhenClickOutside)
        Monitor.start(type: .backWhenAssistiveClick)
        Monitor.start(type: .saveFishWhenClipboardChanges)
        Monitor.start(type: .localKeyBoardPressedAsyncEvent)
        quickExecutionWindow = QuickExecutionWindow()
        TouchFishApp.activate()
        Log.info("application start success")
        Log.debug("support path=\(appSupportPath.path)")
    }
    
    static private func createAppSupportPathIfNotExists() {
        for path in [appSupportPath, logPath] {
            if !FileManager.default.fileExists(atPath: path.path) {
                do {
                    try FileManager.default.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    Functions.doAlert(type: .critical, title: "Error", message: "create application support path failed, path=\(path.path)")
                    TouchFishApp.quit()
                }
            }
        }
    }
    
    static func activate() {
        TouchFishApp.quickExecutionWindow.show()
    }
    
    static func deactivate() {
        TouchFishApp.quickExecutionWindow.hide()
        NSApp.hide(nil)
    }
    
    static func quit() {
        NSApp.terminate(nil)
    }

}
