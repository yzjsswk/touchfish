import SwiftUI

struct FishEditView: View {
    
    @Binding var isEditing: Bool
    
    var identity: String
    
    @State var description: String
    @State var tags: [String]
    
    @State var showSaveAlert = false
    @State var alertMessage = ""
    
    var body: some View {
        VStack {
            HStack {
                BackButtonView()
                    .onTapGesture {
                        isEditing = false
                        NotificationCenter.default.post(name: .CommandBarShouldFocus, object: nil, userInfo: nil)
                    }
                Spacer()
                Text("Editing of \(identity)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                SaveButtonView()
                    .onTapGesture {
                        Task {
                            let ok = await Storage.modifyFish(identity, description: description, tags: tags)
                            if ok {
                                isEditing = false
                                NotificationCenter.default.post(name: .CommandBarShouldFocus, object: nil, userInfo: nil)
                            } else {
                                showSaveAlert = true
                                alertMessage = "save failed"
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
            }
            Divider().background(Color.gray.opacity(0.2))
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Text("Tag")
                            .font(.title2)
                            .bold()
                        ForEach(tags, id: \.self) { tg in
                            TagView(label: tg, tags: $tags)
                        }
                        .offset(y: 1)
                        TagEditView(tags: $tags)
                        .offset(y: 1)
                    }
                    .padding(.top)
                    Text("Description")
                        .font(.title2)
                        .bold()
                    ZStack {
                        VStack {
                            Spacer()
                            TextEditor(text: $description)
                                .font(.custom("Menlo", size: 16))
                            Spacer()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(height: Constant.mainWidth*0.3)
                    
                }
            }
            .padding()
        }
    }
    
}

struct BackButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        Image(systemName: "arrow.backward.square")
        .resizable()
        .frame(width: 25, height: 25)
        .foregroundColor(isHovered ? .yellow : .gray)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
}

struct SaveButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        Image(systemName: "checkmark.square.fill")
        .resizable()
        .frame(width: 25, height: 25)
        .foregroundColor(isHovered ? .green : .gray)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
}

struct TagView: View {
    
    var label: String
    
    @State private var isHovered = false
    
    @Binding var tags: [String]
    
    var body: some View {
        Text(label)
            .frame(minWidth: 40)
            .background(
                GeometryReader { geometry in
                    Rectangle()
                        .cornerRadius(8)
                        .foregroundStyle(Constant.tagBackgroundColor)
                        .frame(width: geometry.size.width+5, height: geometry.size.height+8)
                        .offset(x: -2.5, y: -4)
                }
            )
            .foregroundStyle(Functions.makeLinearGradient(colors: ["444444"]))
            .opacity(isHovered ? 0.5 : 1.0)
            .offset(y: isHovered ? 5 : 0)
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
            .onTapGesture {
                withAnimation {
                    tags.removeAll(where: { $0 == label } )
                }
            }
    }
    
}

struct TagEditView: View {
    
    @State private var isOpening = false
    
    @State private var isHovered1 = false
    @State private var isHovered2 = false
    @State private var isHovered3 = false
    
    @State private var tagSearchText = ""
    @State private var isShowTagPreview = false
    @State private var tagPreviewList: [String] = []
    
    @Binding var tags: [String]
    
    var body: some View {
        
        if !isOpening {
            Image(systemName: "plus.circle")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(isHovered1 ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
            .onHover { isHovered in
                self.isHovered1 = isHovered
            }
            .onTapGesture {
                isOpening = true
            }
        } else {
            HStack {
                TextField("Search", text: $tagSearchText)
                .frame(width: 100, height: 20)
                .onChange(of: tagSearchText) {
                    let allTags: [String] = []
                    tagPreviewList = allTags.filter { tg in
                        return tg.lowercased().contains(tagSearchText.lowercased())
                    }
                    isShowTagPreview = !tagPreviewList.isEmpty
                }
                .popover(isPresented: $isShowTagPreview, arrowEdge: .bottom) {
                    VStack {
                        ForEach(tagPreviewList, id: \.self) { item in
                            TagPreviewView(label: item, tagSearchText: $tagSearchText)
                        }
                    }
                }
                Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isHovered2 ? .green : .gray)
                .onHover { isHovered in
                    self.isHovered2 = isHovered
                }
                .onTapGesture {
                    if !tags.contains(tagSearchText) {
                        withAnimation {
                            tags.append(tagSearchText)
                        }
                    }
                    isOpening = false
                    tagSearchText = ""
                    tagPreviewList = []
                }
                Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isHovered3 ? .red : .gray)
                .onHover { isHovered in
                    self.isHovered3 = isHovered
                }
                .onTapGesture {
                    isOpening = false
                    tagSearchText = ""
                    tagPreviewList = []
                }
            }
        }
    }

}

struct TagPreviewView: View {
    
    var label: String
    
    @State private var isHovered = false
    
    @Binding var tagSearchText: String
    
    var body: some View {
        Text(label)
            .padding()
            .foregroundColor(isHovered ? .black : .gray)
//            .font(isHovered ? .custom("Menlo", size: 12) : .custom("Menlo", size: 10))
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .onTapGesture {
                tagSearchText = label
            }
    }
    
}

