import Carbon.HIToolbox.Events

struct KeyboardShortcut: Codable {
    
    enum Modifier: String, Codable {
        case command
        case option
        case control
        case shift
    }
    
    enum KeyEvent: String, Codable {
        case keyDown
        case keyUp
    }
    
    var keyCode: UInt32
    
    var modifiers: [Modifier]
    
    var events: [KeyEvent]
    
    var carbonModifiers: UInt32 {
        var result = 0
        if modifiers.contains(.command) {
            result += cmdKey
        }
        if modifiers.contains(.option) {
            result += optionKey
        }
        if modifiers.contains(.control) {
            result += controlKey
        }
        if modifiers.contains(.shift) {
            result += shiftKey
        }
        return UInt32(result)
    }
    
    var id: UInt32 {
        let id = keyCode + carbonModifiers
        return id
    }
    
    // convert self.keyCode to the character
    // https://stackoverflow.com/a/35138823 https://gist.github.com/ArthurYidi/3af4ccd7edc87739530476fc80a22e12
    var character: String? {
        let keyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutPointer = TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData) else { fatalError("Failed to get layout data.") }
        let layoutData = Unmanaged<CFData>.fromOpaque(layoutPointer).takeUnretainedValue() as Data
        var deadKeyState: UInt32 = 0
        var stringLength = 0
        var unicodeString = [UniChar](repeating: 0, count: 255)
        let status = layoutData.withUnsafeBytes {
            UCKeyTranslate(
                $0.bindMemory(to: UCKeyboardLayout.self).baseAddress,
                UInt16(self.keyCode),
                UInt16(kUCKeyActionDown),
                0,
                UInt32(LMGetKbdType()),
                0,
                &deadKeyState,
                255,
                &stringLength,
                &unicodeString
            )
        }
        if status != noErr {
            return nil
        }
        let string = NSString(characters: unicodeString, length: stringLength) as String
        if string.count <= 0 {
            return nil
        }
        return string
    }
    
}

class GlobalKeyboardEventListener {

    private var currentEvent: KeyboardShortcut.KeyEvent = .keyUp
	
    func startListening(keyboardShortcut: KeyboardShortcut, actionOnEvent: @escaping (KeyboardShortcut.KeyEvent) -> Void) {
		let eventHotKeyID = EventHotKeyID(signature: FourCharCode(1397966955), id: keyboardShortcut.id)
		var eventHotKey: EventHotKeyRef?
		RegisterEventHotKey(keyboardShortcut.keyCode, keyboardShortcut.carbonModifiers, eventHotKeyID, GetEventDispatcherTarget(), 0, &eventHotKey)
		var eventHandler: EventHandlerRef?
		var eventSpecification = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)
            ),
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)
            )
        ]
		InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                NotificationCenter.default.post(name: NSNotification.Name("HotKeyWithID\(hotKeyID.id)"), object: nil)
                return 0
            },
            2,
            &eventSpecification,
            nil,
            &eventHandler
        )
		NotificationCenter.default.addObserver(forName: Notification.Name("HotKeyWithID\(eventHotKeyID.id)"), object: nil, queue: nil) { [self] _ in
			if currentEvent == .keyUp {
				currentEvent = .keyDown
			} else {
				currentEvent = .keyUp
			}
			if keyboardShortcut.events.contains(currentEvent) {
				actionOnEvent(currentEvent)
			}
		}
	}
    
}
