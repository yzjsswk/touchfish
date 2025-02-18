import SwiftUI

struct RecipeManageView: View {
    
    @State var allRecipes = RecipeManager.allRecipesList
    
    @State var selectedRecipe: Recipe? = nil
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if let selectedRecipe = selectedRecipe {
                RecipeManageDetailView(recipe: selectedRecipe, selectedRecipe: $selectedRecipe)
            } else {
                ForEach(allRecipes, id: \.0) { serverName, recipes in
                    VStack(alignment: .leading) {
                        RecipeManageServerView(serverName: serverName, recipes: recipes, selectedRecipe: $selectedRecipe)
                    }
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
    
    @Binding var selectedRecipe: Recipe?
    
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
                                canEdit: true,
                                enable: RecipeManager.isEnable(bundleId: recipe.bundleId)
                            )
                        }
                    }
                    .padding(8)
                }
                .frame(height: 65)
                .padding(.vertical, 5)
                .padding(.horizontal)
                .onTapGesture {
                    selectedRecipe = recipe
                }
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
            .onChange(of: enable) {
                if enable {
                    let _ = RecipeManager.enable(bundleId: bundleId)
                } else {
                    let _ = RecipeManager.disable(bundleId: bundleId)
                }
                RecipeManager.refresh()
            }
        
    }
    
}

struct RecipeManageDetailView: View {
    
    var recipe: Recipe
    @Binding var selectedRecipe: Recipe?
    
    @State var backButtonOnHovered: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "arrow.left.square")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 20, maxHeight: 20)
                        .foregroundStyle(.black.opacity(0.6))
                }
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill("C6C7F4".color.opacity(backButtonOnHovered ? 0.2 : 0))
                )
                .onHover { isHovering in
                    self.backButtonOnHovered = isHovering
                }
                .onTapGesture {
                    selectedRecipe = nil
                }
                Spacer()
            }
            Divider()
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(radius: 5)
                    HStack {
                        HStack {
                            recipe.icon
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(height: 30)
                        .padding(.horizontal, 5)
                        VStack(alignment: .leading) {
                            HStack {
                                Text(recipe.name)
                                .font(.title2)
                                Text(recipe.bundleId)
                                .foregroundStyle(.gray)
                                .font(.caption)
                                Spacer()
                            }
                            RecipeManageDetailCommandView(recipe: recipe)
                            if let desc = recipe.description {
                                Text(desc)
                                .foregroundStyle(.gray)
                                .font(.caption)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(String(recipe.version))
                                .font(.caption2)
                                Text("Version")
                                .foregroundStyle(.gray)
                                .font(.caption)
                            }
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(recipe.author)
                                .font(.caption2)
                                Text("Author")
                                .foregroundStyle(.gray)
                                .font(.caption)
                            }
                        }
                    }
                    .padding(10)
                }
                .padding(8)
                if let readme = recipe.readme {
                    if let readmeMd = try? AttributedString(markdown: readme) {
                        // todo: markdown render not correct
                        Text(readmeMd)
                    } else {
                        Text(readme)
                    }
                }
                
            }
        }
    }
    
}

struct RecipeManageDetailCommandView: View {
    
    var recipe: Recipe
    
    @State var isEditButtonHovered: Bool = false
    @State var isEditing: Bool = false
    @State var editingCommand: String = ""
    @State var isEditOkButtonHovered: Bool = false
    @State var isEditCancelButtonHovered: Bool = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "command.square.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.gray.opacity(0.6))
            }
            .frame(width: 15)
            if isEditing {
                TextField("", text: $editingCommand)
                .frame(width: 100, height: 20)
                .onAppear {
                    editingCommand = getCommand(recipe: recipe) ?? ""
                }
                Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isEditOkButtonHovered ? .green : .gray)
                .onHover { isHovered in
                    self.isEditOkButtonHovered = isHovered
                }
                .onTapGesture {
                    let editingCommand = self.editingCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                    if editingCommand != "" {
                        Config.recipeCommands[recipe.bundleId] = editingCommand
                    } else {
                        Config.recipeCommands.removeValue(forKey: recipe.bundleId)
                    }
                    if !Config.save() {
                        Log.warning("edit recipe command - failed: save config file failed, bundleId=\(recipe.bundleId), command=\(editingCommand)")
                    }
                    isEditing = false
                }
                Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isEditCancelButtonHovered ? .red : .gray)
                .onHover { isHovered in
                    self.isEditCancelButtonHovered = isHovered
                }
                .onTapGesture {
                    isEditing = false
                    editingCommand = ""
                }
            } else {
                if let command = getCommand(recipe: recipe) {
                    Text(command)
                    .font(.title3)
                }
                HStack {
                    Image(systemName: "pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 15, maxHeight: 15)
                        .foregroundStyle(.black.opacity(0.6))
                }
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill("C6C7F4".color.opacity(isEditButtonHovered ? 0.2 : 0))
                )
                .onHover { isHovering in
                    self.isEditButtonHovered = isHovering
                }
                .onTapGesture {
                    self.isEditing = true
                }
            }
            Spacer()
        }
    }
    
    private func getCommand(recipe: Recipe) -> String? {
        if let command = Config.recipeCommands[recipe.bundleId] {
            return command
        }
        return recipe.command
    }
    
}
