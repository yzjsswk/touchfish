import SwiftUI

struct RecipeItemView: View {
    
    var recipe: Recipe
    
    @State var isSelected: Bool = false
    
    @State var unreadMessageCount = Topic.unreadMsgCount
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                recipe.icon
                .resizable()
                .scaledToFit()
                .foregroundColor(isSelected ? Constant.mainTextColor.color: Constant.mainTextColor.color)
            }
            .frame(width: Constant.recipeItemHeight)
            .padding(.leading, 2.5)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name)
                        .font(.title3)
                        .foregroundColor(isSelected ? Constant.mainTextColor.color: Constant.mainTextColor.color)
                    if let command = recipe.command {
                        Text(command)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? Constant.mainTextColor.color: Constant.mainTextColor.color)
                    }
                }
                if let desc = recipe.description, isSelected {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
            if recipe.bundleId == "com.touchfish.Topics", unreadMessageCount > 0 {
                ZStack {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Constant.unreadMessageTipColor)
                    Text(String(unreadMessageCount))
                        .font(.custom("Menlo", size: 12))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(5)
        .frame(width: Constant.mainWidth-30, height: isSelected ? Constant.recipeItemSelectedHeight : Constant.recipeItemHeight)
        .background(isSelected ? "F0F0F3".color : Color.clear)
//        .saturation(1.0)
        .cornerRadius(10)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
        .onTapGesture(count: 1) {
            RecipeManager.goToRecipe(recipeId: recipe.bundleId)
        }
        .onAppear {
            unreadMessageCount = Topic.unreadMsgCount
        }
    }
    
}
