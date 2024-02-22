import SwiftUI

struct FishListItemView: View {
    
    var id: Int
    @Binding var selectedFishId: Int
    var isSelected: Bool {
        return id == selectedFishId
    }
    
    var name: String?
    var desc: String?
    var icon: Image?
    var isMarked: Bool
    var action: () -> Void
    
    init(id: Int, selectedFishId: Binding<Int>, name: String? = nil, desc: String? = nil,  icon: Image? = nil, isMarked: Bool = false, action: @escaping () -> Void) {
        self.id = id
        self._selectedFishId = selectedFishId
        self.name = name
        self.desc = desc
        self.icon = icon
        self.isMarked = isMarked
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 10) {
            icon?
            .resizable()
            .scaledToFit()
//            .font(.largeTitle)
//            .foregroundColor(.red)
            VStack(alignment: .leading, spacing: 4) {
                if let name = name {
                    Text(name)
                    .font(.title2)
//                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? Color.white: Color.black)
                }
                if let desc = desc {
                    Text(desc)
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            Spacer()
            if isMarked {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.orange)
                    .onTapGesture {
                        let ok = DB.markFish(of: id, isMarked: false)
                        if !ok {
                            Log.warning("cancel mark fish(id=\(id)) failed")
                        }
                    }
            } else if isSelected {
                Image(systemName: "bookmark")
                    .foregroundColor(.orange)
                    .onTapGesture {
                        let ok = DB.markFish(of: id, isMarked: true)
                        if !ok {
                            Log.warning("mark fish(id=\(id)) failed")
                        }
                    }
            }
        }
        .frame(maxWidth: Config.it.mainWidth)
        .padding(5)
        .background(isSelected ? Config.it.selectedItemBackgroundColor.color : Config.it.mainBackgroundColor.color)
        .cornerRadius(5)
//        .shadow(color: Color.gray.opacity(0.3), radius: 2, x: 0, y: 2)
        .onTapGesture(count: 1, perform: action)
        .onHover { isHovered in
            if isHovered {
                selectedFishId = id
            }
        }
        
    }
    
}
