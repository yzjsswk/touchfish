import Foundation
import SwiftUI

class PromptManager {
    
    static func exec(prompt: String) -> [Process] {
        var ret: [Process] = []
        let fishRepositoryProcess = Process(
            id: 1,
            name: "Fish Repository",
            desc: "master your information",
            icon: Image(systemName: "fish")
        ) {
            NotificationCenter.default.post(name: .ShouldShowFishView, object: nil)
//            Log.info("post should show fish view end")
        }
        ret.append(fishRepositoryProcess)
        let webBrowser = Process(
            id: 2,
            name: "Web BookMark",
            icon: Image(systemName: "globe"),
            command: "bm"
        )
//        ret.append(webBrowser)
        return ret
    }
    
}
