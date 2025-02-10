import SwiftUI

struct RecipeListView: View {
    
    @State var recipeList: [Recipe] = []
    
    var body: some View {

        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(recipeList.filter {$0.order < 0}, id: \.bundleId) { recipe in
                        RecipeItemView(recipe: recipe)
                    }
                    ForEach(recipeList.filter {$0.order >= 0}, id: \.bundleId) { recipe in
                        RecipeItemView(recipe: recipe)
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
