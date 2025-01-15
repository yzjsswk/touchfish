import SwiftUI

struct FishDetailView: View {
    
    @Binding var fishs: [String:Fish]
    @Binding var selectedFishUid: String?
    @Binding var isMultSelecting: Bool
    @Binding var multSelectedFishUids: Set<String>
    
    var selectedFish: Fish? {
        if let uid = selectedFishUid {
            return fishs[uid]
        }
        return nil
    }
    
    @State var showDetail: Bool = false
    @State var showDetailWithAnima: Bool = false
    
    var body: some View {
        VStack {
            if let selectedFish = self.selectedFish, 
                selectedFish.tags.count > 0 || selectedFish.description.count > 0 {
                VStack {
                    if selectedFish.tags.count > 0 {
                        DetailTagView(fish: .constant(selectedFish))
                    }
                    if selectedFish.description.count > 0 {
                        DetailDescView(fish: .constant(selectedFish))
                    }
                }
            }
            if let selectedFish = self.selectedFish {
                ScrollView {
                    DetailValueView(fish: .constant(selectedFish))
                }
            } else {
                Color.clear
                .contentShape(Rectangle())
                .frame(height: Constant.mainHeight*0.5)
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                .fill(Constant.commandBarBackgroundColor)
                .frame(height: showDetailWithAnima ? Constant.mainHeight*0.3 : 0)
                if let selectedFish = self.selectedFish {
                    DetailExtraInfoView(fish: .constant(selectedFish))
                    .frame(height: showDetailWithAnima ? Constant.mainHeight*0.3 : 0)
                    .padding(.top, 8)
                    .padding(.horizontal, 5)
                }
                if !showDetail {
                    UpArrowView()
                    .onTapGesture {
                        withAnimation(.spring) {
                            showDetailWithAnima = true
                        }
                        showDetail = true
                    }
                }
            }
        }
        .onTapGesture {
            // TODO: when there is no fish, click not take effect
            withAnimation {
                showDetailWithAnima = false
            }
            showDetail = false
            withAnimation {
                isMultSelecting = false
            }
            multSelectedFishUids.removeAll()
        }
    }
    
}

struct DetailTagView: View {
    
    struct TagView: View {
        
        var label: String
        
        var body: some View {
            Text(label)
                .font(.custom("Menlo", size: 12))
                .frame(minWidth: 30)
            .background(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 5)
                        .fill("5B5BCF".color)
                        .frame(width: geometry.size.width+5, height: geometry.size.height+8)
                        .offset(x: -2.5, y: -4)
                }
            )
            .foregroundStyle(.white)
        }
    }
    
    @Binding var fish: Fish
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(fish.tags.enumerated()), id: \.0) { (_, tg) in
                    TagView(label: tg)
                }
                Spacer()
            }
            .frame(height: 20)
            .padding(3)
        }
        
    }
    
}
    
struct DetailDescView: View {
    
    @Binding var fish: Fish
    
    var body: some View {
        HStack {
            Text(fish.description)
                .font(.title3)
                .bold()
                .padding([.top, .horizontal], 3)
            Spacer()
        }
    }
    
}

struct DetailValueView: View {
    
    @Binding var fish: Fish
    
    var body: some View {
        switch fish.fishType {
        case .Text:
            VStack {
                if let textValue = fish.textData {
                    Text(textValue.prefix(Config.textFishDetailPreviewLength))
                        .font(.callout)
                    if textValue.count > Config.textFishDetailPreviewLength {
                        Text("...")
                            .font(.callout)
                            .bold()
                    }
                } else {
                    Text("No Preview (This may be dirty data)")
                        .font(.callout)
                        .bold()
                        .foregroundColor(.gray)
                }
            }
        case .Image:
            if let image = fish.imageData {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("No Preview (This may be dirty data)")
                    .font(.callout)
                    .bold()
                    .foregroundColor(.gray)
            }
        default:
            Text("Not Supported To Preview")
                .font(.callout)
                .bold()
                .foregroundColor(.gray)
        }
    }
    
}

struct DetailExtraInfoView: View {
    
    @Binding var fish: Fish
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                Spacer()
                DetailItemView(itemName: "Type", itemValue: fish.fishType.rawValue)
                DetailItemView(itemName: "Repeats Number", itemValue: fish.count)
                DetailItemView(itemName: "Source Application", itemValue: fish.extraInfo.sourceAppName)
                switch fish.fishType {
                case .Text:
                    DetailItemView(itemName: "Char Count", itemValue: fish.dataInfo.charCount)
                    DetailItemView(itemName: "Word Count", itemValue: fish.dataInfo.wordCount)
                    DetailItemView(itemName: "Row Count", itemValue: fish.dataInfo.rowCount)
                case .Image:
                    DetailItemView(itemName: "Width", itemValue: fish.dataInfo.width)
                    DetailItemView(itemName: "Height", itemValue: fish.dataInfo.height)
                default:
                    EmptyView()
                }
                if let byteCount = fish.dataInfo.byteCount {
                    DetailItemView(itemName: "Size", itemValue: Functions.descByteCount(byteCount))
                }
                DetailItemView(itemName: "Create Time", itemValue: fish.createTime)
                DetailItemView(itemName: "Update Time", itemValue: fish.updateTime)
                Spacer()
            }
        }
    }
    
}

struct DetailItemView: View {
    
    var itemName: String
    var itemValue: String?
    
    init(itemName: String, itemValue: String? = nil) {
        self.itemName = itemName
        self.itemValue = itemValue
    }
    
    init(itemName: String, itemValue: Int? = nil) {
        self.itemName = itemName
        if let itemValue = itemValue {
            self.itemValue = String(itemValue)
        }
    }
    
    var body: some View {
        if let itemValue = itemValue {
            HStack {
                Text(itemName)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.black)
                    .bold()
                Spacer()
                Text(itemValue)
                    .foregroundStyle(.black)
                    .font(.system(.body, design: .monospaced))
            }
            .frame(height: Constant.fishDetailItemHeight)
        }
    }
    
}

struct UpArrowView: View {
    
    @State var isHovered: Bool = false
    
    struct ArrowShap: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            return path
        }
    }

    var body: some View {
        ArrowShap()
            .stroke("27295F".color.opacity(isHovered ? 1 : 0.5), lineWidth: 2)
            .frame(width: Constant.mainWidth*0.15, height: 10)
            .background(Color.gray.opacity(0.01))
            .offset(y: isHovered ? 0 : 5)
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
    }
    
}
