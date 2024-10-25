import SwiftUI

struct MainView: View {
    
    @State var recipeList: [Recipe] = []
    @State var activeRecipeBundleId: String?
    
    @State var commandText = ""
    @State var commandCell: [String] = []
    
    var body: some View {
        ZStack {
            Constant.mainBackgroundColor
            VStack {
                CommandBarView(commandText: $commandText, commandCell: $commandCell)
                if let activeRecipeBundleId = activeRecipeBundleId {
                    switch activeRecipeBundleId {
                    case "com.touchfish.FishRepository":
                        FishRepositoryView()
                    case "com.touchfish.AddFish":
                        FishAddView()
                    case "com.touchfish.Statistics":
                        StatsView()
                    case "com.touchfish.Setting":
                        SettingView()
                    case "com.touchfish.MessageCenter":
                        MessageCenterView()
                    case "com.touchfish.RecipeStore":
                        VStack {
                            Spacer()
                            Text("Not   Avaliable")
                                .foregroundStyle(.gray)
                                .font(.largeTitle)
                                .offset(x:0, y:-60)
                            Spacer()
                        }
                    default:
                        RecipeView(recipeList: $recipeList, activeRecipeBundleId: activeRecipeBundleId)
                    }
                } else {
                    RecipeView(recipeList: $recipeList)
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
            Task {
                let fishs = await Storage.searchFish()
                NotificationCenter.default.post(name: .FishRefreshed, object: nil, userInfo: ["fish":fishs])
            }
            withAnimation {
                RecipeManager.refresh()
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
                activeRecipeBundleId = nil
                commandCell.removeAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandTextChanged)) { notification in
            if let commandText = notification.userInfo?["commandText"] as? String {
                self.commandText = commandText
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
