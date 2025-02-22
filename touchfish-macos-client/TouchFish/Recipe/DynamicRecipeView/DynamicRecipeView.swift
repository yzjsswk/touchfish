import SwiftUI

struct DynamicRecipeView: View {
    
    @Binding var context: RecipeExecutionContext
    
    var dynamicRecipeViewInfo: DynamicRecipeViewInfo
    var paraFieldEnable: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(Array(dynamicRecipeViewInfo.items.enumerated()), id: \.0) { idx, item in
                    DynamicRecipeItemView(
                        context:$context, item: item, info: .constant(dynamicRecipeViewInfo), paraFieldEnable: paraFieldEnable
                    )
                }
            }
            .padding(.vertical, 10)
        }
    }
        
}
