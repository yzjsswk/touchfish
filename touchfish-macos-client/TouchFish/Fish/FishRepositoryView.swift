import SwiftUI

struct FishRepositoryView: View {
    
    @State var fishs: [String:Fish] = [:]
    @State var fishList: [Fish] = []
    
    @State var selectedFishUid: String?
    @State var isEditing: Bool = false
    @State var isMultSelecting: Bool = false
    @State var multSelectedFishUids: Set<String> = []
    
    @State var fishItemPosOffset: CGFloat = -1
    
    @State var fuzzy: String? = nil
    @State var identitys: [String]? = nil
    @State var fishTypes: [Fish.FishType]? = nil
    @State var tags: [String]? = nil
    @State var isMarked: Bool? = nil
    @State var isLocked: Bool? = nil
    @State var passedHours: Int? = nil
    @State var sortField: String = ""
    
    var isAllMultSelected: Bool {
        for uid in fishs.keys {
            if !multSelectedFishUids.contains(uid) {
                return false
            }
        }
        return true
    }
    
    var isAllMultSelectedLocked: Bool {
        for uid in multSelectedFishUids {
            if let fish = fishs[uid], fish.isLocked == false {
                return false
            }
        }
        return true
    }
    
    var isAllMultSelectedMarked: Bool {
        for uid in multSelectedFishUids {
            if let fish = fishs[uid], fish.isMarked == false {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        HStack {
            if isEditing, let uid = selectedFishUid, let editingFish = fishs[uid] {
                FishEditView(
                    isEditing: $isEditing,
                    uid: editingFish.uid,
                    description: editingFish.description,
                    tags: Dictionary(uniqueKeysWithValues: editingFish.tags.map { ($0, true) })
                )
                .frame(width: Constant.mainWidth-30)
            } else {
                VStack {
                    if isMultSelecting {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill("C6C7F4".color)
                            HStack(spacing: 3) {
                                if isAllMultSelected {
                                    HStack {
                                        Image(systemName: "checkmark.square")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle("27295F".color)
                                            .onTapGesture {
                                                multSelectedFishUids.removeAll()
                                            }
                                    }
                                    .frame(width: 25, height: 20)
                                } else {
                                    HStack {
                                        Image(systemName: "square")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle("27295F".color)
                                            .onTapGesture {
                                                for uid in fishs.keys {
                                                    multSelectedFishUids.insert(uid)
                                                }
                                            }
                                    }
                                    .frame(width: 25, height: 20)
                                }
                                Spacer()
                                // todo: icon move anima when lock
                                if isAllMultSelectedLocked {
                                    MultUnLockButtonView()
                                        .onTapGesture {
                                            Task {
                                                await Storage.unLockFish(Array(multSelectedFishUids))
                                            }
                                        }
                                } else {
                                    MultLockButtonView()
                                        .onTapGesture {
                                            Task {
                                                await Storage.lockFish(Array(multSelectedFishUids))
                                            }
                                        }
                                    if isAllMultSelectedMarked {
                                        MultUnMarkButtonView()
                                            .onTapGesture {
                                                Task {
                                                    await Storage.unMarkFish(Array(multSelectedFishUids))
                                                }
                                            }
                                    } else {
                                        MultMarkButtonView()
                                            .onTapGesture {
                                                Task {
                                                    await Storage.markFish(Array(multSelectedFishUids))
                                                }
                                            }
                                    }
                                    MultDeleteButtonView()
                                        .onTapGesture {
                                            Task {
                                                await Storage.removeFish(Array(multSelectedFishUids))
                                                multSelectedFishUids.removeAll()
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                        .padding(.horizontal, 3)
                        .frame(height: 40)
                    }
                    FishListView(
                        fishList: $fishList,
                        selectedFishUid: $selectedFishUid,
                        isEditing: $isEditing,
                        isMultSelecting: $isMultSelecting,
                        multSelectedFishUids: $multSelectedFishUids,
                        fishItemPosOffset: $fishItemPosOffset
                    )
                    .frame(width: (Constant.mainWidth - 30)/2)
                }
                FishDetailView(
                    fishs: $fishs,
                    selectedFishUid: $selectedFishUid,
                    isMultSelecting: $isMultSelecting,
                    multSelectedFishUids: $multSelectedFishUids
                )
                .frame(width: (Constant.mainWidth - 30)/2)
            }
        }
        .padding(.horizontal, 5)
        .onAppear {
            isEditing = false
            NotificationCenter.default.post(name: .CommandBarShouldFocus, object: nil, userInfo: nil)
            NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRefreshFish)) { _ in
            Storage.incrementalUpdate()
            Task {
                let fishs = await Storage.searchFish(
                    fuzzy: fuzzy, identitys: identitys, fishTypes: fishTypes,
                    tags: tags, isMarked: isMarked, isLocked: isLocked, passedHours: passedHours
                )
                NotificationCenter.default.post(name: .FishRefreshed, object: nil, userInfo: ["fish":fishs])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .FishRefreshed)) { notification in
            if let fish = notification.userInfo?["fish"] as? [String:Fish] {
                let fishList = fish.values.sorted(by: {
                    if sortField.lowercased() == "create" {
                        return $0.createTime == $1.createTime ? $0.uid > $1.uid : $0.createTime > $1.createTime
                    }
                    if sortField.lowercased() == "type" {
                        return $0.fishType == $1.fishType ? $0.uid > $1.uid : $0.fishType.rawValue > $1.fishType.rawValue
                    }
                    if sortField.lowercased() == "size" {
                        let size0 = $0.dataInfo.byteCount ?? -1
                        let size1 = $1.dataInfo.byteCount ?? -1
                        return size0 == $1.dataInfo.byteCount ? $0.uid > $1.uid : size0 > size1
                    }
                    return $0.updateTime == $1.updateTime ? $0.uid > $1.uid : $0.updateTime > $1.updateTime
                })
                if self.fishs.isEmpty || fish.isEmpty {
                    self.fishs = fish
                    self.fishList = fishList
                    fishItemPosOffset = -1
                    withAnimation(.easeOut(duration: 0.4)) {
                        fishItemPosOffset = 0
                    }
                } else {
                    withAnimation(.spring(duration: 0.4)) {
                        self.fishs = fish
                        self.fishList = fishList
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandBarEndEditing)) { notification in
            fuzzy = nil
            if let commandText = notification.userInfo?["commandText"] as? String, !isEditing, commandText != "" {
                fuzzy = commandText
            }
            NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
            identitys = nil
            fishTypes = nil
            tags = nil
            isMarked = nil
            isLocked = nil
            passedHours = nil
            sortField = ""
            for (argName, argValue) in RecipeManager.activeRecipeArg {
                if argName == "identity" {
                    identitys = argValue
                }
                if argName == "type" {
                    fishTypes = argValue.compactMap { Fish.FishType(rawValue: $0.capitalized) }
                }
                if argName == "tag" {
                    tags = argValue
                }
                if argName == "marked", argValue.count > 0 {
                    if argValue[0].lowercased() == "true" || argValue[0] == "1" {
                        isMarked = true
                    }
                    if argValue[0].lowercased() == "false" || argValue[0] == "0" {
                        isMarked = false
                    }
                }
                if argName == "locked", argValue.count > 0 {
                    if argValue[0].lowercased() == "true" || argValue[0] == "1" {
                        isLocked = true
                    }
                    if argValue[0].lowercased() == "false" || argValue[0] == "0" {
                        isLocked = false
                    }
                }
                if argName == "passed", argValue.count > 0 {
                    if let value = Int(argValue[0]) {
                        passedHours = value
                    }
                }
                if argName == "sort", argValue.count > 0 {
                    sortField = argValue[0].lowercased()
                }
            }
            NotificationCenter.default.post(name: .ShouldRefreshFish, object: nil, userInfo: nil)
        }
    }

}

struct MultLockButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "lock.fill" : "lock")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color)
                .frame(width: isHovered ? 28 : 26, height: isHovered ? 23 : 21)
        }
        .frame(width: 28, height: 23)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct MultUnLockButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color.opacity(isHovered ? 0.5 : 1.0))
                .frame(width: isHovered ? 28 : 26, height: isHovered ? 23 : 21)
        }
        .frame(width: 28, height: 23)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct MultMarkButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "bookmark.fill" : "bookmark")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color)
                .frame(width: isHovered ? 23 : 21, height: isHovered ? 23 : 21)
        }
        .frame(width: 23, height: 23)
        .offset(y:1)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct MultUnMarkButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color.opacity(isHovered ? 0.5 : 1.0))
                .frame(width: isHovered ? 23 : 21, height: isHovered ? 23 : 21)
        }
        .frame(width: 23, height: 23)
        .offset(y:1)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct MultDeleteButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "trash.fill" : "trash")
                .resizable()
                .scaledToFit()
                .foregroundStyle("27295F".color)
                .frame(width: isHovered ? 23 : 21, height: isHovered ? 23 : 21)
        }
        .frame(width: 23, height: 23)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}
