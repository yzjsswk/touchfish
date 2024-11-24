import Foundation

struct TFTask {
    
    static func start() {
        autoRefreshTopic()
        autoRefreshRecipe()
    }
    
    static func autoRefreshTopic() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
        }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
            }
            autoRefreshTopic()
        }
    }
    
    static func autoRefreshRecipe() {
        RecipeManager.refresh()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
            RecipeManager.refresh()
            autoRefreshTopic()
        }
    }
    
}
