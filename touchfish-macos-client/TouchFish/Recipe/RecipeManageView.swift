import SwiftUI

struct RecipeManageView: View {
    
    @State var allRecipes = RecipeManager.allRecipesList
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            ForEach(allRecipes, id: \.0) { serverName, recipes in
                VStack(alignment: .leading) {
                    RecipeManageServerView(serverName: serverName, recipes: recipes)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            RecipeManager.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeRefreshed)) { _ in
            allRecipes = RecipeManager.allRecipesList
        }
    }
    
}

struct RecipeManageServerView: View {
    
    var serverName: String
    var recipes: [Recipe]
    
    var body: some View {
        Text("\(serverName) (\(recipes.count) recipes)")
            .font(.title2)
            .padding(.vertical, 5)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(recipes, id: \.bundleId) { recipe in
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(radius: 5)
                    HStack {
                        VStack {
                            recipe.icon
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(height: 30)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(recipe.name)
                            Spacer()
                            RecipeManageToggleView(
                                serverName: serverName,
                                bundleId: recipe.bundleId,
                                canEdit: RecipeManager.canEditSetting(serverName: serverName, bundleId: recipe.bundleId),
                                enable: RecipeManager.isEnable(serverName: serverName, bundleId: recipe.bundleId)
                            )
                        }
                    }
                    .padding(8)
                }
                .frame(height: 65)
                .padding(.vertical, 5)
                .padding(.horizontal)
            }
        }
    }
    
}


struct RecipeManageToggleView: View {
    
    var serverName: String
    var bundleId: String
    var canEdit: Bool
    @State var enable: Bool
    
    var body: some View {
        
        Toggle("", isOn: $enable)
            .toggleStyle(SwitchToggleStyle())
            .disabled(!canEdit)
            .onChange(of: enable) { old, new in
                let key = "\(serverName).\(bundleId)"
                if var setting = RecipeManager.recipeSetting[key] {
                    setting.enable = new
                    RecipeManager.recipeSetting[key] = setting
                } else if new {
                    RecipeManager.recipeSetting[key] = RecipeManager.RecipeSetting(
                        serverName: serverName, bundleId: bundleId, enable: new, order: 0
                    )
                }
                RecipeManager.saveRecipeSetting()
                RecipeManager.refresh()
            }
        
    }
    
}
