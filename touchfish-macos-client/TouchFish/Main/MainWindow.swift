import SwiftUI

class MainWindow: NSWindow, NSWindowDelegate {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1300, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        self.delegate = self
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.contentView = NSHostingView(rootView: MainView())
        self.repositionWindowButtons()
        self.center()
    }
    
    private func repositionWindowButtons() {
        guard let closeButton = self.standardWindowButton(.closeButton),
              let minimizeButton = self.standardWindowButton(.miniaturizeButton),
              let zoomButton = self.standardWindowButton(.zoomButton) else {
            return
        }
        let buttonSize = closeButton.frame.size
        let buttonSpacing: CGFloat = 10
        let leftPadding: CGFloat = (Constant.mainWindowWindowButtonAreaWidth-buttonSize.width*3-buttonSpacing*2)/2
        let topPadding: CGFloat = (Constant.mainWindowTabBarHeight-buttonSize.height)/2
        closeButton.frame.origin = CGPoint(x: leftPadding, y: 16-topPadding)
        minimizeButton.frame.origin = CGPoint(x: leftPadding+buttonSize.width+buttonSpacing, y: 16-topPadding)
        zoomButton.frame.origin = CGPoint(x: leftPadding+buttonSize.width*2+buttonSpacing*2, y: 16-topPadding)
    }
    
    func show() {
        self.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        self.orderOut(nil)
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        TouchFishApp.quit()
        return false
    }
    
    func windowDidResize(_ notification: Notification) {
        repositionWindowButtons()
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        repositionWindowButtons()
        NotificationCenter.default.post(name: .MainWindowEnterFullScreen, object: nil)
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        repositionWindowButtons()
        NotificationCenter.default.post(name: .MainWindowExitFullScreen, object: nil)
    }
    
    override func mouseDown(with event: NSEvent) {
        if TouchFishApp.quickExecutionWindow.isVisible {
            TouchFishApp.quickExecutionWindow.hide()
        }
        super.mouseDown(with: event)
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        if TouchFishApp.quickExecutionWindow.isVisible {
            TouchFishApp.quickExecutionWindow.hide()
        }
    }
    
}
