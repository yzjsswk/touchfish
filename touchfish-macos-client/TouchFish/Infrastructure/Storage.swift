import SwiftUI
import Alamofire

struct Storage {
    
    struct FishCache {
        private var cache: [String:Fish] = [:]
        private var lock = NSLock()
        
        func getFish(_ uid: String) -> Fish? {
            lock.lock()
            defer {
                lock.unlock()
            }
            return cache[uid]
        }
        
        mutating func setFish(_ fish: Fish) {
            lock.lock()
            defer {
                lock.unlock()
            }
            cache[fish.uid] = fish
        }
        
        mutating func batchSetFish(_ fishList: [Fish]) {
            lock.lock()
            defer {
                lock.unlock()
            }
            for fish in fishList {
                cache[fish.uid] = fish
            }
        }
        
        mutating func removeFish(_ uid: String) {
            lock.lock()
            defer {
                lock.unlock()
            }
            cache.removeValue(forKey: uid)
        }
        
        mutating func batchRemoveFish(_ uids: [String]) {
            lock.lock()
            defer {
                lock.unlock()
            }
            for uid in uids {
                cache.removeValue(forKey: uid)
            }
        }
        
        mutating func clear() {
            lock.lock()
            defer {
                lock.unlock()
            }
            cache.removeAll()
        }
        
    }
    
    struct Version {
        private var version = Int64(Date().timeIntervalSince1970 * 1000)
        private var lock = NSLock()
        
        func getLatestVersion() -> Int64 {
            lock.lock()
            defer {
                lock.unlock()
            }
            return version
        }
        
        mutating func updateVersion() {
            lock.lock()
            defer {
                lock.unlock()
            }
            version = Int64(Date().timeIntervalSince1970 * 1000)
        }
        
    }
    
    private static var fishCache = FishCache()
    private static var version: Version? = nil
    
    private static let incrementalUpdateQueue = DispatchQueue(label: "incremental_update_fish_cache")
    
    static func incrementalUpdate() {
        incrementalUpdateQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                let result: Result<DataServiceResponse<[String]>, AFError>
                if var version = self.version {
                    let lastUpdateTime = version.getLatestVersion()
                    version.updateVersion()
                    result = await DataService.delectFish(updateAfter: lastUpdateTime)
                } else {
                    self.version = Version()
                    result = await DataService.delectFish()
                }
                var uids: [String] = []
                switch result {
                case .success(let resp):
                    if !resp.isOk() {
                        Log.error("Storage.incrementalUpdate - fail: delectFish.resp.code is not ok, resp.code=\(resp.code)")
                        return
                    }
                    guard let data = resp.data else {
                        Log.error("Storage.incrementalUpdate - fail: delectFish.resp.data=nil, resp.code=\(resp.code)")
                        return
                    }
                    uids = data
                case .failure(let err):
                    Log.error("Storage.incrementalUpdate - fail: delectFish request failed, err=\(err)")
                }
                for uid in uids {
                    let result = await DataService.pickFish(uid: uid)
                    switch result {
                    case .success(let resp):
                        if !resp.isOk() {
                            Log.warning("Storage.incrementalUpdate - ignore one fish: pickFish.resp.code is not ok, resp.code=\(resp.code), fish.uid=\(uid)")
                            continue
                        }
                        guard let data = resp.data else {
                            Log.warning("Storage.incrementalUpdate - ignore one fish: pickFish.resp.data=nil, resp.code=\(resp.code), fish.uid=\(uid)")
                            continue
                        }
                        guard let fish = data.toEntity() else {
                            Log.warning("Storage.incrementalUpdate - ignore one fish: parse fishResp to Fish failed, fish.uid=\(uid)")
                            continue
                        }
                        fishCache.setFish(fish)
                    case .failure(let err):
                        Log.warning("Storage.incrementalUpdate - ignore one fish: pickFish request failed, err=\(err), fish.uid=\(uid)")
                    }
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    static func getFishFromCache(_ uid: String) -> Fish? {
        return fishCache.getFish(uid)
    }
    
    static func searchFish(
        fuzzy: String? = nil,
        identitys: [String]? = nil,
        fishTypes: [Fish.FishType]? = nil,
        description: String? = nil,
        tags: [String]? = nil,
        isMarked: Bool? = nil,
        isLocked: Bool? = nil,
        passedHours: Int? = nil
    ) async -> [String:Fish] {
        var updateBefore: Int64? = nil
        if let passedHours = passedHours {
            let now = Date()
            let hoursAgoDate = Calendar.current.date(byAdding: .hour, value: -passedHours, to: now)
            guard let hoursAgoDate = hoursAgoDate else {
                Log.error("Storage.searchFish - fail: pass passedHours to timestamp failed, passedHours=\(passedHours)")
                return [:]
            }
            updateBefore = Int64(hoursAgoDate.timeIntervalSince1970 * 1000)
        }
        var ret: [String:Fish] = [:]
        let result = await DataService.delectFish(
            fuzzy: fuzzy, identitys: identitys, fishTypes: fishTypes, description: description, tags: tags,
            isMarked: isMarked, isLocked: isLocked, updateBefore: updateBefore
        )
        var uids: [String] = []
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.searchFish - fail: delectFish.resp.code is not ok, resp.code=\(resp.code)")
                return ret
            }
            guard let data = resp.data else {
                Log.error("Storage.searchFish - fail: delectFish.resp.data=nil, resp.code=\(resp.code)")
                return ret
            }
            uids = data
        case .failure(let err):
            Log.error("Storage.searchFish - fail: delectFish request failed, err=\(err)")
        }
        for uid in uids {
            if let fish = fishCache.getFish(uid) {
                ret[fish.uid] = fish
                continue
            }
            let result = await DataService.pickFish(uid: uid)
            switch result {
            case .success(let resp):
                if !resp.isOk() {
                    Log.warning("Storage.searchFish - ignore one fish: pickFish.resp.code is not ok, resp.code=\(resp.code), fish.uid=\(uid)")
                    continue
                }
                guard let data = resp.data else {
                    Log.warning("Storage.searchFish - ignore one fish: pickFish.resp.data=nil, resp.code=\(resp.code), fish.uid=\(uid)")
                    continue
                }
                guard let fish = data.toEntity() else {
                    Log.warning("Storage.searchFish - ignore one fish: parse fishResp to Fish failed, fish.uid=\(uid)")
                    continue
                }
                ret[fish.uid] = fish
                fishCache.setFish(fish)
            case .failure(let err):
                Log.warning("Storage.searchFish - ignore one fish: pickFish request failed, err=\(err), fish.uid=\(uid)")
            }
        }
        return ret
    }
    
    static func pickFish(uid: String) async -> Fish? {
        if let fish = fishCache.getFish(uid) {
            return fish
        }
        let result = await DataService.pickFish(uid: uid)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.pickFish - failed: pickFish.resp.code is not ok, resp.code=\(resp.code), fish.uid=\(uid)")
                return nil
            }
            guard let data = resp.data else {
                return nil
            }
            guard let fish = data.toEntity() else {
                Log.error("Storage.pickFish - failed: parse fishResp to Fish failed, fish.uid=\(uid)")
                return nil
            }
            fishCache.setFish(fish)
            return fish
        case .failure(let err):
            Log.error("Storage.pickFish - failed: pickFish request failed, err=\(err), fish.uid=\(uid)")
            return nil
        }
    }
    
    static func pickFishByIdentity(identity: String) async -> Fish? {
        let result = await DataService.pickFishByIdentity(identity: identity)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.pickFish - failed: pickFish.resp.code is not ok, resp.code=\(resp.code), fish.identity=\(identity)")
                return nil
            }
            guard let data = resp.data else {
                return nil
            }
            guard let fish = data.toEntity() else {
                Log.error("Storage.pickFish - failed: parse fishResp to Fish failed, fish.identity=\(identity)")
                return nil
            }
            fishCache.setFish(fish)
            return fish
        case .failure(let err):
            Log.error("Storage.pickFish - failed: pickFish request failed, err=\(err), fish.identity=\(identity)")
            return nil
        }
    }
    
    static func addFish(
        _ fishType: Fish.FishType,
        _ fishData: Data,
        description: String? = nil,
        tags: [String]? = nil,
        isMarked: Bool? = nil,
        isLocked: Bool? = nil,
        extraInfo: [String:String]? = nil
    ) async -> String? {
        let result = await DataService.addFish(
            fishType: fishType, fishData: fishData, description: description, tags: tags,
            isMarked: isMarked, isLocked: isLocked, extraInfo: extraInfo
        )
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.addFish - fail: resp is not ok, resp.code=\(resp.code)")
                return nil
            }
            guard let uid = resp.data else {
                Log.error("Storage.addFish - fail: resp.data=nil, resp.code=\(resp.code)")
                return nil
            }
            fishCache.removeFish(uid)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
            return uid
        case .failure(let err):
            Log.error("Storage.addFish - fail: request data service fail, err=\(err)")
            return nil
        }
    }
    
    static func modifyFish(
        _ uid: String, description: String? = nil, tags: [String]? = nil, extraInfo: [String:String]? = nil
    ) async -> Bool {
        let result = await DataService.modifyFish(
            uid: uid, description: description, tags: tags, extraInfo: extraInfo
        )
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.modifyFish - fail: resp is not ok, resp.code=\(resp.code)")
                return false
            }
            fishCache.removeFish(uid)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
            return true
        case .failure(let err):
            Log.error("Storage.modifyFish - fail: request data service fail, err=\(err)")
            return false
        }
    }
    
    static func removeFish(_ uids: [String]) async {
        let result = await DataService.expireFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.removeFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            fishCache.batchRemoveFish(uids)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.removeFish - fail: request data service fail, err=\(err)")
        }
    }
    
    static func markFish(_ uids: [String]) async {
        let result = await DataService.markFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.markFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            fishCache.batchRemoveFish(uids)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.markFish - fail: request data service fail, err=\(err)")
        }
    }
    
    static func unMarkFish(_ uids: [String]) async {
        let result = await DataService.unMarkFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.unMarkFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            fishCache.batchRemoveFish(uids)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.unMarkFish - fail: request data service fail, err=\(err)")
        }
    }
    
    static func lockFish(_ uids: [String]) async {
        let result = await DataService.lockFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.lockFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            fishCache.batchRemoveFish(uids)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.lockFish - fail: request data service fail, err=\(err)")
        }
    }
    
    static func unLockFish(_ uids: [String]) async {
        let result = await DataService.unLockFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.unLockFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            fishCache.batchRemoveFish(uids)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.unLockFish - fail: request data service fail, err=\(err)")
        }
    }
    
    static func pinFish(_ uids: [String]) async {
        let result = await DataService.pinFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.pinFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            fishCache.batchRemoveFish(uids)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.pinFish - fail: request data service fail, err=\(err)")
        }
    }
    
    static func countFish() async -> CountFishResp? {
        let result = await DataService.countFish()
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.countFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            guard let data = resp.data else {
                Log.error("Storage.countFish - fail: resp.data=nil, resp.code=\(resp.code)")
                return nil
            }
            return data
        case .failure(let err):
            Log.error("Storage.countFish - fail: request data service fail, err=\(err)")
            return nil
        }
    }
    
    static func createTopic(
        subject: String, source: String, title: String, extraInfo: [String:String]? = nil
    ) async -> String? {
        let result = await DataService.createTopic(
            subject: subject, source: source, title: title, extraInfo: extraInfo
        )
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.createTopic - fail: resp is not ok, resp.code=\(resp.code)")
            }
            guard let data = resp.data else {
                Log.error("Storage.createTopic - fail: resp.data=nil, resp.code=\(resp.code)")
                return nil
            }
            return data
        case .failure(let err):
            Log.error("Storage.createTopic - fail: request data service fail, err=\(err)")
            return nil
        }
    }
    
    static func removeTopic(subject: String) async {
        let result = await DataService.removeTopic(subject: subject)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.removeTopic - fail: resp is not ok, resp.code=\(resp.code)")
            }
        case .failure(let err):
            Log.error("Storage.removeTopic - fail: request data service fail, err=\(err)")
        }
    }
    
    static func listTopic() async -> [Topic] {
        let result = await DataService.listTopic()
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.listTopic - fail: resp is not ok, resp.code=\(resp.code)")
            }
            guard let data = resp.data else {
                Log.error("Storage.listTopic - fail: resp.data=nil, resp.code=\(resp.code)")
                return []
            }
            let topics = data.compactMap { topicResp in
                if let topic = topicResp.toEntity() {
                    return topic
                }
                Log.warning("Storage.listTopic - ignore a topic: topicResp.toEntity return nil, topicResp.uid = \(topicResp.uid)")
                return nil
            }
            return topics
        case .failure(let err):
            Log.error("Storage.listTopic - fail: request data service fail, err=\(err)")
            return []
        }
    }
    
    static func sendMessage(
        subject: String, level: Message.Level, title: String,
        body: String, extraInfo: [String:String]? = nil
    ) async {
        let result = await DataService.sendMessage(
            subject: subject, level: level, title: title,
            body: body, hasRead: false, extraInfo: extraInfo
        )
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.sendMessage - fail: resp is not ok, resp.code=\(resp.code)")
            }
        case .failure(let err):
            Log.error("Storage.sendMessage - fail: request data service fail, err=\(err)")
        }
    }
    
    static func readMessage(topicUid: String, messageUid: String) async -> Bool {
        let result = await DataService.readMessage(topicUid: topicUid, messageUid: messageUid)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.readMessage - fail: resp is not ok, resp.code=\(resp.code)")
            }
            return true
        case .failure(let err):
            Log.error("Storage.readMessage - fail: request data service fail, err=\(err)")
            return false
        }
    }
    
    static func searchRecipe(host: String, port: String) async -> [Recipe] {
        var ret: [Recipe] = []
        let result = await RecipeService(host: host, port: port).listRecipe()
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.searchRecipe - fail: resp is not ok, resp.code=\(resp.code), host=\(host), port=\(port)")
            }
            guard let data = resp.data else {
                Log.error("Storage.searchRecipe - fail: resp.data=nil, resp.code=\(resp.code), host=\(host), port=\(port)")
                return ret
            }
            for recipeResp in data {
                guard let recipe = recipeResp.toRecipe() else {
                    Log.warning("Storage.searchRecipe - skip a recipe: parse recipeResp to recipe failed, bundleId=\(recipeResp.bundleId), host=\(host), port=\(port)")
                    continue
                }
                ret.append(recipe)
            }
        case .failure(let err):
            Log.error("Storage.searchRecipe - fail: request recipe server failed, host=\(host), port=\(port), err=\(err)")
        }
        return ret
    }
  
}
