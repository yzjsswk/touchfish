import SwiftUI

struct DynamicRecipeTextCardItemView: View {
    
    var size: DynamicRecipeViewInfo.ViewItem.Size
    var title: String
    var description: String?
    var iconPattern: String?
    var tags: [String]
    var content: String
    var properties: [DynamicRecipeViewInfo.ViewItem.Property]
    var showProperties: Bool
    var operations: [DynamicRecipeViewInfo.Operation]
    var value: String?
    var selectable: Bool

    @Binding var info: DynamicRecipeViewInfo
    @Binding var context: RecipeExecutionContext
    
    var paraFieldEnable: Bool
    
    @State var isHovered: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(radius: 10)
            HStack {
                VStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let pattern = iconPattern {
                                if let image = info.patternToImage(pattern: pattern) {
                                    image
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle("27295F".color)
                                } else {
                                    Image(systemName: "questionmark.square")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle("27295F".color)
                                }
                            }
                            Text(title)
                            .font(.title2)
                            DynamicRecipeCardItemTagView(tags: tags)
                        }
                        .frame(height: 20)
                        if let desc = description {
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(desc)
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                    ZStack {
                        ScrollView(showsIndicators: false) {
                            if let contentMd = try? AttributedString(markdown: content) {
                                Text(contentMd)
                                .font(.body)
                            } else {
                                Text(content)
                                .font(.body)
                            }
                        }
                        if isHovered {
                            HStack {
                                Spacer()
                                VStack {
                                    Spacer()
                                    ForEach(Array(operations.enumerated()), id: \.0) { _, op in
                                        DynamicRecipeCardItemButtonView(label: op.name)
                                        .frame(width: 90, height: 25)
                                        .offset(x: -5, y: -5)
                                        .onTapGesture {
                                            Task {
                                                for action in op.actions {
                                                    await context.executeAction(action: action)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .onHover { isHovered in
                        self.isHovered = isHovered
                    }
                }
                if showProperties {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        .fill(Constant.commandBarBackgroundColor)
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading) {
                                ForEach(Array(properties.enumerated()), id: \.0) { i, p in
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
            }
            .padding()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: ((size == .Small || (size == .Adaptive && content.count < (showProperties ? 80*4 : 115*4))) ? 180 : ((size == .Large || (size == .Adaptive && content.count > (showProperties ? 200*4 : 275*4))) ? 480 : 300)))
    }

}

struct DynamicRecipeCardItemButtonView: View {

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

struct DynamicRecipeCardItemTagView: View {

    struct TagView: View {

        var label: String

        var body: some View {
            Text(label)
            .font(.system(size: 11))
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

    var tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(tags.enumerated()), id: \.0) { (_, tg) in
                    TagView(label: tg)
                }
                Spacer()
            }
            .frame(height: 16)
            .padding(3)
        }

    }

}


struct DynamicRecipeLoadingIconView: View {

    @State private var isAnimating = false

    var body: some View {
        HStack {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            .resizable()
            .scaledToFit()
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }

}
