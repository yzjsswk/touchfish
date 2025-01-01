import SwiftUI

struct DynamicRecipeCardView: View {
    
    var data: [Data]
    var item: DynamicRecipeViewInfo.ViewItem
    
    @State var isSelected: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(radius: 10)
            HStack {
                VStack {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            if let icon = item.icon {
                                icon
                                .resizable()
                                .scaledToFit()
                            }
                            Text(item.title)
                            .font(.title2)
                            DynamicRecipeCardTagView(item: item)
                        }
                        .frame(height: 20)
                        if let desc = item.description {
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(desc)
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                    ZStack {
                        TabView {
                            ForEach(item.images, id: \.self) { image in
                                (item.patternToImage(pattern: image) ?? Image(systemName: "doc.plaintext"))
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                            }
                        }
                        if isSelected {
                            HStack {
                                Spacer()
                                VStack {
                                    Spacer()
                                    ForEach(Array(item.operations.enumerated()), id: \.0) { _, op in
                                        DynamicRecipeCardButtonView(label: op.name)
                                            .frame(width: 90, height: 25)
                                            .offset(x: -5, y: -5)
                                            .onTapGesture {
                                                for action in op.actions {
                                                    action.execute()
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Constant.commandBarBackgroundColor)
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading) {
                            ForEach(Array(item.properties.enumerated()), id: \.0) { i, p in
                                HStack {
                                    Text(p.name)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.black)
                                    .bold()
                                    Spacer()
                                    Text(p.value)
                                    .foregroundStyle(.black)
                                    .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 5)
                }
                .frame(width: Constant.mainWidth*0.2)
            }
            .padding()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: Constant.userDefinedRecipeItemHeight*6)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
    }
    
}

struct DynamicRecipeCardButtonView: View {

    var label: String
    
    @State var isHovered: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? "B8B9F4".color : "D6D6F9".color, lineWidth: 2)
                .fill(isHovered ? "F8F8FE".color : .white)
            Text(label)
                .font(.body)
                .foregroundStyle(isHovered ? "27295F".color : "4C4C4C".color)
                .padding(3)
        }
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
}

struct DynamicRecipeCardTagView: View {
    
    struct TagView: View {
        
        var label: String
        
        var body: some View {
            Text(label)
            .frame(minWidth: 40)
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
    
    var item: DynamicRecipeViewInfo.ViewItem
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(item.tags.enumerated()), id: \.0) { (_, tg) in
                    TagView(label: tg)
                }
                Spacer()
            }
            .frame(height: 20)
            .padding(3)
        }
        
    }
    
}
