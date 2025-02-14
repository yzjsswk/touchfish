import SwiftUI

struct MainView: View {
    
    @State var recipeExecutionContexts: [RecipeExecutionContext] = []
    
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
                    ZStack {
                        Color.gray.opacity(0.05)
                        VStack {
                            Text("Welcome!")
                            .font(.title)
                        }
                    }
                    .cornerRadius(10)
                    .padding(10)
                case .Setting:
                    CommandBarView(cells: ["Setting"], situation: .constant(.NotRecipe))
                    SettingView()
                case .FishRepository:
                    CommandBarView(cells: ["Fish Repository"], placeHolder: "search...", situation: .constant(.NotRecipe))
                    FishRepositoryView()
                case .RecipeManage:
                    CommandBarView(cells: ["Recipe Manage"], situation: .constant(.NotRecipe))
                    RecipeManageView()
                case .Statistics:
                    CommandBarView(cells: ["Statistics"], situation: .constant(.NotRecipe))
                    StatsView()
                case .RecipeExecution(let idx):
                    if idx < recipeExecutionContexts.count {
                        CommandBarView(
                            text: "",
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
                        RecipeExecutionView(context: $recipeExecutionContexts[idx])
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
