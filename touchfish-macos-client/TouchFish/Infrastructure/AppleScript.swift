import AppKit
import CryptoKit

struct AppleScriptRunner {
    
    static func showApplication(app: String) {
        AppleScriptRunner.runAppleScriptAsyc(appleScript:
            """
              tell application "\(app)"
                  activate
              end tell
            """
        )
    }
    
    static func openWebUrl(with browser: String, url: String) {
        let url = url.starts(with: "http") ? url : "https://" + url
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
    
    static func doShellScript(cmd: String, args: [String]) -> String? {
        var script = "do shell script \"\(cmd)\""
        for (idx, arg) in args.enumerated() {
            script = "set arg\(idx) to \"\(arg)\"\n" + script + " &\" \" & quoted form of arg\(idx)"
        }
        return AppleScriptRunner.runAppleScriptSync(appleScript: script)
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
