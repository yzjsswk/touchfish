import SwiftUI

struct DynamicRecipeFishSideView: View {
    
    @State var fishList: [Fish] = []
    
    @State var hoveredFish: Fish? = nil
    @State var selectedFish: Fish? = nil
    
    @State var searchText: String = ""
    @State var isMarked: Bool?
    @State var isLocked: Bool?
    @State var tags: [String:Bool] = [:]
    @State var sortField: String = "update"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DynamicRecipeFishSideSearchView(searchText: $searchText)
            ScrollView(showsIndicators: false) {
                ForEach(fishList, id: \.uid) { fish in
                    DynamicRecipeFishSideItemView(fish: fish, hoveredFish: $hoveredFish, selectedFish: $selectedFish)
                }
            }
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                .stroke("A1A9C6".color, lineWidth: 2)
                if let fish = (selectedFish != nil ? selectedFish : hoveredFish) {
                    DynamicRecipeFishSideDetailView(fish: .constant(fish))
                } else {
                    VStack {
                        DynamicRecipeFishSideFilterView(isMarked: $isMarked, isLocked: $isLocked, tags: $tags, sortField: $sortField)
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(fishList.count) items")
                                .font(.callout)
                                .foregroundStyle(.gray)
                        }
                        .padding(3)
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal, 3)
        }
        .padding(5)
        .onAppear {
            Task {
                let fish = await Storage.searchFish()
                self.fishList = fish.values.sorted(by: { $0.updateTime > $1.updateTime })
                self.tags.removeAll()
                if let stats = await Storage.countFish() {
                    let tags = stats.tagCount.keys.filter { !$0.isEmpty }
                    for tag in tags {
                        self.tags[tag] = false
                    }
                }
            }
        }
        .onChange(of: searchText) {
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
    }
    
    private func updateFishList() {
        let fuzzy = searchText == "" ? nil : searchText
        let tags = Array(tags.filter { $0.value }.keys)
        Task {
            let fish = await Storage.searchFish(fuzzy: fuzzy, tags: tags.isEmpty ? nil : tags, isMarked: isMarked, isLocked: isLocked)
            withAnimation {
                self.fishList = fish.values.sorted(by: { $0.updateTime > $1.updateTime })
            }
        }
    }
    
}

struct DynamicRecipeFishSideFilterView: View {
    
    struct TagView: View {
        
        var label: String
        @Binding var tags: [String:Bool]
        
        var body: some View {
            Text(label)
                .font(.custom("Menlo", size: 12))
                .frame(minWidth: 30)
                .background(
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 5)
                            .stroke("A1A9C6".color, lineWidth: tags[label, default: false] ? 0 : 1)
                            .fill(
                                tags[label, default: false] ? "5B5BCF".color : Color.clear
                            )
                            .frame(width: geometry.size.width+5, height: geometry.size.height+8)
                            .offset(x: -2.5, y: -4)
                    }
                )
                .foregroundStyle(tags[label, default: false] ? Color.white : "222D59".color)
                .onTapGesture {
                    tags[label]?.toggle()
                }
        }
        
    }

    
    @Binding var isMarked: Bool?
    @Binding var isLocked: Bool?
    @Binding var tags: [String:Bool]
    @Binding var sortField: String
    
    @State var isMarkedValue: Bool = false
    @State var isMarkedEnable: Bool = false
    @State var isMarkedDisableButtonHovered: Bool = false
    
    @State var isLockedValue: Bool = false
    @State var isLockedEnable: Bool = false
    @State var isLockedDisableButtonHovered: Bool = false
    
    var body: some View {
        VStack {
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
            .frame(height: 40)
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
        }
        .padding(5)
        .onAppear {
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
    
}

struct DynamicRecipeFishSideSearchView: View {
    
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
        .padding(.horizontal, 3)
        .padding(.top, 5)
        .padding(.bottom, 10)
    }
    
}

struct DynamicRecipeFishSideItemView: View {
    
    var fish: Fish
    
    @State var isHovered: Bool = false
    
    @Binding var hoveredFish: Fish?
    @Binding var selectedFish: Fish?
    
    private var isSelected: Bool {
        if let selectedFish = selectedFish, selectedFish.uid == fish.uid {
            return true
        }
        return false
    }
    
    var body: some View {
        HStack {
            HStack {
                fish.fishIcon
                .resizable()
                .scaledToFit()
                .foregroundColor((isSelected || isHovered) ? "27295F".color : Color.black)
            }
            .frame(height: 16)
            if fish.isMarked {
                Text(fish.linePreview)
                    .font(.body)
                    .foregroundColor((isSelected || isHovered) ? Color.black: "222D59".color)
            } else {
                Text(fish.linePreview)
                    .font(.body)
                    .foregroundColor((isSelected || isHovered) ? "666970".color : Color.gray )
            }
            Spacer()
        }
        .padding(5)
        .background(isSelected ? "C6C7F4".color : (isHovered ? "EEF2FD".color : .clear))
        .cornerRadius(5)
        .frame(height: 20)
        .onHover { isHovered in
            self.isHovered = isHovered
            TouchFishApp.mainWindow.isMovableByWindowBackground = !isHovered
            if isHovered {
                hoveredFish = fish
            } else {
                hoveredFish = nil
            }
        }
        .onTapGesture {
            if let selectedFish = selectedFish, selectedFish.uid == fish.uid {
                self.selectedFish = nil
            } else {
                self.selectedFish = fish
            }
        }
        .onDrag {
            let provider = NSItemProvider(object: NSString(string: fish.identity))
            return provider
        }
    }
    
}

struct DynamicRecipeFishSideDetailView: View {
    
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

