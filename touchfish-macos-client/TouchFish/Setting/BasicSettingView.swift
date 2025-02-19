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
                Text("data server is used to store data like fish and topics, there must be one and only one")
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
                Text("recipe server is used to detect and execute recipes")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            RecipeServiceConfigListView(tempSetting: $tempSetting)
            .padding(.vertical, 2)
            Divider()

            // call application of keyboard shortCut
            HStack {
                Text("KeyBoard ShortCut: Call Quick Execution Window")
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
                Text("when pressed, the quick execution window shows/hides")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
            // call fish Repository keyboard shortcut
            HStack {
                Text("KeyBoard ShortCut: Call Pasteboard Window ")
                    .font(.title3)
                    .bold()
                Spacer()
                ZStack {
                    Constant.commandBarBackgroundColor
                    HStack(spacing: 2) {
                        Image(systemName: "command")
                        Image(systemName: "option")
                        Image(systemName: "v.square")
                    }
                }
                .frame(width: 60)
                .padding(.horizontal, 5)
            }
            .padding(.vertical, 2)
            HStack{
                Text("when pressed, the pasteboard window shows")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
            // auto imported from clipboard
            HStack {
                Text("Auto Imported Fish From Clipboard")
                    .font(.title3)
                    .bold()
                Spacer()
                Toggle(isOn: $tempSetting.autoImportedFromClipboard) {}
                    .padding(.horizontal, 5)
            }
            .padding(.vertical, 2)
            HStack{
                Text("if enabled, when something (support text/image currently) copyed to the system clipboard, it will also be imported as fish automatically")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
            // fast paste to frontmost application
            HStack {
                Text("Fast Paste To Frontmost Application")
                    .font(.title3)
                    .bold()
                Spacer()
                Toggle(isOn: $tempSetting.fastPasteToFrontmostApplication) {}
                    .padding(.horizontal, 5)
            }
            .padding(.vertical, 2)
            HStack{
                Text("if enabled, when click a fish (support text/image currently) in the pasteboard window, the application will hide and the fish will be tried to paste to the frontmost application; otherwise, the fish will only be copied to the system clipboard and you need to paste it manually")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
            // hideQuickExecutionWindowWhenClickOutSideEnable
            HStack {
                Text("Hide Quick Execution Window When Click Outside")
                    .font(.title3)
                    .bold()
                Spacer()
                Toggle(isOn: $tempSetting.hideQuickExecutionWindowWhenClickOutSideEnable) {}
                    .padding(.horizontal, 5)
            }
            .padding(.vertical, 2)
            HStack{
                Text("if enabled, the quick execution window will hide when you click outside it")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.vertical, 2)
            Divider()
        }
        .padding()
    }
    
}
