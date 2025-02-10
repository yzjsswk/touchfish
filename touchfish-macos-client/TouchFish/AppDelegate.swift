import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
	func applicationDidFinishLaunching(_ aNotification: Notification) {
        TouchFishApp.start()
	}
    
    func applicationWillTerminate(_ aNotification: Notification) {
        Log.info("application exited")
    }

}
