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
            fuzzy: fuzzy, identitys: identitys, fishTypes: fishTypes, description: description, tags: tags,
            isMarked: isMarked, isLocked: isLocked, passedHours: passedHours
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
            Functions.sendDataServiceErrorMessage()
        }
        for uid in uids {
            if let fish = fishCache[uid] {
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
                guard let fish = data.toFish() else {
                    Log.warning("Storage.searchFish - ignore one fish: parse fishResp to Fish failed, fish.uid=\(uid)")
                    continue
                }
                ret[fish.uid] = fish
                fishCache[fish.uid] = fish
            case .failure(let err):
                Log.warning("Storage.searchFish - ignore one fish: pickFish request failed, err=\(err), fish.uid=\(uid)")
                Functions.sendDataServiceErrorMessage()
            }
        }
        return ret
    }
    
    static func pickFish(uid: String) async -> Fish? {
        if let fish = fishCache[uid] {
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
            guard let fish = data.toFish() else {
                Log.error("Storage.pickFish - failed: parse fishResp to Fish failed, fish.uid=\(uid)")
                return nil
            }
            fishCache[fish.uid] = fish
            return fish
        case .failure(let err):
            Log.error("Storage.pickFish - failed: pickFish request failed, err=\(err), fish.uid=\(uid)")
            Functions.sendDataServiceErrorMessage()
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
            guard let fish = data.toFish() else {
                Log.error("Storage.pickFish - failed: parse fishResp to Fish failed, fish.identity=\(identity)")
                return nil
            }
            fishCache[fish.uid] = fish
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
    ) async -> String? {
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
                Log.error("Storage.addFish - fail: resp is not ok, resp.code=\(resp.code)")
                return nil
            }
            guard let uid = resp.data else {
                Log.error("Storage.addFish - fail: resp.data=nil, resp.code=\(resp.code)")
                return nil
            }
            fishCache.removeValue(forKey: uid)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
            return uid
        case .failure(let err):
            Log.error("Storage.addFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
            return nil
        }
    }
    
    static func modifyFish(
        _ uid: String, description: String? = nil, tags: [String]? = nil, extraInfo: Fish.ExtraInfo? = nil
    ) async -> Bool {
        var extraInfoStr: String? = nil
        if let extraInfo = extraInfo {
            guard let extraInfo = extraInfo.to_json_string() else {
                Log.error("Storage.modifyFish - failed: parse extraInfo to string failed, extraInfo=\(extraInfo)")
                return false
            }
            extraInfoStr = extraInfo
        }
        let result = await DataService.modifyFish(
            uid: uid, description: description, tags: tags, extraInfo: extraInfoStr
        )
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.modifyFish - fail: resp is not ok, resp.code=\(resp.code)")
                return false
            }
            fishCache.removeValue(forKey: uid)
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
    
    static func removeFish(_ uids: [String]) async {
        let result = await DataService.expireFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.removeFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            for uid in uids {
                fishCache.removeValue(forKey: uid)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.removeFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func markFish(_ uids: [String]) async {
        let result = await DataService.markFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.markFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            for uid in uids {
                fishCache.removeValue(forKey: uid)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.markFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func unMarkFish(_ uids: [String]) async {
        let result = await DataService.unMarkFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.unMarkFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            for uid in uids {
                fishCache.removeValue(forKey: uid)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.unMarkFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func lockFish(_ uids: [String]) async {
        let result = await DataService.lockFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.lockFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            for uid in uids {
                fishCache.removeValue(forKey: uid)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.lockFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func unLockFish(_ uids: [String]) async {
        let result = await DataService.unLockFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.unLockFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            for uid in uids {
                fishCache.removeValue(forKey: uid)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        case .failure(let err):
            Log.error("Storage.unLockFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
        }
    }
    
    static func pinFish(_ uids: [String]) async {
        let result = await DataService.pinFish(uids: uids)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.pinFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            for uid in uids {
                fishCache.removeValue(forKey: uid)
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
                Log.error("Storage.countFish - fail: resp is not ok, resp.code=\(resp.code)")
            }
            guard let data = resp.data else {
                Log.error("Storage.countFish - fail: resp.data=nil, resp.code=\(resp.code)")
                return nil
            }
            return data
        case .failure(let err):
            Log.error("Storage.countFish - fail: request data service fail, err=\(err)")
            Functions.sendDataServiceErrorMessage()
            return nil
        }
    }
    
    static func searchRecipe() async -> [Recipe] {
        var ret: [Recipe] = []
        for server in Config.recipeServiceConfigs.values {
            let urlPrefix = "http://\(server.host):\(server.port)"
            RecipeService.urlPrefix = urlPrefix
            let result = await RecipeService.listRecipe()
            switch result {
            case .success(let resp):
                if !resp.isOk() {
                    Log.error("Storage.searchRecipe - fail: resp is not ok, resp.code=\(resp.code), urlPrefix=\(urlPrefix)")
                }
                guard let data = resp.data else {
                    Log.error("Storage.searchRecipe - fail: resp.data=nil, resp.code=\(resp.code), urlPrefix=\(urlPrefix)")
                    continue
                }
                for recipeResp in data {
                    guard let recipe = recipeResp.toRecipe() else {
                        Log.warning("Storage.searchRecipe - skip a recipe: parse recipeResp to recipe failed, bundleId=\(recipeResp.bundleId), urlPrefix=\(urlPrefix)")
                        continue
                    }
                    ret.append(recipe)
                }
            case .failure(let err):
                Log.error("Storage.searchRecipe - fail: request recipe server failed, urlPrefix=\(urlPrefix), err=\(err)")
                continue
            }
        }
        return ret
    }
    
    static func executeRecipe(
        bundleId: String, command: String, arguments: [String]
    ) async -> String? {
        guard let server = Config.recipeServiceConfigs.values.first else {
            Log.error("Storage.executeRecipe - fail: no recipe server, bundleId=\(bundleId), command=\(command)")
            return nil
        }
        let urlPrefix = "http://\(server.host):\(server.port)"
        let result = await RecipeService.executeRecipe(bundleId: bundleId, command: command, arguments: arguments)
        switch result {
        case .success(let resp):
            if !resp.isOk() {
                Log.error("Storage.executeRecipe - fail: resp is not ok, resp.code=\(resp.code), urlPrefix=\(urlPrefix), bundleId=\(bundleId), command=\(command)")
            }
            guard let data = resp.data else {
                Log.error("Storage.executeRecipe - fail: resp.data=nil, resp.code=\(resp.code), urlPrefix=\(urlPrefix), bundleId=\(bundleId), command=\(command)")
                return nil
            }
            return data
        case .failure(let err):
            Log.error("Storage.executeRecipe - fail: request recipe server failed, urlPrefix=\(urlPrefix), err=\(err), bundleId=\(bundleId), command=\(command)")
            return nil
        }
    }
  
}

