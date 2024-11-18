import SwiftUI

struct RecipeListView: View {
    
    @Binding var recipeList: [Recipe]
    
    var body: some View {

        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(recipeList.filter {$0.order < 0}, id: \.bundleId) { recipe in
                        RecipeItemView(recipe: recipe)
                    }
//                    Divider()
//                        .padding()
                    ForEach(recipeList.filter {$0.order >= 0}, id: \.bundleId) { recipe in
                        RecipeItemView(recipe: recipe)
                    }
                }
                .padding(.vertical)
            }
        }
        
    }
    
}
