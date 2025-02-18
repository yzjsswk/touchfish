import SwiftUI

struct PasteBoardView: View {
    
    @State var fishList: [Fish] = []
    
    @State var hoveredFish: Fish? = nil
    
    @State var searchText: String = ""
    @State var type: Fish.FishType?
    @State var tags: [String:Bool] = [:]
    @State var isMarked: Bool?
    @State var isLocked: Bool?
    @State var sortField: String = "Update Time"
    
    @State var isFiltering: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
            .fill(Constant.mainBackgroundColor)
            .stroke("A1A9C6".color, lineWidth: 2)
            .padding(3)
            VStack {
                HStack {
                    PasteBoardSearchView(searchText: $searchText)
                    .padding(.horizontal, 5)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    PasteBoardFilterButtonView(isFiltering: $isFiltering)
                    .padding(.trailing, 3)
                }
                HStack {
                    VStack {
                        VStack(alignment: .leading, spacing: 3) {
                            ScrollView(showsIndicators: false) {
                                LazyVStack {
                                    ForEach(fishList, id: \.uid) { fish in
                                        PasteBoardFishItemView(fish: fish, hoveredFish: $hoveredFish)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                        }
                        HStack {
                            Text("\(fishList.count) items")
                            .font(.callout)
                            .foregroundStyle(.gray)
                            .offset(y: 1.5)
                            Spacer()
                        }
                    }
                    HStack {
                        if isFiltering {
                            PasteBoardFishFilterView(type: $type, tags: $tags, isMarked: $isMarked, isLocked: $isLocked, sortField: $sortField)
                        } else {
                            if let fish = hoveredFish {
                                PasteBoardFishDetailView(fish: .constant(fish))
                            }
                        }
                    }
                    .frame(width: 550/2)
                }
            }
            .padding(10)
        }
        .onAppear {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRefreshFish)) { _ in
//            Log.debug("pasteboard refresh fish")
            Storage.incrementalUpdate()
            Task {
                var newTags: [String:Bool] = [:]
                if let stats = await Storage.countFish() {
                    let tags = stats.tagCount.keys.filter { !$0.isEmpty }
                    for tag in tags {
                        if let selected = self.tags[tag] {
                            newTags[tag] = selected
                        } else {
                            newTags[tag] = false
                        }
                    }
                }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.tags = newTags
                }
                updateFishList()
            }
        }
        .onChange(of: searchText) {
            updateFishList()
        }
        .onChange(of: type) {
            updateFishList()
        }
        .onChange(of: tags) {
            updateFishList()
        }
        .onChange(of: isMarked) {
            updateFishList()
        }
        .onChange(of: isLocked) {
            updateFishList()
        }
        .onChange(of: sortField) {
            updateFishList()
        }
    }
    
    private func updateFishList() {
        let fuzzy = searchText == "" ? nil : searchText
        let tags = Array(tags.filter { $0.value }.keys)
        let type = type == nil ? nil : [type!]
        Task {
            let fish = await Storage.searchFish(fuzzy: fuzzy, fishTypes: type, tags: tags.isEmpty ? nil : tags, isMarked: isMarked, isLocked: isLocked)
            let sortedFish = fish.values.sorted(by: {
                if sortField == "Create Time" {
                    return $0.createTime == $1.createTime ? $0.uid > $1.uid : $0.createTime > $1.createTime
                }
                if sortField == "Type" {
                    return $0.fishType == $1.fishType ? $0.uid > $1.uid : $0.fishType.rawValue > $1.fishType.rawValue
                }
                if sortField == "Size" {
                    let size0 = $0.dataInfo.byteCount ?? -1
                    let size1 = $1.dataInfo.byteCount ?? -1
                    return size0 == $1.dataInfo.byteCount ? $0.uid > $1.uid : size0 > size1
                }
                return $0.updateTime == $1.updateTime ? $0.uid > $1.uid : $0.updateTime > $1.updateTime
            })
            withAnimation {
                self.fishList = sortedFish
                if self.fishList.count == 0 {
                    self.hoveredFish = nil
                }
            }
        }
    }
    
}

struct PasteBoardFilterButtonView: View {
    
    @Binding var isFiltering: Bool
    
    @State var isHovering: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 20, maxHeight: 20)
            .foregroundStyle(.black.opacity(0.6))
        }
        .frame(width: 30, height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill("C6C7F4".color.opacity(isHovering ? 0.6 : 0.4))
        )
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            isFiltering.toggle()
        }
    }
}

struct PasteBoardSearchView: View {
    
    @Binding var searchText: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke("A1A9C6".color, lineWidth: 3)
            HStack {
                Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .padding([.vertical, .leading], 5)
                VStack {
                    Spacer(minLength: 0)
                    TextField("", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.custom("Menlo", size: 16))
                    Spacer(minLength: 0)
                }
                .padding([.vertical], 5)
            }
        }
        .background(Color.white)
        .cornerRadius(5)
        .frame(height: 16)
    }
    
}

struct PasteBoardFishItemView: View {
    
    var fish: Fish
    
    @Binding var hoveredFish: Fish?
    
    var isHovered: Bool {
        if let hoveredFish = hoveredFish {
            return fish.uid == hoveredFish.uid
        }
        return false
        
    }
    
    var body: some View {
        HStack {
            HStack {
                fish.fishIcon
                .resizable()
                .scaledToFit()
                .foregroundColor(isHovered ? "27295F".color : Color.black)
            }
            .frame(height: 16)
            if fish.isMarked {
                Text(fish.linePreview)
                    .font(.body)
                    .foregroundColor(isHovered ? Color.black: "222D59".color)
            } else {
                Text(fish.linePreview)
                    .font(.body)
                    .foregroundColor(isHovered ? "666970".color : Color.gray )
            }
            Spacer()
        }
        .padding(5)
        .background(isHovered ? "EEF2FD".color : .clear)
        .cornerRadius(5)
        .frame(height: 19)
        .onHover { isHovered in
            if isHovered {
                hoveredFish = fish
            }
        }
        .onTapGesture {
            fish.copyToClipboard()
            if Config.fastPasteToFrontmostApplication {
                TouchFishApp.pasteBoardWindow.hide()
                pasteToFrontmostApp()
            }
        }
    }
    
    func pasteToFrontmostApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            frontApp.activate(options: .activateIgnoringOtherApps)
    //        let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true)
    //        keyEvent?.flags = [.maskCommand]
    //        Log.debug("do copy")
    //        keyEvent?.post(tap: .cghidEventTap)
            Log.debug("paste fish to frontmost app")
            AppleScriptRunner.doPaste()
        } else {
            Log.warning("paste fish to frontmost app - failed: got frontApp=nil")
        }
    }
    
}

struct PasteBoardFishDetailView: View {
    
    @Binding var fish: Fish
    
    var body: some View {
        VStack {
            if fish.tags.count > 0 || fish.description.count > 0 {
                VStack {
                    if fish.tags.count > 0 {
                        DetailTagView(fish: $fish)
                        .padding(.bottom, -6)
                    }
                    if fish.description.count > 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(fish.description)
                            .font(.body)
                            .bold()
                        }
                        .padding(.bottom, -2)
                        .padding(.horizontal, 3)
                    }
                }
            }
            ScrollView {
                DetailValueView(fish: $fish)
            }
        }
        .padding(2)
    }
    
}

struct PasteBoardFishFilterView: View {
    
    @Binding var type: Fish.FishType?
    @Binding var tags: [String:Bool]
    @Binding var isMarked: Bool?
    @Binding var isLocked: Bool?
    @Binding var sortField: String
    
    @State var typeValue: String = "All"
    
    @State var isMarkedValue: Bool = false
    @State var isMarkedEnable: Bool = false
    @State var isMarkedDisableButtonHovered: Bool = false
    
    @State var isLockedValue: Bool = false
    @State var isLockedEnable: Bool = false
    @State var isLockedDisableButtonHovered: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Type")
                Spacer()
                Picker("", selection: $typeValue) {
                    ForEach(getOptions(), id: \.self) { opt in
                        Text(opt)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 80)
                .onChange(of: typeValue) {
                    self.type = Fish.FishType(rawValue: typeValue)
                }
            }
            HStack {
                Text("Tags")
                Spacer()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill("EEF2FD".color)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(tags.keys.sorted(by: { $0.lowercased() < $1.lowercased() })), id: \.self) { tg in
                            TagView(label: tg, tags: $tags)
                            .frame(height: 30)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.top, -3)
            .frame(height: 32)
            HStack(spacing: 10) {
                if let isMarked = isMarked {
                    Text("Marked: \(isMarked ? "Yes" : "No")")
                } else {
                    Text("Marked: All")
                }
                Spacer()
                if isMarkedEnable {
                    Image(systemName: isMarkedDisableButtonHovered ? "nosign.app.fill" : "nosign.app")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.gray)
                        .onHover { isHovered in
                            self.isMarkedDisableButtonHovered = isHovered
                        }
                        .onTapGesture {
                            isMarkedValue = false
                            isMarkedEnable = false
                            isMarked = nil
                        }
                }
                Toggle(isOn: $isMarkedValue) {}
            }
            HStack(spacing: 10) {
                if let isLocked = isLocked {
                    Text("Locked: \(isLocked ? "Yes" : "No")")
                } else {
                    Text("Locked: All")
                }
                Spacer()
                if isLockedEnable {
                    Image(systemName: isLockedDisableButtonHovered ? "nosign.app.fill" : "nosign.app")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.gray)
                        .onHover { isHovered in
                            self.isLockedDisableButtonHovered = isHovered
                        }
                        .onTapGesture {
                            isLockedValue = false
                            isLockedEnable = false
                            isLocked = nil
                        }
                }
                Toggle(isOn: $isLockedValue) {}
            }
            HStack {
                Text("Sort By")
                Spacer()
                Picker("", selection: $sortField) {
                    ForEach(["Update Time", "Create Time", "Type", "Size"], id: \.self) { opt in
                        Text(opt)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            Spacer()
        }
        .padding([.top, .horizontal], 5)
        .onAppear {
            if let type = type {
                self.typeValue = type.rawValue
            }
            if let isMarked = isMarked {
                isMarkedEnable = true
                isMarkedValue = isMarked
            }
            if let isLocked = isLocked {
                isLockedEnable = true
                isLockedValue = isLocked
            }
        }
        .onChange(of: isMarkedValue) {
            if isMarkedValue {
                isMarkedEnable = true
            }
            if isMarkedEnable {
                isMarked = isMarkedValue
            } else {
                isMarked = nil
            }
        }
        .onChange(of: isLockedValue) {
            if isLockedValue {
                isLockedEnable = true
            }
            if isLockedEnable {
                isLocked = isLockedValue
            } else {
                isLocked = nil
            }
        }
    }
    
    private func getOptions() -> [String] {
        var fishTypes = Fish.FishType.allCases.map { $0.rawValue }
        fishTypes.append("All")
        return fishTypes
    }
    
}
