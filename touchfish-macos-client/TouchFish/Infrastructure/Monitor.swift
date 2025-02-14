import AppKit
import SwiftUI
import Carbon.HIToolbox.Events

let Monitor = MonitorManager.self

struct MonitorManager {
    
    enum MonitorType {
        case MainWindowTabBarControll
        case HideQuickExecutionWindowWhenClickOutside
        case ShowOrHideQuickExecutionWindowWhenKeyShortCutPressed
        
        case backWhenAssistiveClick
        case openFishRepositoryWhenKeyShortCutPressed
        case localKeyBoardPressedAsyncEvent
        case saveFishWhenClipboardChanges
    }

    enum ClipboardListenerState {
        case unStarted // app just run and listener function has not start running
        case stop // function has been running, but stop working
        case ready // function has been running, but waiting for clipboard data change once (should ignore the first data)
        case running // normal running, works whenever clipbaord data changes
    }
    
    static var hoverInMainWindowTabBarMonitor: Any?
    static var leftClickInMainWindowTabBarMonitor: Any?
    static var rightClickInMainWindowTabBarMonitor: Any?
    static var hideQuickExecutionWindowWhenClickOutsideMonitor: Any?
    
    static var localKeyBoardPressedAsyncEventMonitor: Any?
    static var backWhenAssistiveClickMonitor: Any?
    static var clipboardListenerState: ClipboardListenerState = .unStarted
    static var lastClipboardData = UUID().uuidString.data(using: .utf8)
    
    static func start(type: MonitorType) {
        switch type {
        case .MainWindowTabBarControll:
            MonitorManager.hoverInMainWindowTabBarMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [] event in
                if event.window != nil, let window = NSApp.windows.first {
                    let x = event.locationInWindow.x
                    let y = window.frame.size.height - event.locationInWindow.y
                    if x > 0 && y > 0 && y < Constant.mainWindowTabBarHeight-10 {
                        NotificationCenter.default.post(name: .HoverInMainWindowTabBar, object: nil, userInfo: ["shift": x])
                    }
                }
                return event
            }
            MonitorManager.leftClickInMainWindowTabBarMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [] event in
                if event.window != nil, let window = NSApp.windows.first {
                    let x = event.locationInWindow.x
                    let y = window.frame.size.height - event.locationInWindow.y
                    if x > 0 && y > 0 && y < Constant.mainWindowTabBarHeight-10 {
                        NotificationCenter.default.post(name: .LeftClickInMainWindowTabBar, object: nil, userInfo: ["shift": x])
                    }
                }
                return event
            }
            MonitorManager.rightClickInMainWindowTabBarMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [] event in
                if event.window != nil, let window = NSApp.windows.first {
                    let x = event.locationInWindow.x
                    let y = window.frame.size.height - event.locationInWindow.y
                    if x > 0 && y > 0 && y < Constant.mainWindowTabBarHeight-10 {
                        NotificationCenter.default.post(name: .RightClickInMainWindowTabBar, object: nil, userInfo: ["shift": x])
                    }
                }
                return event
            }
        case .ShowOrHideQuickExecutionWindowWhenKeyShortCutPressed:
            GlobalKeyboardEventListener().startListening(keyboardShortcut: Config.appActiveKeyShortcut) { [] _ in
                if TouchFishApp.quickExecutionWindow.isVisible {
                    TouchFishApp.quickExecutionWindow.hide()
                } else {
                    TouchFishApp.quickExecutionWindow.show()
                }
            }
        case .HideQuickExecutionWindowWhenClickOutside:
            MonitorManager.hideQuickExecutionWindowWhenClickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [] event in
                if Config.hideMainQuickExecutionWindowWhenClickOutSideEnable && TouchFishApp.quickExecutionWindow.isVisible {
                    TouchFishApp.quickExecutionWindow.hide()
                }
            }
        case .backWhenAssistiveClick:
            MonitorManager.backWhenAssistiveClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [] event in
                if Config.backWhenAssistiveClick {
                    NotificationCenter.default.post(name: .ShouldBack, object: nil)
                }
                return nil
            }

        case .openFishRepositoryWhenKeyShortCutPressed:
            GlobalKeyboardEventListener().startListening(keyboardShortcut: Config.fishRepositoryActiveKeyShortcut) { [] _ in
//                if !TouchFishApp.quickExecutionWindow.isVisible {
//                    RecipeManager.goToRecipe(recipeId: "com.touchfish.FishRepository")
//                    TouchFishApp.activate()
//                }
            }
        case .localKeyBoardPressedAsyncEvent:
            MonitorManager.localKeyBoardPressedAsyncEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [] event in
                if event.keyCode == kVK_UpArrow {
                    NotificationCenter.default.post(name: .UpArrowKeyWasPressed, object: nil)
                    return event
                }
                if event.keyCode == kVK_DownArrow {
                    NotificationCenter.default.post(name: .DownArrowKeyWasPressed, object: nil)
                    return event
                }
                if event.keyCode == kVK_Tab {
                    NotificationCenter.default.post(name: .TabKeyWasPressed, object: nil)
                    return event
                }
                if event.keyCode == kVK_Escape {
                    NotificationCenter.default.post(name: .EscapeKeyWasPressed, object: nil)
                    return nil
                }
                if event.keyCode == kVK_Space {
                    NotificationCenter.default.post(name: .SpaceKeyWasPressed, object: nil)
                    return event
                }
                if event.keyCode == kVK_Delete {
                    NotificationCenter.default.post(name: .DeleteKeyWasPressed, object: nil)
                    return event
                }
                let characters = event.charactersIgnoringModifiers ?? ""
                if characters == "\r" {
                    NotificationCenter.default.post(name: .ReturnKeyWasPressed, object: nil)
                    return event
                }
                return event
            }
            case .saveFishWhenClipboardChanges:
                if MonitorManager.clipboardListenerState == .unStarted {
                    listenToClipboardChanges()
                }
                MonitorManager.clipboardListenerState = .ready
                // loop running:
                func listenToClipboardChanges() {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        if let clipboardData = Functions.getDataFromClipboard(),
                                clipboardData.1 != MonitorManager.lastClipboardData {
//                            Log.debug("clipboard changed")
                            MonitorManager.lastClipboardData = clipboardData.1
                            if MonitorManager.clipboardListenerState == .ready {
                                MonitorManager.clipboardListenerState = .running
                                listenToClipboardChanges()
                                return
                            }
                            if MonitorManager.clipboardListenerState != .running {
                                listenToClipboardChanges()
                                return
                            }
                            if !Config.autoImportedFromClipboard {
                                return
                            }
                            let extraInfo: [String:String]
                            if let sourceApp = NSWorkspace.shared.frontmostApplication,
                               let sourceAppName = sourceApp.localizedName {
                                extraInfo = ["source": "Copy From \(sourceAppName)"]
                            } else {
                                extraInfo = [:]
                            }
                            let identity = Functions.getMD5(of: clipboardData.1)
                            Task {
                                if let fish = await Storage.pickFishByIdentity(identity: identity) {
                                    await Storage.pinFish([fish.uid])
                                } else {
                                    let newFish = await Storage.addFish(
                                        clipboardData.0, clipboardData.1, extraInfo: extraInfo
                                    )
                                    if newFish == nil {
                                        Log.error("save fish from clipboard - fail: Storage.addFish return nil")
                                    }
                                }
                            }
                        }
                        listenToClipboardChanges()
                    }
                }
        }
    }
    
    static func stop(type: MonitorType) {
        switch type {
        case .MainWindowTabBarControll:
            if let monitor = MonitorManager.hoverInMainWindowTabBarMonitor {
                NSEvent.removeMonitor(monitor)
                MonitorManager.hoverInMainWindowTabBarMonitor = nil
            }
            if let monitor = MonitorManager.leftClickInMainWindowTabBarMonitor {
                NSEvent.removeMonitor(monitor)
                MonitorManager.leftClickInMainWindowTabBarMonitor = nil
            }
            if let monitor = MonitorManager.rightClickInMainWindowTabBarMonitor {
                NSEvent.removeMonitor(monitor)
                MonitorManager.rightClickInMainWindowTabBarMonitor = nil
            }
        case .HideQuickExecutionWindowWhenClickOutside:
            if let monitor = MonitorManager.hideQuickExecutionWindowWhenClickOutsideMonitor {
                NSEvent.removeMonitor(monitor)
                MonitorManager.hideQuickExecutionWindowWhenClickOutsideMonitor = nil
            }
        case .localKeyBoardPressedAsyncEvent:
            guard let monitor = MonitorManager.localKeyBoardPressedAsyncEventMonitor else { return }
            NSEvent.removeMonitor(monitor)
            MonitorManager.localKeyBoardPressedAsyncEventMonitor = nil
        case .backWhenAssistiveClick:
            guard let monitor = MonitorManager.backWhenAssistiveClickMonitor else { return }
            NSEvent.removeMonitor(monitor)
            MonitorManager.backWhenAssistiveClickMonitor = nil
        case .saveFishWhenClipboardChanges:
            if MonitorManager.clipboardListenerState != .unStarted {
                MonitorManager.clipboardListenerState = .stop
            }
        default:
            Log.warning("stop monitor - failed: not support, type=\(type)")
        }
    }
    
}
