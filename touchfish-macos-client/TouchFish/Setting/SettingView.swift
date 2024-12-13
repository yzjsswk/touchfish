import SwiftUI

enum SettingTab: CaseIterable {
    
    case basic
    case fishRespository
    
    var tabName: String {
        switch self {
        case .basic: 
            return "Basic"
        case .fishRespository:
            return "Fish Respository"
        }
    }
    
}

struct SettingView: View {
    
    @State var tempSetting = Configuration.read()
    @State var selectedTab: SettingTab = .basic
    
    var body: some View {
        VStack {
            HStack {
                SettingTabView(selectedTab: $selectedTab)
                    .frame(width: Constant.mainWidth*0.2)
                Divider()
                VStack {
                    ScrollView(showsIndicators: false) {
                        switch selectedTab {
                        case .basic:
                            BasicSettingView(tempSetting: $tempSetting)
                        case .fishRespository:
                            FishRepositorySettingView(tempSetting: $tempSetting)
                        }
                    }
                }
                .frame(width: Constant.mainWidth*0.75)
            }
            HStack {
                Spacer()
                Button(action: {
                    tempSetting = Configuration.read()
                }) {
                    Text("Undo Changes")
                        .font(.title3)
                        .padding(3)
                }
                Spacer()
                Button(action: {
                    tempSetting = Configuration()
                }) {
                    Text("Set To Default")
                        .font(.title3)
                        .padding(3)
                }
                Spacer()
                Button(action: {
                    let ok = tempSetting.save()
                    if ok {
                        Config = Configuration.read()
                        RecipeManager.goToRecipe(recipeId: nil)
                    } else {
                        Functions.doAlert(type: .warning, title: "Warning", message: "Save Failed")
                    }
                }) {
                    Text("Apply Changes")
                        .font(.title3)
                        .bold()
                        .padding(3)
                }
                Spacer()
            }
            .padding(5)
        }
    }
    
}

struct SettingTabView: View {
    
    struct SettingTabItemView: View {
        
        var title: String
        var isSelected: Bool
        
        @State var isHovered: Bool = false
        
        var body: some View {
            ZStack {
                isSelected ? Constant.selectedItemBackgroundColor.opacity(1.0) : (
                    isHovered ? Constant.selectedItemBackgroundColor.opacity(0.6) :
                        Constant.commandBarBackgroundColor.opacity(1.0)
                )
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(isSelected || isHovered ? .white : .black)
                    .padding()
            }
            .cornerRadius(8)
            .onHover { isHovered in
                self.isHovered = isHovered
            }
        }
        
    }
    
    @Binding var selectedTab: SettingTab
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            ForEach(SettingTab.allCases, id:\.self) { tab in
                SettingTabItemView(title: tab.tabName, isSelected: selectedTab == tab)
                    .onTapGesture {
                        selectedTab = tab
                    }
            }
        }
    }
    
}
