import SwiftUI
import SwiftUICharts

struct StatsView: View {
    
    @State var statistics: CountFishResp? = nil
    @State var selectedTab: StatsTabView.StatsTab = .Fish
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            StatsTabView(selectedTab: $selectedTab)
                .frame(width: Constant.mainWidth*0.4)
            switch selectedTab {
            case .Fish:
                if let statistics = statistics {
                    FishStatsView(statistics: statistics)
                }
            case .Recipe:
                RecipeStatsView()
            }
        }
        .onAppear {
            Task {
                statistics = await Storage.countFish()
            }
        }
    }
    
}

struct StatsTabView: View {
    
    enum StatsTab: String, CaseIterable {
        case Fish
        case Recipe
    }
    
    struct StatsTabItemView: View {
        
        var title: String
        var isSelected: Bool
        
        @State var isHovered: Bool = false
        
        var body: some View {
            ZStack {
                isSelected ? Constant.selectedItemBackgroundColor.opacity(1.0) : (
                    isHovered ? Constant.selectedItemBackgroundColor.opacity(0.6) :
                        Functions.makeLinearGradient(colors: [.white]).opacity(1.0)
                )
                Text(title)
                    .font(.title3)
                    .foregroundStyle(isSelected || isHovered ? .white : .black)
                    .bold()
                    .padding()
            }
            .cornerRadius(8)
            .onHover { isHovered in
                self.isHovered = isHovered
            }
        }
        
    }
    
    @Binding var selectedTab: StatsTab
    
    var body: some View {
        HStack {
            ForEach(StatsTab.allCases, id:\.self) { tab in
                StatsTabItemView(title: tab.rawValue, isSelected: selectedTab == tab)
                    .onTapGesture {
                        selectedTab = tab
                    }
            }
        }
    }
    
}



