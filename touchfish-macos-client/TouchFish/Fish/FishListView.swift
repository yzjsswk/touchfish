import SwiftUI

struct FishListView: View {
    
    @Binding var fishList: [Fish]
    @Binding var selectedFishUid: String?
    @State var hoveringFishUid: String?
    @State var lastHoverTs: TimeInterval = Date().timeIntervalSince1970
    
    @Binding var isEditing: Bool
    @Binding var isMultSelecting: Bool
    @Binding var multSelectedFishUids: Set<String>
    
    @Binding var fishItemPosOffset: CGFloat
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach(Array(fishList.enumerated()), id: \.1.uid) { (idx, fish) in
                        FishListItemView(
                            fish: $fishList[idx],
                            selectedFishUid: $selectedFishUid,
                            hoveringFishUid: $hoveringFishUid,
                            isEditing: $isEditing,
                            isMultSelecting: $isMultSelecting,
                            multSelectedFishUids: $multSelectedFishUids
                        )
                        .offset(y: idx <= 16 ? (fishItemPosOffset*50*CGFloat(idx+1)) : 0)
                        .opacity(fishItemPosOffset == 0 ? 1 : 0)
                        .onHover { isHovered in
                            if isHovered {
                                selectedFishUid = fish.uid
                                if hoveringFishUid != fish.uid {
                                    hoveringFishUid = nil
                                }
                                lastHoverTs = Date().timeIntervalSince1970
                                let hoverTs = lastHoverTs
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    if isHovered && lastHoverTs == hoverTs {
                                        withAnimation(.spring(duration: 0.4)) {
                                            hoveringFishUid = fish.uid
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            HStack {
                Text("\(fishList.count) items")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
        }

    }
    
}



