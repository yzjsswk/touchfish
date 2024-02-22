import SQLite
import AppKit

let DB = DataBaseOperator.self

struct TFish {
    
    static let fish = Table("fish")
    static let id = Expression<Int>("id")
    static let identity = Expression<String>("identity")
    static let type = Expression<String>("type")
    static let source = Expression<String>("source")
    static let value = Expression<String>("value")
    static let description = Expression<String>("description")
    static let tag = Expression<String>("tag")
    static let isMarked = Expression<Bool>("is_marked")
    static let extraInfo = Expression<String>("extra_info")
    static let createTime = Expression<String>("create_time")
    static let updateTime = Expression<String>("update_time")
    
    static func parse(from queryResult: Row) -> Fish? {
        guard let id = try? queryResult.get(TFish.id) else {
            Log.warning("query result ignored: got id=nil when parse fish")
            Log.verbose(queryResult)
            return nil
        }
        guard let identity = try? queryResult.get(TFish.identity) else {
            Log.warning("query result ignored: got identity=nil when parse fish(id=\(id))")
            return nil
        }
        guard let type = try? queryResult.get(TFish.type) else {
            Log.warning("query result ignored: got type=nil when parse fish(id=\(id))")
            return nil
        }
        guard let source = try? queryResult.get(TFish.source) else {
            Log.warning("query result ignored: got source=nil when parse fish(id=\(id))")
            return nil
        }
        let value = (try? queryResult.get(TFish.value)) ?? ""
        let description = (try? queryResult.get(TFish.description)) ?? ""
        let tag = (try? queryResult.get(TFish.tag)) ?? ""
        let isMarked = (try? queryResult.get(TFish.isMarked)) ?? false
        let extraInfoJs = (try? queryResult.get(TFish.extraInfo)) ?? ""
        let createTime = (try? queryResult.get(TFish.createTime)) ?? "--"
        let updateTime = (try? queryResult.get(TFish.updateTime)) ?? "--"
        
        guard let type = FishType(rawValue: type) else {
            Log.warning("query result ignored: got unexpected type=\(type) when parse fish(id=\(id))")
            return nil
        }
        guard let source = Source(rawValue: source) else {
            Log.warning("query result ignored: got unexpected source=\(source) when parse fish(id=\(id))")
            return nil
        }
        let tags = tag.split(separator: ",").compactMap { String($0) }
        
        guard let extraInfo = ExtraInfo.load(from: extraInfoJs) else {
            Log.warning("query result ignored: got unexpected extraInfo=\(extraInfoJs) when parse fish(id=\(id))")
            return nil
        }
        
        return Fish(
            id: id,
            identity: identity,
            type: type,
            source: source,
            value: value,
            description: description,
            tag: tags,
            isMarked: isMarked,
            extraInfo: extraInfo,
            createTime: createTime,
            updateTime: updateTime
        )
    }
    
}

struct DataBaseOperator {
    
    /**
     drop table if exists fish;
     create table fish (
         id integer PRIMARY KEY AUTOINCREMENT,
         identity varchar(64) NOT NULL,
         type varchar(16) NOT NULL,
         source varchar(16) NOT NULL,
         value text NOT NULL DEFAULT '',
         description text NOT NULL DEFAULT '',
         tag varchar(128) NOT NULL DEFAULT '',
         is_marked tinyint NOT NUll DEFAULT 0,
         extra_info text NOT NULL DEFAULT '{}',
         create_time DATETIME NOT NULL DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')),
         update_time DATETIME NOT NULL DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')),
         CONSTRAINT idx_unique UNIQUE (identity, type, source)
     );

     drop TRIGGER if exists update_fish;
     CREATE TRIGGER update_fish
     AFTER UPDATE ON fish
     FOR EACH ROW
     BEGIN
         UPDATE fish SET update_time = datetime(CURRENT_TIMESTAMP, 'localtime') WHERE id = NEW.id;
     END;
     */
    
    static let db = try! Connection(TouchFishApp.dbPath.path)
    
    static func searchFish(valueOrDesc: String? = nil, value: String? = nil, description: String? = nil, identity: String? = nil, type: [FishType]? = nil, tag: [String]? = nil, source: [Source]? = nil, isMarked: Bool? = nil, limitNum: Int? = nil) -> [Fish] {
        var selectSql = TFish.fish
        if let valueOrDesc = valueOrDesc {
            selectSql = selectSql.filter(TFish.value.like("%\(valueOrDesc)%") || TFish.description.like("%\(valueOrDesc)%"))
        }
        if let value = value {
            selectSql = selectSql.filter(TFish.value.like("%\(value)%"))
        }
        if let description = description {
            selectSql = selectSql.filter(TFish.description.like("%\(description)%"))
        }
        if let identity = identity {
            selectSql = selectSql.filter(TFish.identity == identity)
        }
        if let type = type?.map({ $0.rawValue }) {
            selectSql = selectSql.filter(type.contains(TFish.type))
        }
        if let source = source?.map({ $0.rawValue }) {
            selectSql = selectSql.filter(source.contains(TFish.source))
        }
        if let tag = tag {
            let tagList = Array(Set(tag)).sorted()
            var keyword = ""
            for tg in tagList {
                keyword += "%\(tg)"
            }
            keyword += "%"
            selectSql = selectSql.filter(TFish.tag.like(keyword))
        }
        if let isMarked = isMarked {
            selectSql = selectSql.filter(TFish.isMarked == isMarked)
        }
        selectSql = selectSql.order(TFish.updateTime.desc)
        if let limitNum = limitNum {
            selectSql = selectSql.limit(limitNum)
        }
        var res: [Fish] = []
        do {
            res = try db.prepare(selectSql).compactMap{ TFish.parse(from: $0) }
        } catch {
            Log.error("search fish error: \(error)")
        }
//        if let tag = tag {
//            // todo: correct?
//            res = res.filter { tag.allSatisfy($0.tag.contains(_:)) }
//        }
        return res
    }
    
    static func getFish(of id: Int) -> Fish? {
        guard let row = try? db.pluck(TFish.fish.filter(TFish.id == id)) else {
            return nil
        }
        return TFish.parse(from: row)
    }
    
    static func getFishHasTag() -> [Fish] {
        var res: [Fish] = []
        do {
            res = try db.prepare(TFish.fish.filter(TFish.tag != "")).compactMap{ TFish.parse(from: $0) }
        } catch {
            Log.error("get fish has tag error: \(error)")
        }
        return res
    }
        
    // return: if success
    static func markFish(of id: Int, isMarked: Bool? = nil) -> Bool {
        if let isMarked = isMarked {
            return DataBaseOperator.updateFish(of: id, isMarked: isMarked)
        }
        if let targetFish = DataBaseOperator.getFish(of: id) {
            return DataBaseOperator.updateFish(of: id, isMarked: !targetFish.isMarked)
        }
        return true;
    }
    
    // return: the row id of new line, or nil if failed
    static func addFish(value: String, description: String = "", identity: String, type: FishType, source: Source, tag: [String] = [], extraInfo: ExtraInfo = ExtraInfo()) -> Int? {
        defer {
            Cache.FishCache.refresh()
        }
        var conditions: [Setter] = []
        conditions.append(TFish.value <- value)
        conditions.append(TFish.description <- description)
        conditions.append(TFish.identity <- identity)
        conditions.append(TFish.type <- type.rawValue)
        conditions.append(TFish.source <- source.rawValue)
        let tagList = Array(Set(tag)).sorted()
        conditions.append(TFish.tag <- tagList.joined(separator: ","))
        guard let extraInfoJs = extraInfo.toJsonString() else {
            Log.error("add fish failed: parse para extraInfo to json string error")
            Log.verbose(extraInfo)
            return nil
        }
        conditions.append(TFish.extraInfo <- extraInfoJs)
        let insertSql = TFish.fish.insert(conditions)
        do {
            return Int(try db.run(insertSql))
        } catch {
            print("add fish error: \(error)")
        }
        return nil;
    }
    
    // return: if successed
    static func updateFish(of id: Int, identity: String? = nil, type: FishType? = nil, value: String? = nil, description: String? = nil, tag: [String]? = nil, source: Source? = nil, extraInfo: ExtraInfo? = nil, isMarked: Bool? = nil) -> Bool {
        defer {
            Cache.FishCache.refresh()
        }
        var conditions: [Setter] = []
        if let identity = identity {
            conditions.append(TFish.identity <- identity)
        }
        if let type = type {
            conditions.append(TFish.type <- type.rawValue)
        }
        if let value = value {
            conditions.append(TFish.value <- value)
        }
        if let description = description {
            conditions.append(TFish.description <- description)
        }
        if let tag = tag {
            let tagList = Array(Set(tag)).sorted()
            conditions.append(TFish.tag <- tagList.joined(separator: ","))
        }
        if let source = source {
            conditions.append(TFish.source <- source.rawValue)
        }
        if let extraInfo = extraInfo {
            guard let extraInfoJs = extraInfo.toJsonString() else {
                Log.error("update fish failed: parse para extraInfo to json string error")
                Log.verbose(extraInfo)
                return false
            }
            conditions.append(TFish.extraInfo <- extraInfoJs)
        }
        if let isMarked = isMarked {
            conditions.append(TFish.isMarked <- isMarked)
        }
        let updateSql = TFish.fish.filter(TFish.id == id).update(conditions)
        do {
            return try db.run(updateSql) > 0
        } catch {
            Log.error("update fish(id=\(id)) error: \(error)")
        }
        return false
    }
    
    // return: if successed
    static func deleteFish(of id: Int) -> Bool {
        defer {
            Cache.FishCache.refresh()
        }
        let deleteSql = TFish.fish.filter(TFish.id == id).delete()
        do {
            return try db.run(deleteSql) > 0
        } catch {
            Log.error("delete fish(id=\(id)) error: \(error)")
        }
        return false;
    }
    
}
