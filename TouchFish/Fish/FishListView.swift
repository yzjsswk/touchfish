import SwiftUI

struct FishListView: View {
    
    var fishList: [Fish]
    @Binding var selectedFishId: Int
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(fishList, id: \.id) { fish in
                        FishListItemView(
                            id: fish.id,
                            selectedFishId: $selectedFishId,
                            name: fish.itemPreview,
                            icon: fish.sourceAppIcon,
                            isMarked: fish.isMarked
                        ) {
                            fish.copyToClipboard()
                            TouchFishApp.deactivate()
                            pasteToFrontmostApp()
//                            Log.info("paste fish \(fish.id)")
                        }
                        .id(fish.id)
                        .frame(width: (Config.it.mainWidth - 30)/2, height: Config.it.fishItemHeight)
                    }
                }
                .padding(.vertical)
            }
            HStack {
                Text("images: [\(Cache.ImageCache.images.count):\(Cache.ImageCache.totalBytes/1024/1024)MB]")
                    .font(.footnote)
                Spacer()
                Text("total count: \(Cache.FishCache.totalCount)")
                    .font(.footnote)
            }
            .frame(width: (Config.it.mainWidth - 30)/2)

        }

    }
    
}

func pasteToFrontmostApp() {
    // 模拟粘贴操作 alfred运行时会失效
    if let frontApp = NSWorkspace.shared.frontmostApplication {
        frontApp.activate(options: .activateIgnoringOtherApps)
        let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true)
        keyEvent?.flags = [.maskCommand]
        keyEvent?.post(tap: .cghidEventTap)
//        AppleScriptRunner.doPaste()
    }
}

