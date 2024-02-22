// Snap.swift
//
// Created by TeChris on 20.03.21.

import SwiftUI
import Carbon.HIToolbox.Events

class Snap {
    
//	static let `default` = (NSApp.delegate as! AppDelegate).snap
    
    static let `default` = Snap()
	
	/// The URL to the application support directory for Snap.
	static let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Snap/")
	
	var clipboardManager: ClipboardManager!
    var snippetExpansionManager: SnippetExpansionManager!
    var statusBar: SnapStatusBar!
	var searchWindow: SearchWindow!
    var preferencesWindow: PreferencesWindow?
    var gettingStartedWindow: GettingStartedWindow!
	
	private var isStarted = false
    
    let notificationCenter = NotificationCenter.default
	
	/// The application's icon.
	var icon: Image {
		let iconImage = NSApp.applicationIconImage!
		iconImage.size = NSSize(width: 250, height: 250)
		return Image(nsImage: iconImage)
	}
	
	private var configuration: Configuration!
	
	func start() {
		if !UserDefaults.standard.bool(forKey: "StartedBefore") {
            gettingStartedWindow = GettingStartedWindow()
            return
		}
		
		// Check if the Application Support directory for Snap exists; If it doesn't, then create it.
//		print(Snap.applicationSupportURL.path)
        let fileManager = FileManager.default
		if !fileManager.fileExists(atPath: Snap.applicationSupportURL.path) {
			try? fileManager.createDirectory(at: Snap.applicationSupportURL, withIntermediateDirectories: false, attributes: nil)
		}
		
		configuration = Configuration.decoded
		clipboardManager = ClipboardManager()
		snippetExpansionManager = SnippetExpansionManager()
//		Permissions.requestPermissions()
//		setUpStatusItem()
        statusBar = SnapStatusBar()
        searchWindow = SearchWindow()
        self.activate()
		
        SnapMonitorManager.startSearchWindowShowSwitchMonitor()
        SnapMonitorManager.startSearchWindowShouldCloseMonitor()
        
		if configuration.clipboardHistoryEnabled {
			clipboardManager.start()
		}
		if configuration.snippetExpansionEnabled {
			snippetExpansionManager.start()
		}
		isStarted = true
	}
	
    func activate() {
        print("active")
//        NSApp.activate(ignoringOtherApps: false)
        searchWindow.show()
//        NSApp.hide(nil)
    }
    
    func deactivate() {
        print("deactive")
        if !isStarted {
            return
        }
        notificationCenter.post(name: .ApplicationShouldExit, object: nil)
        searchWindow.hide()
        NSApp.hide(nil)
        SnapMonitorManager.stopLocalKeyboardPressMonitor()
    }
    
    func quit() {
        NSApp.terminate(nil)
    }

	func showPreferencesWindow() {
		searchWindow.hide()
		// If the preferences window is already on the screen, then give it focus and return.
		if preferencesWindow?.isVisible == true {
			preferencesWindow?.makeKeyAndOrderFront(nil)
			return
		}
		// Configure the preferences window.
		preferencesWindow = PreferencesWindow()
		// Stop listening for events, they aren't relevant for the preferences window.
        SnapMonitorManager.stopLocalKeyboardPressMonitor()
	}

}
