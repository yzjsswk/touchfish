import SwiftUI

struct MainView: View {
    
    @State var recipeList: [Recipe] = []
    @State var activeRecipeBundleId: String?
    
    @State var topics: [Topic] = []
    
    @State var commandText = ""
    @State var commandCell: [String] = []
    
    var body: some View {
        ZStack {
            Constant.mainBackgroundColor
            VStack {
                CommandBarView(commandText: $commandText, commandCell: $commandCell)
                if let activeRecipeBundleId = activeRecipeBundleId {
                    switch activeRecipeBundleId {
                    case "com.touchfish.RecipeManage":
                        RecipeManageView()
                    case "com.touchfish.Topics":
                        TopicListView(topics: $topics)
                    case "com.touchfish.Statistics":
                        StatsView()
                    case "com.touchfish.Setting":
                        SettingView()
                    case "com.touchfish.FishRepository":
                        FishRepositoryView()
                    case "com.touchfish.AddFish":
                        FishAddView()
                    default:
                        if let activeRecipe = RecipeManager.activeRecipe {
                            DynamicRecipeView(activeRecipe: activeRecipe)
                        } else {
                            EmptyView()
                        }
                    }
                } else {
                    RecipeListView(recipeList: $recipeList)
                }
                Spacer()
            }
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                .shadow(radius: 5)
        )
        .onAppear {
            RecipeManager.refresh()
            NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
            Task {
                let fishs = await Storage.searchFish()
                NotificationCenter.default.post(name: .FishRefreshed, object: nil, userInfo: ["fish":fishs])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeRefreshed)) { _ in
            withAnimation {
                recipeList = RecipeManager.orderedRecipeList
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
            if let recipe = RecipeManager.activeRecipe {
                activeRecipeBundleId = recipe.bundleId
                commandCell.removeAll()
                commandCell.append(recipe.name)
                for (k, v) in RecipeManager.activeRecipeAddOrderArg {
                    commandCell.append("\(k):\(v)")
                }
            } else {
                RecipeManager.refresh()
                NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                activeRecipeBundleId = nil
                commandCell.removeAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandTextChanged)) { notification in
            if let commandText = notification.userInfo?["commandText"] as? String, self.commandText != commandText {
                self.commandText = commandText
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRefreshTopic)) { _ in
            Task {
                let topics = await Storage.listTopic()
                withAnimation(.spring(duration: 0.2)) {
                    self.topics = topics.sorted(by: { $0.createTime > $1.createTime })
                }
                let unreadCount = self.topics.reduce(into: 0) { acc, it in
                    acc += it.messages.filter({ !$0.hasRead }).count
                }
                Topic.unreadMsgCount = unreadCount
//                Log.debug("topic refreshed: \(unreadCount)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .EscapeKeyWasPressed)) { _ in
            TouchFishApp.deactivate()
        }
        .onChange(of: activeRecipeBundleId) {
            if let activeRecipeBundleId = activeRecipeBundleId {
                Metrics.recipeUseCount[activeRecipeBundleId, default: 0] += 1
                Metrics.save()
            }
        }
    }
    
}
