import AppKit
import SwiftUI
import Carbon.HIToolbox.Events

let Monitor = MonitorManager.self

struct MonitorManager {
    
    enum MonitorType {
        case hideMainWindowWhenClickOutside
        case showOrHideMainWindowWhenKeyShortCutPressed
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
    
    static var localKeyBoardPressedAsyncEventMonitor: Any?
    static var hideMainWindowWhenClickOutsideMonitor: Any?
    static var clipboardListenerState: ClipboardListenerState = .unStarted
    static var lastClipboardData = UUID().uuidString.data(using: .utf8)
    
    static func start(type: MonitorType) {
        switch type {
        case .hideMainWindowWhenClickOutside:
            MonitorManager.hideMainWindowWhenClickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [] event in
                if Config.hideMainWindowWhenClickOutSideEnable && TouchFishApp.mainWindow.isVisible {
                    TouchFishApp.deactivate()
                }
            }
        case .showOrHideMainWindowWhenKeyShortCutPressed:
            GlobalKeyboardEventListener().startListening(keyboardShortcut: Config.appActiveKeyShortcut) { [] _ in
                if TouchFishApp.mainWindow.isVisible {
                    TouchFishApp.deactivate()
                } else {
                    TouchFishApp.activate()
                }
            }
        case .openFishRepositoryWhenKeyShortCutPressed:
            GlobalKeyboardEventListener().startListening(keyboardShortcut: Config.fishRepositoryActiveKeyShortcut) { [] _ in
                if !TouchFishApp.mainWindow.isVisible {
                    RecipeManager.goToRecipe(recipeId: "com.touchfish.FishRepository")
                    TouchFishApp.activate()
                }
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
                            var extraInfo = Fish.ExtraInfo()
                            if let sourceApp = NSWorkspace.shared.frontmostApplication,
                               let sourceAppName = sourceApp.localizedName {
                                extraInfo.sourceAppName = sourceAppName
                            }
                            let ex = extraInfo
                            let identity = Functions.getMD5(of: clipboardData.1)
                            Task {
                                if let fish = await Storage.pickFishByIdentity(identity: identity) {
                                    let newFish = await Storage.addFish(
                                        fish.fishType, fish.fishData, description: fish.description, tags: fish.tags,
                                        isMarked: fish.isMarked, isLocked: fish.isLocked, extraInfo: fish.extraInfo
                                    )
                                    if newFish == nil {
                                        Log.error("save fish from clipboard - fail: Storage.addFish return nil")
                                    }
                                } else {
                                    let newFish = await Storage.addFish(
                                        clipboardData.0, clipboardData.1, extraInfo: ex
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
        case .localKeyBoardPressedAsyncEvent:
            guard let monitor = MonitorManager.localKeyBoardPressedAsyncEventMonitor else { return }
            NSEvent.removeMonitor(monitor)
            MonitorManager.localKeyBoardPressedAsyncEventMonitor = nil
        case .hideMainWindowWhenClickOutside:
            guard let monitor = MonitorManager.hideMainWindowWhenClickOutsideMonitor else { return }
            NSEvent.removeMonitor(monitor)
            MonitorManager.hideMainWindowWhenClickOutsideMonitor = nil
        case .saveFishWhenClipboardChanges:
            if MonitorManager.clipboardListenerState != .unStarted {
                MonitorManager.clipboardListenerState = .stop
            }
        default:
            Log.warning("stop monitor - failed: not support, type=\(type)")
        }
    }
    
}
