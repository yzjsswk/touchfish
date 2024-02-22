import AppKit
import CryptoKit
import SwiftUI

struct Functions {
    
    static func getDataFromClipboard() -> (FishType, Data, Any)? {
        if let types = NSPasteboard.general.types, types.count > 0 {
            if let str = NSPasteboard.general.string(forType: .string),
               let data = str.data(using: .utf8) {
                return (.text, data, str)
            }
            if let data = NSPasteboard.general.data(forType: types[0]) {
                if let img = NSImage(data: data) {
                    return (.image, data, img)
                }
            }
            Log.warning("data type not supported from clipboard")
            Log.verbose(types)
        }
        return nil
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
    
    static func compressImageByPNG(_ image: NSImage, _ compressionFactor: CGFloat) -> NSImage? {
        guard let imageData = image.tiffRepresentation else {
            return nil
        }
        guard let imageRep = NSBitmapImageRep(data: imageData) else {
            return nil
        }
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: compressionFactor
        ]
        guard let compressedData = imageRep.representation(using: .tiff, properties: properties) else {
            return nil
        }
        return NSImage(data: compressedData)
    }
    
}
