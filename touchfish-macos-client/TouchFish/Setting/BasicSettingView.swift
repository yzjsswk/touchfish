import SwiftUI

struct BasicSettingView: View {
    
    @Binding var tempSetting: Configuration
    
    var body: some View {
        VStack {
            // language
            HStack {
                Text("Language")
                    .font(.title3)
                    .bold()
                Spacer()
                Picker("", selection: $tempSetting.language) {
                    ForEach(Configuration.TFLanguage.allCases) { lan in
                        Text(lan.rawValue)
                            .tag(lan)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }
            .padding(.vertical, 2)
            HStack{
                Text("the language of the application")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
            // call application of keyboard shortCut
            HStack {
                Text("Call Application KeyBoard ShortCut")
                    .font(.title3)
                    .bold()
                Spacer()
                ZStack {
                    Constant.commandBarBackgroundColor
                    HStack(spacing: 2) {
                        Image(systemName: "option")
                        Image(systemName: "space")
                    }
                }
                .frame(width: 50)
                .padding(.horizontal, 5)
            }
            .padding(.vertical, 2)
            HStack{
                Text("when pressed, the application activates and shows")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
            // Data Server
            HStack {
                Text("Data Server")
                    .font(.title3)
                    .bold()
                Spacer()
                DataServiceConfigAddView(dataServiceConfigs: $tempSetting.dataServiceConfigs)
            }
            .padding(.vertical, 2)
            HStack{
                Text("data server is used to store data like fish and topics")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            DataServiceConfigListView(tempSetting: $tempSetting)
            .padding(.vertical, 5)
            Divider()
            // Recipe Server
            HStack {
                Text("Reicpe Server")
                    .font(.title3)
                    .bold()
                Spacer()
                RecipeServiceConfigAddView(recipeServiceConfigs: $tempSetting.recipeServiceConfigs)
            }
            .padding(.vertical, 2)
            HStack{
                Text("recipe server is used to detect and execute user-defined recipes")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            RecipeServiceConfigListView(tempSetting: $tempSetting)
            .padding(.vertical, 2)
            Divider()
            // hideMainWindowWhenClickOutSideEnable
            HStack {
                Text("Hide When Click Outside")
                    .font(.title3)
                    .bold()
                Spacer()
                Toggle(isOn: $tempSetting.hideMainQuickExecutionWindowWhenClickOutSideEnable) {}
                    .padding(.horizontal, 5)
            }
            .padding(.vertical, 2)
            HStack{
                Text("if enabled, when click outside the window, the application will hide and deactivate")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
            // backWhenAssistiveClick
//            HStack {
//                Text("Back When Assistive Click")
//                    .font(.title3)
//                    .bold()
//                Spacer()
//                Toggle(isOn: $tempSetting.backWhenAssistiveClick) {}
//                    .padding(.horizontal, 5)
//            }
//            .padding(.vertical, 2)
//            HStack{
//                Text("if enabled, when do an assistive click, the last cell in command bar will be removed")
//                    .font(.callout)
//                    .foregroundStyle(.gray)
//                Spacer()
//            }
//            .padding(.vertical, 2)
//            Divider()
        }
        .padding()
    }
    
}
