//import SwiftUI
//
//class MainWindow: NSPanel {
//    
//    init() {
//        super.init(
//            contentRect: NSRect(
//                x: 0,
//                y: 0,
//                width: Constant.mainWidth,
//                height: Constant.mainHeight
//            ),
//            styleMask: [.nonactivatingPanel],
//            backing: .buffered,
//            defer: false
//        )
//        self.isReleasedWhenClosed = false
//        self.moveToUpCenter()
//        self.backgroundColor = .clear
//        self.hasShadow = false
//        self.level = .floating
//        self.contentView = NSHostingView(rootView: MainView())
//        self.isMovableByWindowBackground = true
//    }
//    
//    private func moveToUpCenter() {
//        guard let screen = NSScreen.main else {
//            Log.warning("move main window to up center - fail: get screen = nil")
//            return
//        }
//        let screenSize = screen.visibleFrame.size
//        let screenOrigin = screen.visibleFrame.origin
//        let windowSize = self.frame.size
//        let x = screenOrigin.x + (screenSize.width - windowSize.width) * 0.5
//        let y = screenOrigin.y + (screenSize.height - windowSize.height) * 0.8
//        self.setFrameOrigin(NSPoint(x: x, y: y))
//    }
//    
//    func show() {
//        self.makeKeyAndOrderFront(nil)
//    }
//    
//    func hide() {
//        self.close()
//    }
//    
//    override var canBecomeKey: Bool {
//        return true
//    }
//    
//}
