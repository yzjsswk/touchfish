import AppKit

struct Cache {
    
    static func start() {
        TagCache.refresh()
        FishCache.refresh()
        ImageCache.refresh()
        refreshTagByTime()
//        refreshFishByTime()
//        refreshImageByTime()
        func refreshTagByTime() {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
                TagCache.refresh()
                refreshImageByTime()
            }
        }
        func refreshFishByTime() {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
                FishCache.refresh()
                refreshFishByTime()
            }
        }
        func refreshImageByTime() {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
                ImageCache.refresh()
                refreshImageByTime()
            }
        }
    }
    
    struct TagCache {
        static var tagMap: [String:Int] = [:]
        
        static func refresh() {
            let hasTagFishList = DB.getFishHasTag()
            var newTagMap: [String:Int] = [:]
            for fish in hasTagFishList {
                for tg in fish.tag {
                    if let cnt = newTagMap[tg] {
                        newTagMap[tg] = cnt + 1
                    } else {
                        newTagMap[tg] = 1
                    }
                }
            }
            tagMap = newTagMap
        }
        
    }
    
    struct FishCache {
        static var fishList: [Fish] = []
        static var totalCount = 0
        static var valueOrDesc: String? = nil { didSet { refresh() } }
        static var identity: String? = nil { didSet { refresh() } }
        static var type: [FishType]? = nil { didSet { refresh() } }
        static var tag: [String]? = nil { didSet { refresh() } }
        static var source: [Source]? = nil { didSet { refresh() } }
        static var isMarked: Bool? = nil { didSet { refresh() } }
        
        static func refresh() {
            Log.debug("fish cache refresh start")
            var res = DB.searchFish(valueOrDesc: valueOrDesc, identity: identity, type: type, tag: tag, source: source, isMarked: isMarked)
            fishList = Array<Fish>(res.prefix(100))
            totalCount = res.count
//            fishList.sort { $0.updateTime > $1.updateTime }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFishList, object: nil)
            }
            Log.debug("fish cache refresh end")
        }
    }

    struct ImageCache {
        static var images: [URL:NSImage] = [:]
        static var totalBytes: Int = 0
        
        static func refresh() {
            var newImages: [URL:NSImage] = [:]
            var newTotalBytes = 0
            let resourcePath = CONFIG.workPath.appendingPathComponent("resource")
            let resources = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath.path)) ?? []
            for resource in resources {
                let curPath = resourcePath.appendingPathComponent(resource)
                if let curData = FileManager.default.contents(atPath: curPath.path),
                   let image = NSImage(data: curData) {
                    newImages[curPath] = image
                    newTotalBytes += curData.count
                }
            }
            images = newImages
            totalBytes = newTotalBytes
        }
        
        static func searchImageByIdentity(identity: String) -> NSImage? {
            if let url = searchURLByIdentity(identity: identity) {
                return images[url]
            }
            return nil
        }
        
        static func searchURLByIdentity(identity: String) -> URL? {
            return images.keys.first(where: { $0.lastPathComponent.starts(with: identity) })
        }
        
    }
    
}
