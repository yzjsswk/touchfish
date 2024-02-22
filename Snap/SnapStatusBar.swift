//
//  StatusBar.swift
//  Snap
//
//  Created by ByteDance on 2023/11/18.
//

import SwiftUI

class SnapStatusBar {
    
    private var statusItem: NSStatusItem!
    
    private var menu: NSMenu!
    
    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

        button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        self.menu = NSMenu()
        let menuItems = [
            NSMenuItem(title: "Show Search Bar",
                       action: #selector(self.showSearchBarAction),
                       keyEquivalent: "S"),
            NSMenuItem(title: "Show Preferences",
                       action: #selector(self.showPreferencesAction),
                       keyEquivalent: "P"),
            NSMenuItem.separator(),
            NSMenuItem(title: "Quit",
                       action: #selector(self.quitAction),
                       keyEquivalent: "Q")]
        for menuItem in menuItems {
            // The target should be self, otherwise, actions won't be executed.
            menuItem.target = self
            
            menu.addItem(menuItem)
        }
        statusItem.menu = menu
    }
    
    @objc func showSearchBarAction() {
        Snap.default.activate()
    }
    
    @objc func showPreferencesAction() {
        Snap.default.showPreferencesWindow()
    }
    
    @objc func quitAction() {
        Snap.default.quit()
    }
    
}
