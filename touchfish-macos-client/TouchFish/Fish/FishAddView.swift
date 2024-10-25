import SwiftUI

struct FishAddView: View {
    
    @State var toAddFiles: [URL:AddInfo] = [:]
    @State var selectedFile: URL = URL(filePath: "")
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                Picker("", selection: $selectedFile) {
                    let urls = Array(toAddFiles.keys).sorted {$0.path < $1.path}
                    ForEach(urls, id: \.self) { url in
                        Text(url.lastPathComponent)
                    }
                }
                .pickerStyle(.segmented)
            }
            if let addInfo = toAddFiles[selectedFile] {
                ScrollView(showsIndicators: false) {
                    AddInfoView(selectedFile: selectedFile, addInfo: addInfo)
                }
                .padding()
                HStack {
                    Spacer()
                    AddButtonView(addFileCount: toAddFiles.count) {
                        for (url, info) in toAddFiles {
                            if let data = FileManager.default.contents(atPath: url.path) {
                                if let type = Fish.FishType(rawValue: info.selectedType) {
                                    Task {
                                        let newFish = await Storage.addFish(
                                            type,
                                            data,
                                            description: info.description,
                                            tags: info.tags,
                                            isMarked: true,
                                            extraInfo: Fish.ExtraInfo(sourceAppName: "TouchFish")
                                        )
                                        if newFish == nil {
                                            MessageCenter.send(level: .error, title: "Add Fish From File", content: "file \(url.path) add failed, check if there had been one same fish", source: "com.touchfish.AddFish")
                                            Log.error("click button to add fish - one fish add failed: storage.addFish returns nil, url=\(url.path)")
                                        }
                                    }
                                } else {
                                    MessageCenter.send(level: .error, title: "Add Fish From File", content: "file \(url.path) add failed, type \(info.selectedType) invalid", source: "com.touchfish.AddFish")
                                    Log.error("click button to add fish - skip a fish: parse type=nil, url=\(url.path), type=\(info.selectedType)")
                                }
                            } else {
                                MessageCenter.send(level: .error, title: "Add Fish From File", content: "file \(url.path) add failed, read file data failed", source: "com.touchfish.AddFish")
                                Log.error("click button to add fish - skip a fish: got file data=nil, url=\(url.path)")
                            }
                        }
                        RecipeManager.goToRecipe(recipeId: nil)
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            Monitor.stop(type:.hideMainWindowWhenClickOutside)
            let res = panel.runModal()
            Monitor.start(type:.hideMainWindowWhenClickOutside)
            if res == .OK && panel.urls.count > 0 {
                let urls = panel.urls.sorted {$0.path < $1.path}
                for url in urls {
                    if let fileSize = Functions.getFileSize(atPath: url.path) {
                        if fileSize > Constant.maxDataSizeAddFish {
                            Log.warning("select file to add fish - skip a file: size out of limited, url=\(url.path), size=\(fileSize), limited=\(Constant.maxDataSizeAddFish)")
                            continue
                        }
                        let addInfo = AddInfo(fileSize: Int(fileSize))
                        let ext = url.pathExtension.lowercased()
                        switch ext {
                        case "txt", "json", "cpp", "go", "py":
                            addInfo.selectedType = "Text"
                        case "png", "jpg", "jpeg":
                            addInfo.selectedType = "Image"
                        default:
                            addInfo.selectedType = "Other"
                        }
                        addInfo.description = url.lastPathComponent
                        toAddFiles[url] = addInfo
                    } else {
                        Log.error("select file to add fish - skip a file: got size of the file failed, url=\(url.path)")
                        continue
                    }
                }
                selectedFile = urls[0]
            } else {
                RecipeManager.goToRecipe(recipeId: nil)
            }
        }

    }
    
}

struct AddButtonView: View {
        
    var addFileCount: Int
    @State private var isHovered = false
    
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Add \(addFileCount) File\(addFileCount == 1 ? "":"s")")
                .font(.title3)
                .bold()
                .foregroundColor(isHovered ? .black : .gray)
        }
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
}


struct AddInfoView: View {
    
    var selectedFile: URL
    @ObservedObject var addInfo: AddInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack(spacing: 10) {
                Text("Data")
                    .font(.title2)
                    .bold()
                Text("\(selectedFile.path) (\(Functions.descByteCount(addInfo.fileSize)))")
                    .font(.title3)
            }
            
            HStack(spacing: 10) {
                Text("Type")
                    .font(.title2)
                    .bold()
                Picker("", selection: $addInfo.selectedType) {
                    ForEach(Fish.FishType.allCases, id: \.rawValue) { type in
                        Text(type.rawValue)
                    }
                }
                .frame(width: Constant.mainWidth*0.1)
                .pickerStyle(.menu)
            }
            
//            HStack(spacing: 12) {
//                Text("Tag")
//                    .font(.title2)
//                    .bold()
//                ForEach(addInfo.tags, id: \.self) { tg in
//                    TagView(label: tg, tags: $tags)
//                }
//                .offset(y: 1)
//                TagEditView(tags: $addInfo.tags)
//                .offset(y: 1)
//            }
            
            Text("Description")
                .font(.title2)
                .bold()
                ZStack {
                    VStack {
                        Spacer()
                        TextEditor(text: $addInfo.description)
                            .font(.custom("Menlo", size: 16))
                        Spacer()
                    }
                }
                .background(Color.white)
                .cornerRadius(5)
                .frame(height: Constant.mainWidth*0.3)
        }
    }
    
}

class AddInfo: ObservableObject {
    @Published var description: String = ""
    @Published var tags: [String] = []
    @Published var selectedType = "Other"
    var fileSize: Int
    
    init(fileSize: Int) {
        self.fileSize = fileSize
    }
    
}
