import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct RecipeSelectionView: View {
    
    @State var recipeList: [Recipe] = []
    
    @Binding var context: RecipeExecutionContext
    
    @State var draggedRecipe: Recipe?
    @State var draggingHoveringRecipe: Recipe?
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(recipeList, id: \.bundleId) { recipe in
                        RecipeSelectionItemView(recipe: recipe, context: $context)
                        .onDrag {
                            draggedRecipe = recipe
                            return NSItemProvider(item: recipe.bundleId.data(using: .utf8) as NSData?, typeIdentifier: UTType.data.identifier)
                        }
                        .onDrop(
                            of: [.data],
                            delegate: RecipeSelectionViewDraggingDelegate(
                                recipe: recipe,
                                draggedRecipe: $draggedRecipe,
                                draggingHoveringRecipe: $draggingHoveringRecipe,
                                recipeList: $recipeList
                            )
                        )
                    }
                }
            }
        }
        .onAppear {
            RecipeManager.refresh()
        }
        .onDrop(
            of: [.data],
            delegate: RecipeSelectionViewDropDelegate(
                draggedRecipe: $draggedRecipe,
                draggingHoveringRecipe: $draggingHoveringRecipe,
                recipeList: $recipeList
            )
        )
        .padding(.vertical)
        .onReceive(NotificationCenter.default.publisher(for: .RecipeRefreshed)) { _ in
            withAnimation {
                recipeList = RecipeManager.orderedRecipeList
            }
        }
    }
    
}

struct RecipeSelectionViewDraggingDelegate: DropDelegate {
    
    var recipe: Recipe
    
    @Binding var draggedRecipe: Recipe?
    @Binding var draggingHoveringRecipe: Recipe?
    @Binding var recipeList: [Recipe]
    
    func performDrop(info: DropInfo) -> Bool {
        if let draggedRecipe = draggedRecipe, let draggingHoveringRecipe = draggingHoveringRecipe {
            var draggedIdx: Int? = nil
            var hoveringIdx: Int? = nil
            for (idx, recipe) in recipeList.enumerated() {
                if recipe.bundleId == draggedRecipe.bundleId {
                    draggedIdx = idx
                }
                if recipe.bundleId == draggingHoveringRecipe.bundleId {
                    hoveringIdx = idx
                }
            }
            if let draggedIdx = draggedIdx, let hoveringIdx = hoveringIdx {
                var newRecipeList = recipeList
                newRecipeList.remove(at: draggedIdx)
                newRecipeList.insert(draggedRecipe, at: hoveringIdx)
                withAnimation {
                    self.recipeList = newRecipeList
                }
                Config.recipeOrders = newRecipeList.map { $0.bundleId }
                if !Config.save() {
                    Log.warning("save recipe order failed")
                }
                RecipeManager.refresh()
                self.draggedRecipe = nil
                self.draggingHoveringRecipe = nil
                return true
            }
        }
        self.draggedRecipe = nil
        self.draggingHoveringRecipe = nil
        return false
    }
    
    func dropEntered(info: DropInfo) {
        draggingHoveringRecipe = recipe
    }
    
    func dropExited(info: DropInfo) {
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
}

struct RecipeSelectionViewDropDelegate: DropDelegate {
    
    @Binding var draggedRecipe: Recipe?
    @Binding var draggingHoveringRecipe: Recipe?
    @Binding var recipeList: [Recipe]
    
    func performDrop(info: DropInfo) -> Bool {
        if let draggedRecipe = draggedRecipe, let draggingHoveringRecipe = draggingHoveringRecipe {
            var draggedIdx: Int? = nil
            var hoveringIdx: Int? = nil
            for (idx, recipe) in recipeList.enumerated() {
                if recipe.bundleId == draggedRecipe.bundleId {
                    draggedIdx = idx
                }
                if recipe.bundleId == draggingHoveringRecipe.bundleId {
                    hoveringIdx = idx
                }
            }
            if let draggedIdx = draggedIdx, let hoveringIdx = hoveringIdx {
                var newRecipeList = recipeList
                newRecipeList.remove(at: draggedIdx)
                newRecipeList.insert(draggedRecipe, at: hoveringIdx)
                withAnimation {
                    self.recipeList = newRecipeList
                }
                Config.recipeOrders = newRecipeList.map { $0.bundleId }
                if !Config.save() {
                    Log.warning("save recipe order failed")
                }
                RecipeManager.refresh()
                self.draggedRecipe = nil
                self.draggingHoveringRecipe = nil
                return true
            }
        }
        self.draggedRecipe = nil
        self.draggingHoveringRecipe = nil
        return false
    }
    
    func dropEntered(info: DropInfo) {
    }
    
    func dropExited(info: DropInfo) {
        draggingHoveringRecipe = nil
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
}

struct RecipeSelectionItemView: View {
    
    var recipe: Recipe
    
    @State var isSelected: Bool = false
    
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                recipe.icon
                .resizable()
                .scaledToFit()
                .foregroundColor(isSelected ? Constant.mainTextColor.color: Constant.mainTextColor.color)
            }
            .frame(width: Constant.recipeItemHeight)
            .padding(.leading, 2.5)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name)
                        .font(.title3)
                        .foregroundColor(isSelected ? Constant.mainTextColor.color: Constant.mainTextColor.color)
                    if let command = recipe.command {
                        Text(command)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? Constant.mainTextColor.color: Constant.mainTextColor.color)
                    }
                }
                if let desc = recipe.description, isSelected {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
        }
        .padding(5)
        .frame(height: isSelected ? Constant.recipeItemSelectedHeight : Constant.recipeItemHeight)
        .background(isSelected ? "F0F0F3".color : Color.clear)
        .cornerRadius(10)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
        .onTapGesture(count: 1) {
            Task {
                await context.switchRecipe(recipe.bundleId)
                await context.executeIfAutomatic()
            }
        }
    }
    
}
