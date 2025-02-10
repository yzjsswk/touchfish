import SwiftUI

struct MainView: View {
    
    enum Tab {
        case Setting
        case FishRepository
        case RecipeManage
        case Statistics
        case QuickExecution
        case DynamicRecipe(String)
        
        var identity: String {
            switch self {
            case .Setting:
                return "setting"
            case .FishRepository:
                return "fish_repository"
            case .RecipeManage:
                return "recipe_manage"
            case .Statistics:
                return "statistics"
            case .QuickExecution:
                return "quick_execution"
            case .DynamicRecipe(let identity):
                return "dynamic_recipe_\(identity)"
            }
        }
        
    }
    
    struct TabBarView: View {
        
        struct TabButton: View {
            
            @State var isHovering: Bool = false
            
            @Binding var pressedTab: Tab
            @Binding var hoveringTab: Tab?
            @Binding var isFullScreen: Bool
            
            var tab: Tab
            var iconPattern: String
            
            var isPressed: Bool {
                pressedTab.identity == tab.identity
            }
            
            var isHovered: Bool {
                if isFullScreen {
                    return isHovering
                }
                if let hoveringTab = hoveringTab {
                    return hoveringTab.identity == tab.identity
                }
                return false
            }
            
            var body: some View {
                HStack {
                    Image(systemName: iconPattern)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .scaledToFit()
                    .foregroundStyle("27295F".color)
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
                        pressedTab = tab
                    }
                }
            }
            
        }
        
        @Binding var pressedTab: Tab
        @State var hoveringTab: Tab? = nil
        
        @Binding var isFullScreen: Bool
        
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
                            pressedTab: $pressedTab,
                            hoveringTab: $hoveringTab,
                            isFullScreen: $isFullScreen,
                            tab: .Setting,
                            iconPattern: "gearshape"
                        )
                        TabButton(
                            pressedTab: $pressedTab,
                            hoveringTab: $hoveringTab,
                            isFullScreen: $isFullScreen,
                            tab: .FishRepository,
                            iconPattern: "fish.circle"
                        )
                        TabButton(
                            pressedTab: $pressedTab,
                            hoveringTab: $hoveringTab,
                            isFullScreen: $isFullScreen,
                            tab: .RecipeManage,
                            iconPattern: "books.vertical"
                        )
                        TabButton(
                            pressedTab: $pressedTab,
                            hoveringTab: $hoveringTab,
                            isFullScreen: $isFullScreen,
                            tab: .Statistics,
                            iconPattern: "chart.line.uptrend.xyaxis.circle"
                        )
                        TabButton(
                            pressedTab: $pressedTab,
                            hoveringTab: $hoveringTab,
                            isFullScreen: $isFullScreen,
                            tab: .QuickExecution,
                            iconPattern: "play.square.fill"
                        )
                        Image(systemName: "plus")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .padding()
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
                    hoveringTab = posToTab(pos: shift)
//                    Log.debug("hover \(hoveringTab), shift=\(shift)")
                    
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .ClickInMainWindowTabBar)) { notification in
                if let shift = notification.userInfo?["shift"] as? CGFloat, !isFullScreen {
                    if let tab = posToTab(pos: shift) {
                        pressedTab = tab
                    }
//                    Log.debug("click \(pressedTab) shift=\(shift)")
                }
            }
        }
        
        private func posToTab(pos: CGFloat) -> Tab? {
            let bound: (Int) -> CGFloat = { n in
                if n <= 0 {
                    return Constant.mainWindowWindowButtonAreaWidth
                }
                return CGFloat(Constant.mainWindowWindowButtonAreaWidth) + CGFloat(CGFloat(0.5)*CGFloat(n-1)+CGFloat(40*n))
            }
            if pos <= bound(0) {
                return nil
            }
            if pos < bound(1) {
                return .Setting
            }
            if pos < bound(2) {
                return .FishRepository
            }
            if pos < bound(3) {
                return .RecipeManage
            }
            if pos < bound(4) {
                return .Statistics
            }
            if pos < bound(5) {
                return .QuickExecution
            }
            return nil
        }
        
    }
    
    @State var pressedTab: Tab = .Setting
    @State var isFullScreen: Bool = false
    
    @State var commandText = ""
    @State var commandCell: [String] = []
    @State var activeRecipeBundleId: String?
    
    var body: some View {
        
        ZStack {
            VStack {
                TabBarView(pressedTab: $pressedTab, isFullScreen: $isFullScreen)
                Spacer()
            }
            .offset(y: -33 + (isFullScreen ? 28 : 0))
            RoundedRectangle(cornerRadius: 10)
            .fill("FDFDFD".color)
            .offset(y: 9 + (isFullScreen ? 28 : 0))
            VStack {
                CommandBarView(commandText: $commandText, commandCell: $commandCell)
                switch pressedTab {
                case .Setting:
                    SettingView()
                case .FishRepository:
                    FishRepositoryView()
                case .RecipeManage:
                    RecipeManageView()
                case .Statistics:
                    StatsView()
                case .QuickExecution:
                    DynamicRecipeView()
                case .DynamicRecipe:
                    EmptyView()
                }
                Spacer()
            }
            .padding(.top, 18)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }
    
}

