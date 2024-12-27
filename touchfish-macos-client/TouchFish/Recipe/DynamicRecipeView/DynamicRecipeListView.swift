import SwiftUI

struct DynamicRecipeListView: View {
    
    var data: [Data]
    var item: DynamicRecipeViewInfo.ViewItem
    
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                (item.icon ?? Image(systemName: "doc.plaintext"))
                .resizable()
                .scaledToFit()
            }
            .frame(width: Constant.userDefinedRecipeItemHeight*0.5)
            .padding(.leading, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? Color.white: Color.black)
                if let desc = item.description {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .frame(width: Constant.mainWidth-30, height: Constant.userDefinedRecipeItemHeight)
        .background(isSelected ? Constant.selectedItemBackgroundColor : Constant.mainBackgroundColor)
        .cornerRadius(5)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
//        .onTapGesture {
//            for action in item.actions {
//                action.execute()
//            }
//        }
    }
    
}

struct UserDefinedRecipeListItemView2: View {
    
    var item: DynamicRecipeViewInfo.ViewItem
    var defaultItemIcon: String?
    
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                (item.icon ?? Image(systemName: "doc.plaintext"))
                .resizable()
                .scaledToFit()
            }
            .frame(width: Constant.userDefinedRecipeItemHeight*(isSelected ? 0.5 : 0.4))
            .padding(.leading, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                .font(.title3)
//                    .fontWeight(.bold)
                .foregroundColor(isSelected ? Color.white: Color.black)
                if let desc = item.description, isSelected {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .frame(width: Constant.mainWidth-30, height: isSelected ? Constant.userDefinedRecipeItemHeight : Constant.userDefinedRecipeItemHeight-15)
        .background(isSelected ? Constant.selectedItemBackgroundColor : Constant.mainBackgroundColor)
        .cornerRadius(5)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
//        .onTapGesture {
//            for action in item.actions {
//                action.execute()
//            }
//        }
    }
    
}
