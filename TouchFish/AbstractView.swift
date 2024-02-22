import SwiftUI

struct ListItemView: View {
    
    var name: String?
    var desc: String?
    var isSelected: Bool
    var icon: Image?
    var action: () -> Void
    
    init(name: String? = nil, desc: String? = nil, isSelected: Bool = false, icon: Image? = nil, action: @escaping () -> Void) {
        self.name = name
        self.desc = desc
        self.isSelected = isSelected
        self.icon = icon
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
        }
        .frame(maxWidth: Config.it.mainWidth)
        .padding(5)
        .background(isSelected ? Config.it.selectedItemBackgroundColor.color : Config.it.mainBackgroundColor.color)
        .cornerRadius(5)
//        .shadow(color: Color.gray.opacity(0.3), radius: 2, x: 0, y: 2)
        .onTapGesture(count: 1, perform: action)
        
    }
    
}
