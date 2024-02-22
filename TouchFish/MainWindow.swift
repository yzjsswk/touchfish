import SwiftUI

class MainWindow: NSPanel {
    
    init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: CONFIG.mainWidth,
                height: CONFIG.mainHeight
            ),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isReleasedWhenClosed = false
        self.center()
        self.moveToUpCenter()
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.contentView = NSHostingView(rootView: MainView())
        self.isMovableByWindowBackground = true
    }
    
    private func moveToUpCenter() {
        let screenSize = NSScreen.main?.visibleFrame.size
        let windowSize = self.frame.size
        if let screenSize = screenSize {
            let x = (screenSize.width - windowSize.width) / 2
            let y = screenSize.height / 2 + screenSize.height / 3
            let origin = NSPoint(x: x, y: y)
            self.setFrameOrigin(origin)
        }
    }
    
    func show() {
        // Add the titled style mask, it will be removed later.
        self.styleMask.insert(.titled)
        self.makeKeyAndOrderFront(nil)
        // The titled style mask needs to be removed after the window ordered the front; Otherwise, it will stay in the background.
        self.styleMask.remove(.titled)
    }
    
    func hide() {
        self.close()
    }
    
    
}
