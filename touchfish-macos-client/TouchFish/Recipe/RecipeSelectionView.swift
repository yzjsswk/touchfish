import SwiftUI

struct RecipeSelectionView: View {
    
    @State var recipeList: [Recipe] = []
    
    @Binding var context: RecipeExecutionContext
    
    var body: some View {

        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(recipeList, id: \.bundleId) { recipe in
                        RecipeSelectionItemView(recipe: recipe, context: $context)
                    }
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            RecipeManager.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeRefreshed)) { _ in
            withAnimation {
                recipeList = RecipeManager.orderedRecipeList
            }
        }
        
    }
    
}

struct RecipeSelectionItemView: View {
    
    var recipe: Recipe
    
    @State var isSelected: Bool = false
    
    @Binding var context: RecipeExecutionContext
    
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
        }
        .padding(5)
        .frame(height: isSelected ? Constant.recipeItemSelectedHeight : Constant.recipeItemHeight)
        .background(isSelected ? "F0F0F3".color : Color.clear)
        .cornerRadius(10)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
        .onTapGesture(count: 1) {
            Task {
                await context.switchRecipe(recipe.bundleId)
                await context.executeIfAutomatic()
            }
        }
    }
    
}
