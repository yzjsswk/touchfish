import SwiftUI

struct FishAddView: View {
    
    @State var toAddFiles: [URL:AddInfo] = [:]
    @State var selectedFile: URL = URL(filePath: "")
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                Picker("", selection: $selectedFile) {
                    let urls = Array(toAddFiles.keys).sorted { $0.path < $1.path }
                    ForEach(urls, id: \.self) { url in
                        Text(url.lastPathComponent + "\((toAddFiles[url]?.exists ?? false) ? " (Exists)" : "")")
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 5)
            if let addInfo = toAddFiles[selectedFile] {
                ScrollView(showsIndicators: false) {
                    AddInfoView(selectedFile: selectedFile, addInfo: addInfo)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                HStack {
                    Spacer()
                    ButtonView(label: "Add \(toAddFiles.count) File\(toAddFiles.count == 1 ? "":"s")")
                    .frame(width: 150, height: 40)
                    .onTapGesture {
                        Task {
                            let subject = "add_fish_\(Date().timeIntervalSince1970)"
                            let _ = await Storage.createTopic(topicType: .Info, subject: subject, source: "com.touchfish.AddFish", title: "Add Fish From File")
                            for (url, info) in toAddFiles {
                                if let data = FileManager.default.contents(atPath: url.path) {
                                    if let type = Fish.FishType(rawValue: info.selectedType) {
                                        let uid = await Storage.addFish(
                                            type, data, description: info.description,
                                            tags: info.tags.filter({ $0.value }).map({$0.key}),
                                            isMarked: true, extraInfo: Fish.ExtraInfo(sourceAppName: "TouchFish")
                                        )
                                        if uid != nil {
                                            await Storage.sendMessage(topicSubject: subject, level: .Info, title: "Add Success", body: "successfully add one fish from file \(url.path)")
                                        } else {
                                            await Storage.sendMessage(topicSubject: subject, level: .Error, title: "Add Failed", body: "failed to add one fish from file \(url.path), check if there had been one same fish")
                                            Log.error("click button to add fish - one fish add failed: storage.addFish returns nil, url=\(url.path)")
                                        }
                                    } else {
                                        await Storage.sendMessage(topicSubject: subject, level: .Error, title: "Add Failed", body: "failed to add one fish from file \(url.path): type \(info.selectedType) invalid")
                                        Log.error("click button to add fish - skip a fish: parse type=nil, url=\(url.path), type=\(info.selectedType)")
                                    }
                                } else {
                                    await Storage.sendMessage(topicSubject: subject, level: .Error, title: "Add Failed", body: "failed to add one fish from file \(url.path): read data from file failed")
                                    Log.error("click button to add fish - skip a fish: got file data=nil, url=\(url.path)")
                                }
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
                    if let fileSize = Functions.getFileSize(atPath: url.path), let data = FileManager.default.contents(atPath: url.path) {
                        if fileSize > Constant.maxDataSizeAddFish {
                            Log.warning("select file to add fish - skip a file: size out of limited, url=\(url.path), size=\(fileSize), limited=\(Constant.maxDataSizeAddFish)")
                            continue
                        }
                        let addInfo = AddInfo(fileSize: Int(fileSize))
                        let ext = url.pathExtension.lowercased()
                        if ["png", "jpg", "jpeg", "tiff"].contains(ext) {
                            addInfo.selectedType = "Image"
                        } else if let _ = String(data: data, encoding: .utf8) {
                            addInfo.selectedType = "Text"
                        } else {
                            addInfo.selectedType = "Other"
                        }
                        addInfo.description = url.lastPathComponent
                        toAddFiles[url] = addInfo
                        Task {
                            let identity = Functions.getMD5(of: data)
                            if let _ = await Storage.pickFishByIdentity(identity: identity) {
                                toAddFiles[url] = addInfo.withExists()
                            }
                        }
                    } else {
                        Log.error("select file to add fish - skip a file: read file data failed, url=\(url.path)")
                        continue
                    }
                }
                selectedFile = urls[0]
                Task {
                    if let stats = await Storage.countFish() {
                        for tg in stats.tagCount.keys {
                            for addInfo in toAddFiles.values {
                                if !tg.isEmpty && !addInfo.tags.keys.contains(tg) {
                                    addInfo.tags[tg] = false
                                }
                            }
                        }
                    }
                }
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
            HStack(spacing: 20) {
                Text("Data")
                    .font(.title2)
                Text("\(selectedFile.path) (\(Functions.descByteCount(addInfo.fileSize)))")
                    .font(.title3)
//                if addInfo.exists {
//                    Text("(Data Exists)")
//                    .font(.title3)
//                    .foregroundStyle(.red)
//                }
            }
            HStack(spacing: 8) {
                Text("Type")
                    .font(.title2)
                Picker("", selection: $addInfo.selectedType) {
                    ForEach(Fish.FishType.allCases, id: \.rawValue) { type in
                        Text(type.rawValue)
                    }
                }
                .frame(width: Constant.mainWidth*0.1)
                .pickerStyle(.menu)
                .offset(y: 1)
            }
            VStack(alignment: .leading) {
                HStack(spacing: 12) {
                    Text("Tag")
                        .font(.title2)
                    TagAddView(tags: $addInfo.tags)
                        .offset(y: 1)
                }
                .padding(.vertical, 5)
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill("EEF2FD".color)
                        .frame(height: 40)
                    HStack(spacing: 12) {
                        ForEach(Array(addInfo.tags.keys.sorted()), id: \.self) { tg in
                            TagView(label: tg, tags: $addInfo.tags)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            Text("Description")
                .font(.title2)
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke("A1A9C6".color, lineWidth: 3)
                VStack {
                    Spacer()
                    TextEditor(text: $addInfo.description)
                        .font(.custom("Menlo", size: 16))
                    Spacer()
                }.padding(.horizontal, 5)
            }
            .background(Color.white)
            .cornerRadius(5)
            .frame(height: Constant.mainWidth*0.3)
        }
    }
    
}

class AddInfo: ObservableObject {
    @Published var description = ""
    @Published var tags: [String:Bool] = [:]
    @Published var selectedType = "Other"
    @Published var exists = false
    var fileSize: Int
    
    init(fileSize: Int) {
        self.fileSize = fileSize
    }
    
    func withExists() -> AddInfo {
        var ret = AddInfo(fileSize: self.fileSize)
        ret.description = self.description
        ret.tags = self.tags
        ret.selectedType = self.selectedType
        ret.exists = true
        return ret
    }
    
}
