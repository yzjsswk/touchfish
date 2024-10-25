import SwiftUI

struct FishEditView: View {
    
    @Binding var isEditing: Bool
    
    var identity: String
    
    @State var description: String
    @State var tags: [String:Bool]
    
    @State var showSaveAlert = false
    @State var alertMessage = ""
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Editing of \(identity)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            Divider().background(Color.gray.opacity(0.2))
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        HStack(spacing: 12) {
                            Text("Tag")
                                .font(.title2)
                            TagAddView(tags: $tags)
                                .offset(y: 1)
                        }
                        .padding(.vertical, 5)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill("EEF2FD".color)
                                .frame(height: 40)
                            // TODO: tag view change line
                            HStack(spacing: 12) {
                                ForEach(Array(tags.keys.sorted()), id: \.self) { tg in
                                    TagView(label: tg, tags: $tags)
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
                            TextEditor(text: $description)
                                .font(.custom("Menlo", size: 16))
                            Spacer()
                        }.padding(.horizontal, 5)
                    }
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(height: Constant.mainWidth*0.3)
                }
            }
            .padding()
            HStack(spacing: 200) {
                Spacer()
                ButtonView(label: "Cancel")
                .frame(width: 80, height: 40)
                .onTapGesture {
                    isEditing = false
                    NotificationCenter.default.post(name: .CommandBarShouldFocus, object: nil, userInfo: nil)
                }
                ButtonView(label: "Apply")
                .frame(width: 80, height: 40)
                .onTapGesture {
                    Task {
                        let ok = await Storage.modifyFish(identity, description: description, tags: tags.filter({ $0.value }).map({$0.key}))
                        if ok {
                            isEditing = false
                            NotificationCenter.default.post(name: .CommandBarShouldFocus, object: nil, userInfo: nil)
                        } else {
                            showSaveAlert = true
                            alertMessage = "Save failed."
                        }
                    }
                }
                .alert(isPresented: $showSaveAlert) {
                    Alert(
                        title: Text("Modify Fish"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("Ok"))
                    )
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            Task {
                if let stats = await Storage.countFish() {
                    for tg in stats.tagCount.keys {
                        if !tg.isEmpty && !tags.keys.contains(tg) {
                            tags[tg] = false
                        }
                    }
                }
            }
        }
    }
    
}

struct ButtonView: View {

    var label: String
    
    @State var isHovered: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? "B8B9F4".color : "D6D6F9".color, lineWidth: 2)
                .fill(isHovered ? "F8F8FE".color : .white)
            Text(label)
                .font(.title3)
                .foregroundStyle(isHovered ? "27295F".color : "4C4C4C".color)
                .padding(3)
        }
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
}

struct TagView: View {
    
    var label: String
    @Binding var tags: [String:Bool]
    
    var body: some View {
        Text(label)
            .frame(minWidth: 40)
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

struct TagAddView: View {
    
    @State private var isOpening = false
    
    @State private var isHovered1 = false
    @State private var isHovered2 = false
    @State private var isHovered3 = false
    
    @State private var tag = ""
    
    @Binding var tags: [String:Bool]
    
    var body: some View {
        if !isOpening {
            Image(systemName: "plus.circle")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(isHovered1 ? "27295F".color : .gray)
            .onHover { isHovered in
                self.isHovered1 = isHovered
            }
            .onTapGesture {
                isOpening = true
            }
        } else {
            HStack {
                TextField("", text: $tag)
                .frame(width: 100, height: 20)
                Image(systemName: "checkmark.circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isHovered2 ? "27295F".color : .gray)
                .onHover { isHovered in
                    self.isHovered2 = isHovered
                }
                .onTapGesture {
                    if !tags.keys.contains(tag) {
                        withAnimation {
                            tags[tag] = true
                        }
                    }
                    isOpening = false
                    tag = ""
                }
                Image(systemName: "xmark.circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isHovered3 ? "27295F".color : .gray)
                .onHover { isHovered in
                    self.isHovered3 = isHovered
                }
                .onTapGesture {
                    isOpening = false
                    tag = ""
                }
            }
        }
    }
}
