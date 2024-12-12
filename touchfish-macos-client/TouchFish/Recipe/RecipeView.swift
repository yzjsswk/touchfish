import SwiftUI

struct RecipeView: View {
    
    @Binding var recipeList: [Recipe]
    
    var activeRecipeBundleId: String?
    
    @State var userDefinedRecipeView: UserDefinedRecipeView?
    
    var body: some View {
        VStack {
            if let activeRecipeBundleId = activeRecipeBundleId,
               let activeRecipe = RecipeManager.activeRecipe {
                switch activeRecipe.type {
                case .Task, .Commit:
                    RecipeListView(recipeList: $recipeList)
                case .View:
                    if let userDefinedRecipeView = userDefinedRecipeView {
                       switch userDefinedRecipeView.type {
                       case .empty:
                           EmptyView()
                       case .error:
                           ScrollView(showsIndicators: false) {
                               if let err = userDefinedRecipeView.errorMessage {
                                   Text(err)
                                       .font(.title3)
                                       .foregroundColor(.red)
                               } else {
                                   Text("Unknown Error")
                                       .font(.title3)
                                       .foregroundColor(.red)
                               }
                           }
                       case.text:
                           VStack {
                               ForEach(userDefinedRecipeView.items, id: \.title) { item in
                                   Text(item.title)
                               }
                           }
                       case .list1:
                           ScrollView(showsIndicators: false) {
                               VStack(spacing: 5) {
                                   ForEach(userDefinedRecipeView.items, id: \.title) { item in
                                       UserDefinedRecipeListItemView1(item: item, defaultItemIcon: userDefinedRecipeView.defaultItemIcon)
                                   }
                               }
                           }.padding(.vertical)
                       case .list2:
                           ScrollView(showsIndicators: false) {
                               VStack(spacing: 5) {
                                   ForEach(userDefinedRecipeView.items, id: \.title) { item in
                                       UserDefinedRecipeListItemView2(item: item, defaultItemIcon: userDefinedRecipeView.defaultItemIcon)
                                   }
                               }
                           }.padding(.vertical)
                       }
                   } else {
                       EmptyView()
                   }
                    Spacer()
                    HStack {
                        Text("total: \((userDefinedRecipeView?.items.count) ?? 0)")
                            .font(.system(.footnote, design: .monospaced))
                        Spacer()
                        HStack(spacing: 0) {
                            let timeCost = userDefinedRecipeView?.timeCost ?? 0
                            Text("timeCost: ")
                                .font(.system(.footnote, design: .monospaced))
                            Text("\(timeCost)")
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(timeCost < 200 ? .green : (timeCost < 500 ? .yellow : .red))
                            Text(" ms")
                                .font(.system(.footnote, design: .monospaced))
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                RecipeListView(recipeList: $recipeList)
            }
        }
//        .onAppear {
//            RecipeManager.activeRecipe?.execute()
//        }
        // todo: carefully controll event, avoid repeat execute
        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
            if let recipe = RecipeManager.activeRecipe, recipe.type != .Commit {
                recipe.execute()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeCommited)) { _ in
            if let recipe = RecipeManager.activeRecipe, recipe.type == .Commit {
                recipe.execute()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandBarEndEditing)) { notification in
            if let recipe = RecipeManager.activeRecipe, recipe.type == .View {
                recipe.execute()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .UserDefinedRecipeViewChanged)) { notification in
            if let view = notification.userInfo?["view"] as? UserDefinedRecipeView {
                withAnimation(.spring) {
                    self.userDefinedRecipeView = view
                }
            }
        }
    }
    
}

struct UserDefinedRecipeListItemView1: View {
    
    var item: UserDefinedRecipeView.UserDefinedRecipeViewItem
    var defaultItemIcon: String?
    
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                (item.icon?.icon ?? (defaultItemIcon?.icon ?? Image(systemName: "doc.plaintext")))
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: Constant.userDefinedRecipeItemHeight*0.5)
            .padding(.leading, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? Color.white: Color.black)
                if let desc = item.description {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .frame(width: Constant.mainWidth-30, height: Constant.userDefinedRecipeItemHeight)
        .background(isSelected ? Constant.selectedItemBackgroundColor : Constant.mainBackgroundColor)
        .cornerRadius(5)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
        .onTapGesture {
            if let actions = item.actions {
                for action in actions {
                    action.execute(host: nil, port: nil)
                }
            }
        }
    }
    
}

struct UserDefinedRecipeListItemView2: View {
    
    var item: UserDefinedRecipeView.UserDefinedRecipeViewItem
    var defaultItemIcon: String?
    
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                (item.icon?.icon ?? (defaultItemIcon?.icon ?? Image(systemName: "doc.plaintext")))
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: Constant.userDefinedRecipeItemHeight*(isSelected ? 0.5 : 0.4))
            .padding(.leading, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                .font(.title3)
//                    .fontWeight(.bold)
                .foregroundColor(isSelected ? Color.white: Color.black)
                if let desc = item.description, isSelected {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .frame(width: Constant.mainWidth-30, height: isSelected ? Constant.userDefinedRecipeItemHeight : Constant.userDefinedRecipeItemHeight-15)
        .background(isSelected ? Constant.selectedItemBackgroundColor : Constant.mainBackgroundColor)
        .cornerRadius(5)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
        .onTapGesture {
            if let actions = item.actions {
                for action in actions {
                    action.execute(host: nil, port: nil)
                }
            }
        }
    }
    
}
