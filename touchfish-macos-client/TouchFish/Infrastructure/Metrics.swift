import SwiftUI

var Metrics = TFMetrics.it

struct TFMetrics: Codable {
    
    var recipeUsageCount: [String:Int] = [:]
    
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
