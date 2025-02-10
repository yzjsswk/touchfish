import SwiftUI

class QuickExecutionWindow: NSPanel {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isReleasedWhenClosed = false
        self.moveToUpCenter()
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.contentView = NSHostingView(rootView: QuickExecutionView())
        self.isMovableByWindowBackground = true
    }
    
    private func moveToUpCenter() {
        guard let screen = NSScreen.main else {
            return
        }
        let screenSize = screen.visibleFrame.size
        let screenOrigin = screen.visibleFrame.origin
        let windowSize = self.frame.size
        let x = screenOrigin.x + (screenSize.width-windowSize.width)*0.5
        let y = screenOrigin.y + (screenSize.height-windowSize.height)*0.8
        self.setFrameOrigin(NSPoint(x: x, y: y))
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
