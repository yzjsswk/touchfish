// ClipboardHistoryView.swift
//
// Created by TeChris on 05.04.21.

import SwiftUI
import Carbon.HIToolbox.Events

struct ClipboardHistoryView: View {
	@State private var selectedItemIndex = 0
	@State private var items = [ClipboardHistoryItem]()
	@State private var deleteKeyMonitor: Any!
	
	private let configuration = Configuration.decoded
	private let notificationCenter = NotificationCenter.default
	var body: some View {
		if items.count == 0 {
			Text("Your history is empty!")
				.font(configuration.resultItemFont.font)
		}
		HStack {
			ScrollView {
				ScrollViewReader { value in
					ForEach(items, id: \.id) { item in
						Button(action: {
							copySelectedItemToFrontMostApp()
						}) {
							ItemView(icon: nil, isSelectedItem: item.id == selectedItem.id) {
								if item.image != nil {
									Image(nsImage: item.image!)
										.resizable()
										.scaledToFit()
								} else if item.file != nil {
									Text(item.file!)
								} else if item.string != nil {
									Text(item.string!)
								}
							}
                            .onHover {
                                isHovered in
                                if isHovered {
                                    var idx = 0
                                    for it in items {
                                        if it.id == item.id {
                                            updateSelectedItemIndex(idx)
                                            break
                                        }
                                        idx += 1
                                    }
                                }
                            }
						}
						.id(item.id)
						.frame(height: configuration.resultItemHeight)
						.buttonStyle(PlainButtonStyle())
						
					}
//					.onChange(of: selectedItemIndex) { _ in
//						// Check if the selected item exists; If it does, then scroll down to the item.
//						if items.indices.contains(selectedItemIndex) {
//							value.scrollTo(items[selectedItemIndex].id, anchor: .center)
//						}
//					}
				}
			}
			.onReceive(notificationCenter.publisher(for: .ReturnKeyWasPressed)) { _ in
				// When the return key was pressed, then copy the selected item's data to the clipboard.
				copySelectedItemToFrontMostApp()
			}
			.onReceive(notificationCenter.publisher(for: .UpArrowKeyWasPressed)) { _ in
				// Update the index with an animation..
				updateSelectedItemIndex(selectedItemIndex - 1)
			}
			.onReceive(notificationCenter.publisher(for: .DownArrowKeyWasPressed)) { _ in
				// Update the index with an animation..
				updateSelectedItemIndex(selectedItemIndex + 1)
			}
			.onReceive(notificationCenter.publisher(for: .ShouldDeleteClipboardHistoryItem)) { _ in
				// Delete the currently selected item.
				deleteSelectedItem()
			}
			.onReceive(notificationCenter.publisher(for: .ShouldDeleteClipboardHistory)) { _ in
				// Delete the clipboard history.
				// Create a new history without items.
				let newHistory = ClipboardHistory(items: [ClipboardHistoryItem]())
				
				// Write the new history to disk.
				newHistory.write()
				
				// Update the views items.
				items = newHistory.items
			}
			if items.count > 0 {
				ScrollView {
					VStack {
						HStack {
							Spacer()
							if selectedItem.image != nil {
								Image(nsImage: selectedItem.image!)
									.resizable()
									.scaledToFit()
							} else if selectedItem.file != nil {
								Text(selectedItem.file!)
									.font(configuration.resultItemFont.font)
									.foregroundColor(configuration.textColor.color)
							} else if selectedItem.string != nil {
								HStack {
									Text(selectedItem.string!)
										.font(configuration.resultItemFont.font)
										.foregroundColor(configuration.textColor.color)
								}
							}
							Spacer()
						}
						.frame(maxWidth: configuration.maximumWidth / 2)
						Spacer()
					}
				}
			}
		}
		.onAppear {
			// Update the items. This is necessary, because for some reason, when the Application (ClipboardHistoryApp) gets deinitialized, and the user activates the history app again without updating the text, the items are still the old items from before.
			items = ClipboardHistory.decoded.items
			
			// Add a event monitor to check if the delete key was pressed.
			deleteKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
				if event.keyCode == kVK_Delete {
					// If the delete key was pressed, delete the currently selected item.
					self.deleteSelectedItem()
					return nil
				}
				
				return event
			}
		}
		.onDisappear {
			// When the view disappears, remove the delete key event monitor.
			NSEvent.removeMonitor(deleteKeyMonitor!)
		}
	}
	
	var selectedItem: ClipboardHistoryItem {
		return items[selectedItemIndex]
	}
	
	func updateSelectedItemIndex(_ index: Int) {
		// Check if an item with the new index is available.
		if items.indices.contains(index) {
			// Update the selected item with an animation..
			withAnimation(configuration.shouldAnimateNavigation ? .none : .none) {
				selectedItemIndex = index
			}
		}
	}
	
	func copySelectedItemToFrontMostApp() {
        print("do copy")
		selectedItem.copyToClipboard()
        Snap.default.deactivate()
        // TODO remove the copied item and copy it again (to move it top of the list)
//         deleteSelectedItem()
        if let toPasteString = NSPasteboard.general.string(forType: .string) {
            pasteToFrontMostApp(for: toPasteString)
        } else {
            print("剪贴板为空或不包含可粘贴的文本")
        }
	}
    
    func pasteToFrontMostApp(for s: String) {
        // 模拟粘贴操作 alfred运行时会失效
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            frontApp.activate(options: .activateIgnoringOtherApps)
            let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true)
            keyEvent?.flags = [.maskCommand]
            keyEvent?.post(tap: .cghidEventTap)
//            keyEvent?.flags = []
//            keyEvent?.post(tap: .cghidEventTap)
//
//            let typeStringEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
//            typeStringEvent?.keyboardSetUnicodeString(stringLength: pasteString.count, unicodeString: pasteString)
//            typeStringEvent?.post(tap: .cghidEventTap)
        }
    }
	
	func deleteSelectedItem() {
		// Create a updated history.
		var items = self.items
        if items.count > 0 {
            items.remove(at: selectedItemIndex)
        }
		let newHistory = ClipboardHistory(items: items)
		
		// Write the new history to disk.
		newHistory.write()
		
		// Update the view.
		updateSelectedItemIndex(selectedItemIndex - 1)
		self.items = items
	}
    
}
