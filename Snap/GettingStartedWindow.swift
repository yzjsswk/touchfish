//
//  GettingStartedWindow.swift
//  Snap
//
//  Created by ByteDance on 2023/11/18.
//

import AppKit
import SwiftUI

class GettingStartedWindow: NSWindow {
    
    init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 500,
                height: 535
            ),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.title = "Getting Started"
        self.isReleasedWhenClosed = false
        self.center()
        self.contentView = NSHostingView(rootView: GettingStartedView())
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
    }
    
}
