import SwiftUI

struct DynamicRecipeStripItemView: View {
    
    var size: DynamicRecipeViewInfo.ViewItem.Size = .Medium
    var title: String
    var description: String?
    var iconPattern: String?
    var tags: [String]
    var operation: DynamicRecipeViewInfo.Operation?
    var value: String?
    var selectable: Bool
    
    @Binding var info: DynamicRecipeViewInfo
    
    @State var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                if let pattern = iconPattern, let image = info.patternToImage(pattern: pattern) {
                    image
                    .resizable()
                    .scaledToFit()
                } else {
                    Image(systemName: "doc.plaintext")
                    .resizable()
                    .scaledToFit()
                }
            }
            .frame(width: Constant.userDefinedRecipeItemHeight*0.5)
            .padding(.leading, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isHovered ? Color.white: Color.black)
                if let desc = description {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(desc)
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .frame(height: Constant.userDefinedRecipeItemHeight)
        .background(isHovered ? Constant.selectedItemBackgroundColor : Constant.mainBackgroundColor)
        .cornerRadius(5)
        .padding(.horizontal, 12)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
//        .onTapGesture {
//            for action in item.actions {
//                action.execute()
//            }
//        }
    }
    
}
