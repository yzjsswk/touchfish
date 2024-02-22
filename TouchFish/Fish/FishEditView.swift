import SwiftUI

struct FishEditView: View {
    
    var id: Int
    @State var description: String
    @State var content: String
    @State var descriptionAreaHeight: Int = 100
    @State var contentAreaHeight: Int = 100
    @State var selectedTypeIndex: Int
    @State var tags: [String]
    
    @State var showSaveAlert = false
    @State var alertMessage = ""
    
    @Binding var isEditing: Bool
    
    let allowSaveTypes: [FishType] = [.text, .image]
    
    var body: some View {
        VStack {
            HStack {
                BackButtonView()
                    .onTapGesture {
                        isEditing = false
                    }
                Spacer()
                SaveButtonView()
                    .onTapGesture {
                        let type = FishType.allCases[selectedTypeIndex]
                        if !allowSaveTypes.contains(type) {
                            showSaveAlert = true
                            alertMessage = "type \(type) is not allowed to save"
                            return
                        }
                        // todo: use storage
                        let res = DB.updateFish(of: id, description: description, tag: tags)
                        if !res {
                            showSaveAlert = true
                            alertMessage = "save failed"
                            return
                        }
                        isEditing = false
                    }
                    .alert(isPresented: $showSaveAlert) {
                        Alert(
                            title: Text("save failed"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("ok"))
                        )
                    }
            }
            Divider().background(Color.gray.opacity(0.2)) 
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("type")
                        .font(.title2)
                        .bold()
                    Picker("", selection: $selectedTypeIndex) {
                        ForEach(0..<FishType.allCases.count) { idx in
                            Text(FishType.allCases[idx].rawValue)
                        }
//                        ForEach(FishType.allCases, id: \.index) { type in
//                            Text(type.rawValue)
//                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: CGFloat(FishType.allCases.count * 100))
                    .disabled(true)
                    
                    HStack(spacing: 10) {
                        Text("tag")
                            .font(.title2)
                            .bold()
                        TagEditView(tags: $tags)
                    }
                    LazyVGrid(columns: [
                        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
                        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(tags, id: \.self) { tg in
                            TagView(label: tg, tags: $tags)
                        }
                    }
                        
                        
                    Text("description")
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
                    .frame(height: 100)
                    
                    Text("content")
                        .font(.title2)
                        .bold()
                    ZStack {
                        VStack {
                            Spacer()
                            TextEditor(text: $content)
                                .font(.custom("Menlo", size: 12))
                            Spacer()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(height: 600)
//                    .disabled(true)
                }
            }
            .frame(width: CONFIG.mainWidth - 30)
            .padding(5)
        }
        .onChange(of: description) { _ in
            descriptionAreaHeight = min(100, description.count / 30)
        }
    }
    
}

struct BackButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        Image(systemName: "arrow.backward.square")
        .resizable()
        .frame(width: 25, height: 25)
        .foregroundColor(isHovered ? CONFIG.selectedItemBackgroundColor.color : .gray)
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
        ZStack {
            Rectangle()
                .fill(String(Functions.getMD5(of: label).prefix(6)).color)
            .overlay(
                Text(label)
                .foregroundColor(.white)
            )
            .frame(width: 100, height: 25)
            .cornerRadius(10)
            
            if isHovered {
                Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 15, height: 15)
                .offset(x: 40)
                .foregroundColor(.orange)
                .onTapGesture {
                    tags.removeAll(where: { $0 == label } )
                }
            }
        }
        .onHover { isHovered in
            withAnimation {
                self.isHovered = isHovered
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
            .foregroundColor(isHovered1 ? CONFIG.selectedItemBackgroundColor.color : .gray)
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
                .onChange(of: tagSearchText, perform: { value in
                    let allTags = Cache.TagCache.tagMap.keys
                    tagPreviewList = allTags.filter { tg in
                        return tg.lowercased().contains(tagSearchText.lowercased())
                    }
                    isShowTagPreview = !tagPreviewList.isEmpty
                })
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
                        tags.append(tagSearchText)
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

