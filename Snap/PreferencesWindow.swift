// PreferencesWindow.swift
//
// Created by TeChris on 15.04.21.

import AppKit
import SwiftUI

class PreferencesWindow: NSWindow {
	private let notificationCenter = NotificationCenter.default
	
	static let preferencesWindowWillCloseNotification = Notification.Name("PreferencesWindowWillClose")
	
    init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 575,
                height: 450
            ),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.title = "Preferences"
        self.isReleasedWhenClosed = false
        self.center()
        self.contentView = NSHostingView(rootView: PreferencesView())
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        super.close()
    }
    
    override func close() {
		// Send a notification to notify the view that the window has close.
		notificationCenter.post(name: PreferencesWindow.preferencesWindowWillCloseNotification, object: nil)
	}
	
	override func performClose(_ sender: Any?) {
		// Send a notification to notify the view that the window will close.
		notificationCenter.post(name: PreferencesWindow.preferencesWindowWillCloseNotification, object: nil)
	}
	

}
