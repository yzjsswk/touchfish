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
            // hideMainWindowWhenClickOutSideEnable
            HStack {
                Text("Reicpe Directory")
                    .font(.title3)
                    .bold()
                Spacer()
                RecipeDirectoryAddView(tempSetting: $tempSetting)
            }
            .padding(.vertical, 2)
            HStack{
                Text("the directorys below will be used to detect user-defined recipes")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
            RecipeDirectoryListView(tempSetting: $tempSetting)
            .padding(.vertical, 2)
            Divider()
            // hideMainWindowWhenClickOutSideEnable
            HStack {
                Text("Hide When Click Outside")
                    .font(.title3)
                    .bold()
                Spacer()
                Toggle(isOn: $tempSetting.hideMainWindowWhenClickOutSideEnable) {}
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
        }
        .padding()
    }
    
}

struct RecipeDirectoryAddView: View {
    
    @Binding var tempSetting: Configuration
    
    @State var isHovered = false
    
    var body: some View {
        Image(systemName: "plus.circle")
        .resizable()
        .frame(width: 20, height: 20)
        .foregroundStyle(isHovered ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .onTapGesture {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            Monitor.stop(type:.hideMainWindowWhenClickOutside)
            let res = panel.runModal()
            Monitor.start(type:.hideMainWindowWhenClickOutside)
            if res == .OK, let selectedURL = panel.urls.first {
                if !tempSetting.recipeDirectorys.contains(selectedURL) {
                    tempSetting.recipeDirectorys.append(selectedURL)
                }
            }
        }
    }
    
}

struct RecipeDirectoryListView: View {
    
    @Binding var tempSetting: Configuration
    
    struct RecipeDirectoryRemoveButtonView: View {
        
        @Binding var tempSetting: Configuration
        @State var isHovered: Bool = false
        var dir: URL
        
        var body: some View {
            Image(systemName: "minus.circle")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(isHovered ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .onTapGesture {
                tempSetting.recipeDirectorys.removeAll(where: { $0 == dir })
            }
        }
        
    }
    
    var body: some View {
        if tempSetting.recipeDirectorys.count > 0 {
            VStack(spacing: 10) {
                ForEach(tempSetting.recipeDirectorys, id: \.self) { dir in
                    HStack {
                        Text("\(dir.path) (\(countRecipe(directory: dir)) recipes)")
                            .font(.custom("Menlo", size: 13))
                        Spacer()
                        RecipeDirectoryRemoveButtonView(tempSetting: $tempSetting, dir: dir)
                    }
                    
                }
            }
        } else {
            Text("-- Empty --")
                .font(.custom("Menlo", size: 13))
                .foregroundStyle(.gray)
        }
    }
    
    private func countRecipe(directory: URL) -> Int {
        var cnt = 0
        for fileURL in Functions.getAllFiles(in: directory) {
            if fileURL.lastPathComponent == "recipe.json" {
                cnt += 1
            }
        }
        return cnt
    }
    
}
