import SwiftUI

struct TabBarView: View {
    
    @State var hoveringTab: Tab? = nil
    @State var popoverTab: Tab? = nil
    @Binding var pressedTab: Tab
    
    @Binding var isFullScreen: Bool
    
    @Binding var recipeExecutionContexts: [RecipeExecutionContext]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill("C6C7F4".color)
            VStack {
                HStack(spacing: 0.5) {
                    Rectangle()
                    .fill(Color.clear)
                    .frame(width: isFullScreen ? 5 : Constant.mainWindowWindowButtonAreaWidth)
                    TabButton(
                        tab: .Home,
                        icon: Image(systemName: "house"),
                        isFullScreen: $isFullScreen,
                        pressedTab: $pressedTab,
                        popoverTab: .constant(nil),
                        hoveringTab: $hoveringTab
                    )
                    TabButton(
                        tab: .Setting,
                        icon: Image(systemName: "gearshape"),
                        isFullScreen: $isFullScreen,
                        pressedTab: $pressedTab,
                        popoverTab: .constant(nil),
                        hoveringTab: $hoveringTab
                    )
                    TabButton(
                        tab: .FishRepository,
                        icon: Image(systemName: "fish"),
                        isFullScreen: $isFullScreen,
                        pressedTab: $pressedTab,
                        popoverTab: .constant(nil),
                        hoveringTab: $hoveringTab
                    )
                    TabButton(
                        tab: .RecipeManage,
                        icon: Image(systemName: "books.vertical"),
                        isFullScreen: $isFullScreen,
                        pressedTab: $pressedTab,
                        popoverTab: .constant(nil),
                        hoveringTab: $hoveringTab
                    )
                    TabButton(
                        tab: .Statistics,
                        icon: Image(systemName: "chart.line.uptrend.xyaxis.circle"),
                        isFullScreen: $isFullScreen,
                        pressedTab: $pressedTab,
                        popoverTab: .constant(nil),
                        hoveringTab: $hoveringTab
                    )
                    ForEach(Array(recipeExecutionContexts.enumerated()), id: \.0) { idx, context in
                        TabButton(
                            tab: .RecipeExecution(idx),
                            icon: Image(systemName: "play.square.fill"),
                            isFullScreen: $isFullScreen,
                            pressedTab: $pressedTab,
                            popoverTab: $popoverTab,
                            hoveringTab: $hoveringTab,
                            recipeExecutionContext: context
                        )
                        .id("recipe_execution_tab_\(context.uid)")
                    }
                    AddTabButton(
                        tab: .AddRecipeExecution,
                        isFullScreen: $isFullScreen,
                        pressedTab: $pressedTab,
                        hoveringTab: $hoveringTab,
                        recipeExecutionContexts: $recipeExecutionContexts
                    )
                    Spacer()
                }
                Spacer()
            }
            .frame(height: Constant.mainWindowTabBarHeight)
        }
        .frame(height: Constant.mainWindowTabBarHeight+10)
        .onHover { isHovering in
            if !isHovering {
                hoveringTab = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .HoverInMainWindowTabBar)) { notification in
            if let shift = notification.userInfo?["shift"] as? CGFloat, !isFullScreen {
                hoveringTab = posToTab(pos: shift, recipeExecutionCount: recipeExecutionContexts.count)
//                    Log.debug("hover \(hoveringTab), shift=\(shift)")
                
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .LeftClickInMainWindowTabBar)) { notification in
            if let shift = notification.userInfo?["shift"] as? CGFloat, !isFullScreen {
                if let tab = posToTab(pos: shift, recipeExecutionCount: recipeExecutionContexts.count) {
                    if tab == .AddRecipeExecution {
                        recipeExecutionContexts.append(RecipeExecutionContext())
                        pressedTab = .RecipeExecution(recipeExecutionContexts.count-1)
                    } else {
                        pressedTab = tab
                    }
                }
//                Log.debug("click in tab bar, shift=\(shift), pressedTab=\(pressedTab)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RightClickInMainWindowTabBar)) { notification in
            if let shift = notification.userInfo?["shift"] as? CGFloat, !isFullScreen {
                if let tab = posToTab(pos: shift, recipeExecutionCount: recipeExecutionContexts.count) {
                    if case .RecipeExecution(_) = tab {
                        popoverTab = tab
                    }
                }
//                Log.debug("click in tab bar, shift=\(shift), pressedTab=\(pressedTab)")
            }
        }
    }
    
    private func posToTab(pos: CGFloat, recipeExecutionCount: Int) -> Tab? {
        let bound: (Int) -> CGFloat = { n in
            if n <= 0 {
                return Constant.mainWindowWindowButtonAreaWidth
            }
            return CGFloat(Constant.mainWindowWindowButtonAreaWidth) + CGFloat(CGFloat(0.5)*CGFloat(n-1)+CGFloat(40*n))
        }
        if pos <= bound(0) {
            return nil
        }
        if pos <= bound(1) {
            return .Home
        }
        if pos < bound(2) {
            return .Setting
        }
        if pos < bound(3) {
            return .FishRepository
        }
        if pos < bound(4) {
            return .RecipeManage
        }
        if pos < bound(5) {
            return .Statistics
        }
        for i in 0..<recipeExecutionCount {
            if pos < bound(6+i) {
                return .RecipeExecution(i)
            }
        }
        if pos < bound(6+recipeExecutionCount) {
            return .AddRecipeExecution
        }
        return nil
    }
    
    struct AddTabButton: View {
        
        var tab: Tab
        
        @Binding var isFullScreen: Bool
        @Binding var pressedTab: Tab
        @Binding var hoveringTab: Tab?
        @State var isHovering: Bool = false
        
        @Binding var recipeExecutionContexts: [RecipeExecutionContext]
        
        var isPressed: Bool {
            pressedTab == tab
        }
        
        var isHovered: Bool {
            if isFullScreen {
                return isHovering
            }
            if let hoveringTab = hoveringTab {
                return hoveringTab == tab
            }
            return false
        }
        
        var body: some View {
            HStack {
                Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 15, maxHeight: 15)
                .foregroundStyle(.black.opacity(0.6))
            }
            .frame(width: 40, height: 40)
            .background(
                Rectangle()
                    .fill(isPressed ? "FDFDFD".color : "FDFDFD".color.opacity(isHovered ? 0.6 : 0.25))
            )
            .onHover { isHovering in
                if isFullScreen {
                    self.isHovering = isHovering
                }
            }
            .onTapGesture {
                if isFullScreen {
                    recipeExecutionContexts.append(RecipeExecutionContext())
                    pressedTab = .RecipeExecution(recipeExecutionContexts.count-1)
                }
            }
        }
    }

    
    struct TabButton: View {
        
        var tab: Tab
        @State var icon: Image
        
        @Binding var isFullScreen: Bool
        @Binding var pressedTab: Tab
        @Binding var popoverTab: Tab?
        @State var showPopover: Bool = false
        @Binding var hoveringTab: Tab?
        @State var isHovering: Bool = false
        
        var recipeExecutionContext: RecipeExecutionContext? = nil
        @State var recipeExecutionContextUid: UUID? = nil
        
        var isPressed: Bool {
            pressedTab == tab
        }
        
        var isHovered: Bool {
            if isFullScreen {
                return isHovering
            }
            if let hoveringTab = hoveringTab {
                return hoveringTab == tab
            }
            return false
        }
        
        var body: some View {
            HStack {
                icon
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 20, maxHeight: 20)
                .foregroundStyle("27295F".color)
            }
            .frame(width: 40, height: 40)
            .background(
                Rectangle()
                .fill(isPressed ? "FDFDFD".color : "FDFDFD".color.opacity(isHovered ? 0.6 : 0.25))
            )
            .onAppear {
                if let context = recipeExecutionContext {
                    Task {
                        recipeExecutionContextUid = await context.uid
                        if let recipe = await context.activeRecipe {
                            self.icon = recipe.icon
                        } else {
                            self.icon = Image(systemName: "play.square.fill")
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(recipeExecutionContextUid?.uuidString ?? ""))) { notification in
                if let context = recipeExecutionContext {
                    Task {
                        if let recipe = await context.activeRecipe {
                            self.icon = recipe.icon
                        } else {
                            self.icon = Image(systemName: "play.square.fill")
                        }
                    }
                }
            }
            .onHover { isHovering in
                if isFullScreen {
                    self.isHovering = isHovering
                }
            }
            .onTapGesture {
                if isFullScreen {
                    pressedTab = tab
                }
            }
            .onChange(of: popoverTab) {
                if let popoverTab = popoverTab, popoverTab == tab {
                    showPopover = true
                    self.popoverTab = nil
                }
            }
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                VStack(spacing: 0) {
                    PopoverButtonView(desc: "Bind")
                    PopoverButtonView(desc: "Close")
                    .onTapGesture {
                        if let contextUid = self.recipeExecutionContextUid {
                            NotificationCenter.default.post(name: .ShouldRemoveRecipeExecutionContext, object: nil, userInfo: ["uid":contextUid])
                        }
                    }
                }
                .padding(5)
            }
        }
        
    }
    
    struct PopoverButtonView: View {
        
        var desc: String
        
        @State var isHovering: Bool = false
        
        var body: some View {
            Text(desc)
            .font(.body)
            .frame(width: 60, height: 20)
            .padding(3)
            .background(Color.gray.opacity(isHovering ? 0.4 : 0))
            .cornerRadius(5)
            .onHover { isHovering in
                self.isHovering = isHovering
            }
        }
        
    }
    
    enum Tab: Equatable {
        case Home
        case Setting
        case FishRepository
        case RecipeManage
        case Statistics
        case RecipeExecution(Int)
        case AddRecipeExecution
        
        static func ==(a: Tab, b: Tab) -> Bool {
            switch (a, b) {
            case (.Home, .Home):
                return true
            case (.Setting, .Setting):
                return true
            case (.FishRepository, .FishRepository):
                return true
            case (.RecipeManage, .RecipeManage):
                return true
            case (.Statistics, .Statistics):
                return true
            case (.RecipeExecution(let idx1), .RecipeExecution(let idx2)):
                return idx1 == idx2
            case (.AddRecipeExecution, .AddRecipeExecution):
                return true
            default:
                return false
            }
        }
        
    }
    
}
