import AppKit
import CryptoKit
import SwiftUI
import Cocoa

struct Constant {
    
    static let mainWindowTabBarHeight: CGFloat = 45
    static let mainWindowWindowButtonAreaWidth: CGFloat = 80
    
    static let mainWidth: CGFloat = 800
    static let mainHeight: CGFloat = 600
    static let sideWidth: CGFloat = 250
    static let commandBarHeight: CGFloat = 40
    static let commandFieldHeight: CGFloat = 28
    static let userDefinedRecipeItemHeight: CGFloat = 50
    static let recipeItemHeight: CGFloat = 40
    static let recipeItemSelectedHeight: CGFloat = 55
    static let fishItemHeight: CGFloat = 24
    static let fishItemIconWidth: CGFloat = 20
    static let fishItemPreviewLength: CGFloat = 40
    static let fishDetailItemHeight: CGFloat = 10
    static let messageItemHeight: CGFloat = 60
    
//    static let commandBarBackgroundColor = Functions.makeLinearGradient(colors: ["D8E0FE", "EBEDFE"])
    static let commandBarBackgroundColor = Functions.makeLinearGradient(colors: ["F0F1FD"])
    static let tagBackgroundColor = Functions.makeLinearGradient(colors: ["C5D2FA", "CACEFB"])
    static let mainBackgroundColor = Functions.makeLinearGradient(colors: ["#FDFDFD"])
//    static let selectedItemBackgroundColor = Functions.makeLinearGradient(colors: ["5E71F9", "6077F7", "6A9EF8"])
    static let selectedItemBackgroundColor = Functions.makeLinearGradient(colors: ["5B5BCF"])
//        static let selectedItemBackgroundColor = Functions.makeLinearGradient(colors: ["F0F0F3"])
    static let internalRecipeItemColor = Functions.makeLinearGradient(colors: ["D8D8DB"])
    static let userDefinedRecipeDefaultIemColor = Functions.makeLinearGradient(colors: ["D8D8DB"])
    static let unreadMessageTipColor = Functions.makeLinearGradient(colors: ["E2503F"])
    static let mainTextColor = "1D2024"
    
    static let maxDataSizeAddFish = 1024 * 1024 * 10 // 10MB
    
}

struct Functions {
    
    static func makeLinearGradient(colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
    
    static func makeLinearGradient(colors: [Color], start: UnitPoint, end: UnitPoint) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
    }
    
    static func makeLinearGradient(colors: [String]) -> LinearGradient {
        LinearGradient(colors: colors.map { $0.color }, startPoint: .top, endPoint: .bottom)
    }
    
    static func makeLinearGradient(colors: [String], start: UnitPoint, end: UnitPoint) -> LinearGradient {
        LinearGradient(colors: colors.map { $0.color }, startPoint: start, endPoint: end)
    }
    
    static func getDataFromClipboard() -> (Fish.FishType, Data, Any)? {
        if let types = NSPasteboard.general.types, types.count > 0 {
            if let str = NSPasteboard.general.string(forType: .string),
               let data = str.data(using: .utf8) {
                return (.Text, data, str)
            }
            if let data = NSPasteboard.general.data(forType: types[0]) {
                if let img = NSImage(data: data) {
                    return (.Image, data, img)
                }
            }
            // reach here would repeat logging
//            Log.warning("get data from clipboard - return nil: data type not supported, types=\(types)")
        }
        return nil
    }
    
    static func copyDataToClipboard(data: Data, type: Fish.FishType) {
        switch type {
        case .Text:
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setData(data, forType: .string)
        case .Image:
            NSPasteboard.general.declareTypes([.tiff], owner: nil)
            NSPasteboard.general.setData(data, forType: .tiff)
        default:
            Log.warning("copy data to clipboard - fail: unsupported fish type, type=\(type)")
        }
    }
    
    static func getMD5(of string: String) -> String {
        let data = Data(string.utf8)
        return Functions.getMD5(of: data)
    }
    
    static func getMD5(of filePath: URL) -> String? {
        do {
            let data = try Data(contentsOf: filePath)
            return Functions.getMD5(of: data)
        } catch {
            Log.error("read data of file error: \(error)")
            return nil
        }
    }
    
    static func getMD5(of data: Data) -> String {
        let hashedData = Insecure.MD5.hash(data: data)
        let hashString = hashedData.map { String(format: "%02hhx", $0) }.joined()
        return hashString
    }
    
    static func getLinePreview(_ text: String) -> String {
        let firstLine = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n", omittingEmptySubsequences: false).first ?? ""
        return String(firstLine)
    }
    
    static func descByteCount(_ byteCount: Int) -> String {
        if byteCount < 1024 {
            return "\(byteCount)B"
        }
        let KBCount = byteCount / 1024
        if KBCount < 1024 {
            return "\(KBCount)KB"
        }
        let MBCount = KBCount / 1024
        if MBCount < 1024 {
            return "\(MBCount)MB"
        }
        let GBCount = Double(MBCount) / 1024
        return "\(GBCount)GB"
    }
    
    static func descTimeInterval(_ millSec: Int) -> String {
        if millSec < 1000 {
            return "\(millSec) ms"
        }
        var s = millSec / 1000
        let ms = millSec % 1000
        if s < 60 {
            return ms == 0 ? "\(s) s" : "\(s)s \(ms)ms"
        }
        let min = s / 60
        s = min % 60
        if min < 60 {
            return s == 0 ? "\(min) m" : "\(min)m \(s)s"
        }
        let h = min / 60
        s = min % 60
        return min == 0 ? "\(h) h" : "\(h)h \(min)m"
    }
    
    static func runCommand(cmd: String, args: [String] = []) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cmd)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            if let data = try pipe.fileHandleForReading.readToEnd() {
                return String(data: data, encoding: .utf8)
            }
        } catch {
            Log.error("runCommand - fail: \(error)")
        }
        return nil
    }
    
    static func runCommandAsync(cmd: String, args: [String] = [], completion: @escaping (String?) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cmd)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.terminationHandler = { _ in
            do {
                if let data = try pipe.fileHandleForReading.readToEnd() {
                    let res = String(data: data, encoding: .utf8)
                    completion(res)
                }
            } catch {
                Log.error("runCommand - fail: \(error)")
            }
        }
        do {
            try process.run()
        } catch {
            Log.error("runCommand - fail: \(error)")
            completion(nil)
        }
    }
    
    static func getFileSize(atPath path: String) -> UInt64? {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? UInt64 {
                return fileSize
            } else {
                return nil
            }
        } catch {
            Log.error("Functions.getFileSize - fail: \(error)")
            return nil
        }
    }
    
    static func doAlert(type: NSAlert.Style, title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = type
        alert.messageText = title
        alert.informativeText = message
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            Log.debug("here")
            alert.icon = appIcon
        }
        alert.runModal()
    }
    
    static func getCurrentDateString(format: String) -> String {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let dateString = dateFormatter.string(from: currentDate)
        return dateString
    }
    
    static func convertIsoDateToE8(_ isoDateString: String) -> String? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let date = isoFormatter.date(from: isoDateString) else {
            Log.error("convert iso date to e8 date - failed: parse input date string failed, input=\(isoDateString)")
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return dateFormatter.string(from: date)
    }
    
    static func convertDateToWeek(_ dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month else {
            return nil
        }
        let weekOfMonth = calendar.component(.weekOfMonth, from: date)
        return String(format: "%04d-%02d-W%d", year, month, weekOfMonth)
    }
    
    static func getAllFiles(in directory: URL) -> [URL] {
        var fileURLs: [URL] = []
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for fileURL in contents {
                if fileURL.hasDirectoryPath {
                    fileURLs.append(contentsOf: getAllFiles(in: fileURL))
                } else {
                    fileURLs.append(fileURL)
                }
            }
        } catch {
            print("get files in dirctory - fail: got contentsOfDirectory fail, err=\(error)")
        }
        return fileURLs
    }
    
}

extension String {
    
    var color: Color {
        return Color(self.nsColor)
    }
    
    var linearGradient: LinearGradient {
        LinearGradient(
            colors: self.split(separator: "#").map { String($0).color },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var icon: Image? {
        if self.hasPrefix("system:") {
            let systemIconName = String(self.dropFirst(7))
            return Image(systemName: systemIconName)
        }
        if self.hasPrefix("fish:") {
            let uid = String(self.dropFirst(5))
            if let imageData = Storage.getFishFromCache(uid)?.imageData {
                return Image(nsImage: imageData)
            }
            return nil
        }
        return nil
    }
    
}

extension Notification.Name {
    
    static let MainWindowEnterFullScreen = Notification.Name("MainWindowEnterFullScreen")
    static let MainWindowExitFullScreen = Notification.Name("MainWindowExitFullScreen")
    static let HoverInMainWindowTabBar = Notification.Name("HoverInMainWindowTabBar")
    static let LeftClickInMainWindowTabBar = Notification.Name("LeftClickInMainWindowTabBar")
    static let RightClickInMainWindowTabBar = Notification.Name("RightClickInMainWindowTabBar")
    static let ShouldRemoveRecipeExecutionContext = Notification.Name("ShouldRemoveRecipeExecutionContext")
    static let RecipeExecutionContextChanged = Notification.Name("RecipeExecutionContextChanged")
    
    static let ReturnKeyWasPressed = Notification.Name("ReturnKeyWasPressed")
    static let UpArrowKeyWasPressed = Notification.Name("UpArrowKeyWasPressed")
    static let DownArrowKeyWasPressed = Notification.Name("DownArrowKeyWasPressed")
    static let TabKeyWasPressed = Notification.Name("TabKeyWasPressed")
    static let EscapeKeyWasPressed = Notification.Name("EscapeKeyWasPressed")
    static let SpaceKeyWasPressed = Notification.Name("SpaceKeyWasPressed")
    static let DeleteKeyWasPressed = Notification.Name("DeleteKeyWasPressed")
    static let CommandKeyWasPressed = Notification.Name("CommandKeyWasPressed")
    static let ShouldBack = Notification.Name("ShouldBack")
    static let ShouldRefreshFish = Notification.Name("ShouldRefreshFish")
    static let FishRefreshed = Notification.Name("FishRefreshed")
    static let RecipeRefreshed = Notification.Name("RecipeRefreshed")
    static let RecipeStatusChanged = Notification.Name("RecipeStatusChanged")
    static let CommandBarTextChanged = Notification.Name("CommandBarTextChanged")
    static let CommandBarEndEditing = Notification.Name("CommandBarEndEditing")
    static let CommandBarShouldFocus = Notification.Name("CommandBarShouldFocus")
    static let DynamicRecipeViewChanged = Notification.Name("DynamicRecipeViewChanged")
    static let RecipeCommited = Notification.Name("RecipeCommited")
    static let ShouldRefreshTopic = Notification.Name("ShouldRefreshTopic")
    
    
    func group(_ group: String) -> Notification.Name {
        return Notification.Name("\(group)-\(self.rawValue)")
    }
    
}
