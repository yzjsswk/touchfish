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
    
    struct SettingButtonView: View {

        var label: String
        
        @State var isHovered: Bool = false
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? "B8B9F4".color : "D6D6F9".color, lineWidth: 2)
                    .fill(isHovered ? "F8F8FE".color : .white)
                Text(label)
                    .font(.body)
                    .foregroundStyle(isHovered ? "27295F".color : "4C4C4C".color)
                    .padding(3)
            }
            .onHover { isHovered in
                self.isHovered = isHovered
            }
        }
        
    }
    
    @State var tempSetting = Configuration.read()
    @State var selectedTab: SettingTab = .basic
    
    var body: some View {
        VStack {
            HStack {
//                SettingTabView(selectedTab: $selectedTab)
//                .frame(width: 160)
//                Divider()
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
            }
            HStack {
                Spacer()
                SettingButtonView(label: "Undo Changes")
                .frame(width: 100, height: 40)
                .onTapGesture {
                    tempSetting = Configuration.read()
                }
                Spacer()
                SettingButtonView(label: "Set To Default")
                .frame(width: 100, height: 40)
                .onTapGesture {
                    tempSetting = Configuration()
                }
                Spacer()
                SettingButtonView(label: "Apply Changes")
                .frame(width: 100, height: 40)
                .onTapGesture {
                    let ok = tempSetting.save()
                    if ok {
                        Config = Configuration.read()
                        Functions.doAlert(type: .informational, title: "Save Successd!", message: "")
                    } else {
                        Functions.doAlert(type: .warning, title: "Save Failed", message: "")
                    }
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
