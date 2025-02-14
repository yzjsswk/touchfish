import SwiftUI

struct DynamicRecipeView: View {
    
    var dynamicRecipeViewInfo: DynamicRecipeViewInfo
    
    var paraFieldEnable: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                ForEach(Array(dynamicRecipeViewInfo.items.enumerated()), id: \.0) { idx, item in
                    DynamicRecipeItemView(item: item, info: .constant(dynamicRecipeViewInfo), paraFieldEnable: paraFieldEnable)
                }
            }
            .padding(.vertical, 10)
        }
    }
        
}
