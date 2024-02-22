import SwiftUI

class StatusBar {
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(named: "icon_32")
        
        self.menu = NSMenu()
        let menuItems = [
            NSMenuItem(title: "Open",
                       action: #selector(self.openAction),
                       keyEquivalent: "O"),
            NSMenuItem(title: "Preferences",
                       action: #selector(self.showPreferencesAction),
                       keyEquivalent: "P"),
            NSMenuItem.separator(),
            NSMenuItem(title: "Quit",
                       action: #selector(self.quitAction),
                       keyEquivalent: "Q")]
        for menuItem in menuItems {
            menuItem.target = self // The target should be self, otherwise, actions won't be executed.
            menu.addItem(menuItem)
        }
        statusItem.menu = menu
    }
    
    @objc func openAction() {
        TouchFishApp.activate()
    }
    
    @objc func showPreferencesAction() {
        // todo
    }
    
    @objc func quitAction() {
        TouchFishApp.quit()
    }
    
}
