import SwiftUI

struct Storage {
    
    // return if succeed
    static func saveTextFish(value: String, description: String? = nil, source: Source, tag: [String]? = nil, extraInfo: ExtraInfo? = nil, id: Int? = nil) -> Bool {
        let identity = Functions.getMD5(of: value)
        var extraInfo = extraInfo ?? ExtraInfo()
        extraInfo.fillTextInfo(value, description)
        // if id is not nil, do update
        if let id = id {
            return DB.updateFish(of: id, identity: identity, type: .text, value: value, description: description, tag: tag, extraInfo: extraInfo)
        }
        // if (identity, type, source) is not existed, do insert
        let searchRes = DB.searchFish(identity: identity, type: [.text], source: [source])
        if searchRes.isEmpty {
            return DB.addFish(value: value, description: description ?? "", identity: identity, type: .text, source: source, tag: tag ?? [], extraInfo: extraInfo) != nil
        }
        // if (identity, type, source) is existed, update and pin it
        if searchRes.count == 1 {
            return DB.updateFish(of: searchRes[0].id, identity: identity, type: .text, value: value, description: description, tag: tag, source: source, extraInfo: extraInfo)
        }
        Log.warning("(identity=\(identity), type=text, source=\(source) duplicated in database")
        return false;
    }
    
    // return if succeed
    static func saveImageFish(image: NSImage, description: String? = nil, source: Source, tag: [String]? = nil, extraInfo: ExtraInfo? = nil, id: Int? = nil) -> Bool {
        guard let imageData = image.tiffRepresentation else {
            Log.warning("save image fish failed: data of image is nil")
            return false
        }
        guard let savedPath = Storage.saveDataToFile(data: imageData) else {
            Log.warning("save image fish failed: save image to file failed")
            return false
        }
        let value = savedPath.path
        let identity = Functions.getMD5(of: imageData)
        var extraInfo = extraInfo ?? ExtraInfo()
        extraInfo.fillTextInfo(value, description)
        extraInfo.fillImageInfo(image)
        // if id is not nil, do update
        if let id = id {
            return DB.updateFish(of: id, identity: identity, type: .image, value: value, description: description, tag: tag, extraInfo: extraInfo)
        }
        // if (identity, type, source) is not existed, do insert
        let searchRes = DB.searchFish(identity: identity, type: [.image], source: [source])
        if searchRes.isEmpty {
            return DB.addFish(value: value, description: description ?? "", identity: identity, type: .image, source: source, tag: tag ?? [], extraInfo: extraInfo) != nil
        }
        // if (identity, type, source) is existed, update and pin it
        if searchRes.count == 1 {
            return DB.updateFish(of: searchRes[0].id, identity: identity, type: .image, value: value, description: description, tag: tag, source: source, extraInfo: extraInfo)
        }
        Log.warning("(identity=\(identity), type=image, source=\(source) duplicated in database")
        return false;
    }
    
    static func getTextByIdentity(identity: String) -> String? {
        let searchRes = DB.searchFish(identity: identity, type: [.text])
        return searchRes.first?.value
    }
    
    static func getImageByIdentity(identity: String) -> NSImage? {
        if let image = Cache.ImageCache.searchImageByIdentity(identity: identity) {
            return image
        }
        let searchRes = DB.searchFish(identity: identity, type: [.image])
        if let path = searchRes.first?.value, let image = Cache.ImageCache.images[URL(fileURLWithPath: path)] {
            return image
        }
        return nil
    }
    
    static func searchFileURLByIdentity(identity: String) -> URL? {
        let resourcePath = CONFIG.workPath.appendingPathComponent("resource")
        let resources = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath.path)) ?? []
        for resource in resources {
            if resource.starts(with: identity) {
                return resourcePath.appendingPathComponent(resource)
            }
        }
        return nil
    }
    
    static func searchFileURLByIdentityWithCheck(identity: String) -> URL? {
        let resourcePath = CONFIG.workPath.appendingPathComponent("resource")
        let resources = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath.path)) ?? []
        for resource in resources {
            if !resource.starts(with: identity) {
                continue
            }
            let curPath = resourcePath.appendingPathComponent(resource)
            if let curData = Storage.readDataFromFile(of: curPath), Functions.getMD5(of: curData) == identity {
                return curPath
            }
        }
        return nil
    }
    
    static private var lastTs: TimeInterval = Date().timeIntervalSince1970
    static private var saveCount: Int = 0
    static private func fileSaveFrequencyControl() -> Bool {
        let curTs = Date().timeIntervalSince1970
        if curTs - Storage.lastTs > CONFIG.fileSaveLimitInterval {
            Storage.lastTs = curTs
            Storage.saveCount = 0
        }
        if Storage.saveCount > CONFIG.fileSaveLimitCount {
            return false
        }
        Storage.saveCount += 1
        return true
    }
    
    static func saveDataToFile(data: Data) -> URL? {
        let identity = Functions.getMD5(of: data)
        if let existFile = Storage.searchFileURLByIdentityWithCheck(identity: identity) {
            return existFile
        }
        if !Storage.fileSaveFrequencyControl() {
            Log.error("save data to file failed: too frequent")
            return nil
        }
        let savePath = CONFIG.workPath.appendingPathComponent("resource/\(identity)_\(Int(Date().timeIntervalSince1970))")
        do {
            try data.write(to: savePath)
            Cache.ImageCache.refresh()
        } catch {
            Log.error("save data to file failed: \(error)")
            return nil
        }
        return savePath;
    }
    
    // tood: remove
    static func readDataFromFile(of filePath: URL) -> Data? {
        return FileManager.default.contents(atPath: filePath.path)
    }
    
}

