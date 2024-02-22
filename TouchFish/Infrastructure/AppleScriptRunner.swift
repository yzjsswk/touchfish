import AppKit
import CryptoKit

// todo: file name -> AppleScript
struct AppleScriptRunner {
    
    static func openWebUrl(with browser: String, url: String) {
        AppleScriptRunner.runAppleScriptAsyc(appleScript:
            """
              tell application "\(browser)"
                  activate
                  open location "\(url)"
              end tell
            """
        )
    }
    
    static func doPaste() {
        AppleScriptRunner.runAppleScriptAsyc(appleScript:
            """
                tell application "System Events"
                    keystroke "v" using command down
                end tell
            """
        )
    }
    
    // return result if successed
    static func runAppleScriptSync(appleScript: String) -> String? {
        guard let script = NSAppleScript(source: appleScript) else {
            Log.error("apple script invalid: \(appleScript)")
            return nil
        }
        var errorInfo: NSDictionary?
        let res = script.executeAndReturnError(&errorInfo)
        if let error = errorInfo {
            print("run apple script error: script=\(appleScript) error=\(error)")
            return nil
        } else {
            return res.stringValue
        }
    }
    
    static func runAppleScriptAsyc(appleScript: String) {
        guard let script = NSAppleScript(source: appleScript) else {
            Log.error("apple script invalid: \(appleScript)")
            return
        }
        var errorInfo: NSDictionary?
        DispatchQueue.global().async {
            script.executeAndReturnError(&errorInfo)
        }
        if let error = errorInfo {
            Log.error("run apple script error: script=\(appleScript) error=\(error)")
        }
    }
    
}
