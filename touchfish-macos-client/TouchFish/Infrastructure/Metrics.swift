import SwiftUI

var Metrics = TFMetrics.it

struct TFMetrics: Codable {
    
    struct RecipeUsageCount: Codable {
        var value: [String:Int]
        var lock: NSLock
        
        init() {
            self.value = [:]
            self.lock = NSLock()
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            value = try container.decode([String: Int].self, forKey: .value)
            lock = NSLock()
        }
        
        private enum CodingKeys: String, CodingKey {
            case value
        }
        
        func get(bundleId: String) -> Int {
            lock.lock()
            defer {
                lock.unlock()
            }
            return value[bundleId, default: 0]
        }
        
        func getAll() -> [String:Int] {
            lock.lock()
            defer {
                lock.unlock()
            }
            return value
        }
        
        mutating func count(bundleId: String) {
            lock.lock()
            defer {
                lock.unlock()
            }
            value[bundleId, default: 0] += 1
        }
        
    }
    
    var recipeUsageCount = RecipeUsageCount()
    
    static var it = read()
    
    static func read() -> TFMetrics {
        if !FileManager.default.fileExists(atPath: TouchFishApp.metricsPath.path) {
            let defaultMetrics = TFMetrics()
            defaultMetrics.save()
            return defaultMetrics
        }
        let metricsData = try! Data(contentsOf: TouchFishApp.metricsPath)
        return try! JSONDecoder().decode(TFMetrics.self, from: metricsData)
    }
    
    func save() {
        do {
            try JSONEncoder().encode(self).write(to: TouchFishApp.metricsPath)
        } catch {
            Log.error("save metrics - failed, err=\(error)")
        }
    }

}
