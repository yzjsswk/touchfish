import SwiftUI

struct Storage {
    
    private static var fishCache: [String:Fish] = [:]
    
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
        var ret: [String:Fish] = [:]
        let result = await DataService.delectFish(
            fuzzy: fuzzy,
            identitys: identitys,
            fishTypes: fishTypes,
            description: description,
            tags: tags,
            isMarked: isMarked,
            isLocked: isLocked,
            passedHours: passedHours
        )
        var identitys: [String] = []
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.searchFish - fail: delectFish.resp.status is not ok, resp.status=\(resp.status)")
                return ret
            }
            guard let data = resp.data else {
                Log.error("Storage.searchFish - fail: delectFish.resp.data=nil, resp.status=\(resp.status)")
                return ret
            }
            identitys = data
        case .failure(let err):
            Log.error("Storage.searchFish - fail: delectFish request failed, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
        for identity in identitys {
            if let fish = fishCache[identity] {
                ret[fish.identity] = fish
                continue
            }
            let result = await DataService.pickFish(identity: identity)
            switch result {
            case .success(let resp):
                if !resp.isOk() {
                    Log.warning("Storage.searchFish - ignore one fish: pickFish.resp.status is not ok, resp.status=\(resp.status), fish.identity=\(identity)")
                    continue
                }
                guard let data = resp.data else {
                    Log.warning("Storage.searchFish - ignore one fish: pickFish.resp.data=nil, resp.status=\(resp.status), fish.identity=\(identity)")
                    
                    continue
                }
                guard let fish = data.toFish() else {
                    Log.warning("Storage.searchFish - ignore one fish: parse fishResp to Fish failed, fish.identity=\(identity)")
                    continue
                }
                ret[fish.identity] = fish
                fishCache[fish.identity] = fish
            case .failure(let err):
                Log.warning("Storage.searchFish - ignore one fish: pickFish request failed, err=\(err), fish.identity=\(identity)")
                Functions.sendDataServiceErrorMessage()
            }
        }
        return ret
    }
    
    static func pickFish(identity: String) async -> Fish? {
        if let fish = fishCache[identity] {
            return fish
        }
        let result = await DataService.pickFish(identity: identity)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.pickFish - failed: pickFish.resp.status is not ok, resp.status=\(resp.status), fish.identity=\(identity)")
                return nil
            }
            guard let data = resp.data else {
                return nil
            }
            guard let fish = data.toFish() else {
                Log.error("Storage.pickFish - failed: parse fishResp to Fish failed, fish.identity=\(identity)")
                return nil
            }
            fishCache[fish.identity] = fish
            return fish
        case .failure(let err):
            Log.error("Storage.pickFish - failed: pickFish request failed, err=\(err), fish.identity=\(identity)")
            Functions.sendDataServiceErrorMessage()
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
        extraInfo: Fish.ExtraInfo? = nil
    ) async -> Fish? {
        let extraInfo = extraInfo ?? Fish.ExtraInfo()
        guard let extraInfo = extraInfo.to_json_string() else {
            Log.error("Storage.addFish - failed: parse extraInfo to string failed, extraInfo=\(extraInfo)")
            return nil
        }
        let result = await DataService.addFish(
            fishType: fishType, fishData: fishData, description: description, tags: tags,
            isMarked: isMarked, isLocked: isLocked, extraInfo: extraInfo
        )
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.addFish - fail: resp is not ok, resp.status=\(resp.status)")
                return nil
            }
            guard let data = resp.data else {
                Log.error("Storage.addFish - fail: resp.data=nil, resp.status=\(resp.status)")
                return nil
            }
            guard let fish = data.toFish() else {
                Log.error("Storage.addFish - return nil: parse fishResp to Fish failed, resp.status=\(resp.status)")
                return nil
            }
            fishCache[fish.identity] = fish
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
            return fish
        case .failure(let err):
            Log.error("Storage.addFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
            return nil
        }
    }
    
    static func modifyFish(
        _ identity: String, description: String? = nil, tags: [String]? = nil, extraInfo: Fish.ExtraInfo? = nil
    ) async -> Bool {
        let extraInfo = extraInfo ?? Fish.ExtraInfo()
        guard let extraInfo = extraInfo.to_json_string() else {
            Log.error("Storage.modifyFish - failed: parse extraInfo to string failed, extraInfo=\(extraInfo)")
            return false
        }
        let result = await DataService.modifyFish(
            identity: identity, description: description, tags: tags, extraInfo: extraInfo
        )
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.modifyFish - fail: resp is not ok, resp.status=\(resp.status)")
                return false
            }
            fishCache.removeValue(forKey: identity)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
            return true
        case .failure(let err):
            Log.error("Storage.modifyFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
            return false
        }
    }
    
    static func removeFish(_ identitys: [String]) async {
        let result = await DataService.expireFish(identitys: identitys)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.removeFish - fail: resp is not ok, resp.status=\(resp.status)")
            }
            for identity in identitys {
                fishCache.removeValue(forKey: identity)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.removeFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func markFish(_ identitys: [String]) async {
        let result = await DataService.markFish(identitys: identitys)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.markFish - fail: resp is not ok, resp.status=\(resp.status)")
            }
            for identity in identitys {
                fishCache.removeValue(forKey: identity)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.markFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func unMarkFish(_ identitys: [String]) async {
        let result = await DataService.unMarkFish(identitys: identitys)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.unMarkFish - fail: resp is not ok, resp.status=\(resp.status)")
            }
            for identity in identitys {
                fishCache.removeValue(forKey: identity)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.unMarkFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func lockFish(_ identitys: [String]) async {
        let result = await DataService.lockFish(identitys: identitys)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.lockFish - fail: resp is not ok, resp.status=\(resp.status)")
            }
            for identity in identitys {
                fishCache.removeValue(forKey: identity)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.lockFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func unLockFish(_ identitys: [String]) async {
        let result = await DataService.unLockFish(identitys: identitys)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.unLockFish - fail: resp is not ok, resp.status=\(resp.status)")
            }
            for identity in identitys {
                fishCache.removeValue(forKey: identity)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.unLockFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func pinFish(_ identitys: [String]) async {
        let result = await DataService.pinFish(identitys: identitys)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.pinFish - fail: resp is not ok, resp.status=\(resp.status)")
            }
            for identity in identitys {
                fishCache.removeValue(forKey: identity)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.pinFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func countFish() async -> CountFishResp? {
        let result = await DataService.countFish()
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.countFish - fail: resp is not ok, resp.status=\(resp.status)")
            }
            guard let data = resp.data else {
                Log.error("Storage.countFish - fail: resp.data=nil, resp.status=\(resp.status)")
                return nil
            }
            return data
        case .failure(let err):
            Log.error("Storage.countFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
            return nil
        }
    }
  
}

