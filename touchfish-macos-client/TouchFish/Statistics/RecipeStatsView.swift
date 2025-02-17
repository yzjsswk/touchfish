import SwiftUI

struct RecipeStatsView: View {
    
    var body: some View {
        BarChartView(
            title: "Recipe Usage Count",
            data: [
                    Metrics.recipeUsageCount.map {
                        BarSlice(
                            label: RecipeManager.recipes[$0.key]?.name ?? $0.key,
                            value: $0.value,
                            color: String(Functions.getMD5(of: $0.key).suffix(6)).color
                        )
                    }.sorted {$0.value > $1.value}
            ],
            seriesName: ["default"],
            maxHeight: 120
        )
        .frame(height: 300)
        .padding()
    }
    
}
