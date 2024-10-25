import SwiftUI

struct FishListView: View {
    
    @Binding var fishList: [Fish]
    @Binding var selectedFishIdentity: String?
    @State var hoveringFishIdentity: String?
    @State var lastHoverTs: TimeInterval = Date().timeIntervalSince1970
    
    @Binding var isEditing: Bool
    @Binding var isMultSelecting: Bool
    @Binding var multSelectedFishIdentitys: Set<String>
    
    @Binding var fishItemPosOffset: CGFloat
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(Array(fishList.enumerated()), id: \.1.identity) { (idx, fish) in
                        FishListItemView(
                            fish: $fishList[idx],
                            selectedFishIdentity: $selectedFishIdentity,
                            hoveringFishIdentity: $hoveringFishIdentity,
                            isEditing: $isEditing,
                            isMultSelecting: $isMultSelecting,
                            multSelectedFishIdentitys: $multSelectedFishIdentitys
                        )
                        .offset(y: idx <= 16 ? (fishItemPosOffset*50*CGFloat(idx+1)) : 0)
                        .opacity(fishItemPosOffset == 0 ? 1 : 0)
                        .onHover { isHovered in
                            if isHovered {
                                selectedFishIdentity = fish.identity
                                if hoveringFishIdentity != fish.identity {
                                    hoveringFishIdentity = nil
                                }
                                lastHoverTs = Date().timeIntervalSince1970
                                let hoverTs = lastHoverTs
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    if isHovered && lastHoverTs == hoverTs {
                                        withAnimation(.spring(duration: 0.4)) {
                                            hoveringFishIdentity = fish.identity
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
                Text("total: \(fishList.count)")
                    .font(.system(.footnote, design: .monospaced))
                Spacer()
            }
        }

    }
    
}



