import SwiftUI

struct DynamicRecipeImageCardItemView: View {
    
    var size: DynamicRecipeViewInfo.ViewItem.Size
    var title: String
    var description: String?
    var iconPattern: String?
    var tags: [String]
    var imagePatterns: [String]
    var properties: [DynamicRecipeViewInfo.ViewItem.Property]
    var showProperties: Bool
    var operations: [DynamicRecipeViewInfo.Operation]
    var value: String?
    var selectable: Bool

    @Binding var info: DynamicRecipeViewInfo
    
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
                            if let pattern = iconPattern, let image = info.patternToImage(pattern: pattern) {
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
                        TabView {
                            ForEach(imagePatterns, id: \.self) { pattern in
                                if pattern == "loading" {
                                    DynamicRecipeLoadingIconView()
                                } else {
                                    if let image = info.patternToImage(pattern: pattern) {
                                        image
                                        .resizable()
                                        .scaledToFit()
                                    } else {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(.yellow)
                                    }
                                }
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
                                                for action in op.actions {
                                                    action.execute()
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
                if showProperties && !paraFieldEnable {
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
        .frame(height: (size == .Small ? 180 : (size == .Large ? 480 : 300)))
    }

}
