import SwiftUI

class PasteBoardWindow: NSPanel {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 400),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isReleasedWhenClosed = false
        self.center()
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.contentView = NSHostingView(rootView: PasteBoardView())
        self.isMovableByWindowBackground = true
    }
    
    func show() {
        self.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        self.close()
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
}
