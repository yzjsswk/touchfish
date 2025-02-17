import SwiftUI

struct MainView: View {
    
    @State var recipeExecutionContexts: [RecipeExecutionContext] = []
    
    @State var fishTags: [String] = []
    
    @State var pressedTab: TabBarView.Tab = .Home
    @State var isFullScreen: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                TabBarView(pressedTab: $pressedTab, isFullScreen: $isFullScreen, recipeExecutionContexts: $recipeExecutionContexts)
                Spacer()
            }
            .offset(y: -33 + (isFullScreen ? 28 : 0))
            RoundedRectangle(cornerRadius: 10)
            .fill("FDFDFD".color)
            .offset(y: 9 + (isFullScreen ? 28 : 0))
            VStack {
                switch pressedTab {
                case .Home:
                    HomeView()
                case .Setting:
                    CommandBarView(cells: ["Setting"], situation: .constant(.NotRecipe))
                    SettingView()
                    .padding(5)
                case .FishRepository:
                    CommandBarView(cells: ["Fish"], placeHolder: "search...", situation: .constant(.NotRecipe))
                    FishRepositoryView()
                case .RecipeManage:
                    CommandBarView(cells: ["Recipe"], situation: .constant(.NotRecipe))
                    RecipeManageView()
                case .RecipeExecution(let idx):
                    if idx < recipeExecutionContexts.count {
                        CommandBarView(
                            situation: Binding<CommandBarView.Situation>(
                                get: { return .MainWindowRecipe(recipeExecutionContexts[idx]) },
                                set: { newValue in
                                    if case let .MainWindowRecipe(context) = newValue {
                                        recipeExecutionContexts[idx] = context
                                    }
                                }
                            )
                        )
                        .id("recipe_command_bar_\(recipeExecutionContexts[idx].uid)")
                        RecipeExecutionView(context: $recipeExecutionContexts[idx], fishTags: $fishTags)
                        .id("recipe_execution_view_\(recipeExecutionContexts[idx].uid)")
                    } else {
                        EmptyView()
                    }
                default:
                    EmptyView()
                }
                Spacer()
            }
            .offset(y: isFullScreen ? 28 : 0)
            .padding(.top, 18)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                if let stats = await Storage.countFish() {
                    fishTags = stats.tagCount.keys.filter { !$0.isEmpty }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRefreshFish)) { _ in
            Task {
                if let stats = await Storage.countFish() {
                    fishTags = stats.tagCount.keys.filter { !$0.isEmpty }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .MainWindowEnterFullScreen)) { _ in
            withAnimation {
                isFullScreen = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .MainWindowExitFullScreen)) { _ in
            withAnimation {
                isFullScreen = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRemoveRecipeExecutionContext)) { notification in
            if let uid = notification.userInfo?["uid"] as? UUID {
                Task {
                    for (idx, context) in recipeExecutionContexts.enumerated() {
                        if await context.uid == uid {
                            recipeExecutionContexts.remove(at: idx)
                            if case .RecipeExecution(let pidx) = pressedTab {
                                if recipeExecutionContexts.count > 0 {
                                    let new_pidx = (pidx <= idx) ? ((pidx == recipeExecutionContexts.count) ? pidx-1 : pidx) : pidx-1
                                    pressedTab = .RecipeExecution(new_pidx)
                                } else {
                                    pressedTab = .Home
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
