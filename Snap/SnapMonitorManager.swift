//
//  SnapMonitorManager.swift
//  Snap
//
//  Created by ByteDance on 2023/11/19.
//

import SwiftUI
import Carbon.HIToolbox.Events

class SnapMonitorManager {
    
    static func startSearchWindowShouldCloseMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) {
            [] event in
            if Snap.default.searchWindow.isVisible {
                Snap.default.deactivate()
            }
        }
    }
    
    static var localKeyboardPressMonitor: Any?
    static func startLocalKeyboardPressMonitor() {
        self.localKeyboardPressMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [] event in
            if event.keyCode == kVK_UpArrow {
                NotificationCenter.default.post(name: .UpArrowKeyWasPressed, object: nil)
                return nil
            }
            if event.keyCode == kVK_DownArrow {
                NotificationCenter.default.post(name: .DownArrowKeyWasPressed, object: nil)
                return nil
            }
            if event.keyCode == kVK_Tab {
                NotificationCenter.default.post(name: .TabKeyWasPressed, object: nil)
                return nil
            }
            if event.keyCode == kVK_Escape {
                NotificationCenter.default.post(name: .EscapeKeyWasPressed, object: nil)
                Snap.default.deactivate()
                return nil
            }
            
            // Check if the key combination for Quick Look was pressed.
            // Get the keyboard shortcut.
            let quickLookKeyboardShortcut = Configuration.decoded.quickLookKeyboardShortcut
            // Get the keyboard shortcut modifiers.
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).keyboardShortcutModifiers
            if event.keyCode == quickLookKeyboardShortcut.key.keyCode && quickLookKeyboardShortcut.modifiers == modifiers {
                NotificationCenter.default.post(name: .ShouldPresentQuickLook, object: nil)
                return nil
            }
            
            // Get the event's characters.
            let characters = event.charactersIgnoringModifiers ?? ""
            // The return key was pressed.
            if characters == "\r" {
                NotificationCenter.default.post(name: .ReturnKeyWasPressed, object: nil)
                return nil
            }
            
            return event
        }
    }
    
    static func stopLocalKeyboardPressMonitor() {
        guard let monitor = SnapMonitorManager.localKeyboardPressMonitor else { return }
        NSEvent.removeMonitor(monitor)
        SnapMonitorManager.localKeyboardPressMonitor = nil
    }
    
    static func startSearchWindowShowSwitchMonitor() {
        SnapMonitorManager.addGlobalKeyboardEventListener(
            keyboardShortcut: Configuration.decoded.activationKeyboardShortcut,
            actionOnEvent: { [] _ in
                if Snap.default.searchWindow.isVisible {
                    Snap.default.deactivate()
                } else {
                    Snap.default.activate()
                }
            }
        )
    }
    
    private static func addGlobalKeyboardEventListener(keyboardShortcut: KeyboardShortcut, actionOnEvent: @escaping (KeyEvent) -> Void) {
        KeyboardShortcutManager(keyboardShortcut: keyboardShortcut).startListeningForEvents(actionOnEvent: actionOnEvent)
    }
    
    
    
}
