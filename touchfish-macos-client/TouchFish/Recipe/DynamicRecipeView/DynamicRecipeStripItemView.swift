import SwiftUI

struct DynamicRecipeStripItemView: View {
    
    var size: DynamicRecipeViewInfo.ViewItem.Size
    var title: String
    var description: String?
    var iconPattern: String?
    var tags: [String]
    var hoverEffects: [DynamicRecipeViewInfo.ViewItem.HoverEffect]
    var operation: DynamicRecipeViewInfo.Operation?
    var value: String?
    var selectable: Bool
    
    @Binding var info: DynamicRecipeViewInfo
    
    var paraFieldEnable: Bool
    
    @State var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
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
            }
            .frame(height: (size == .Small ? 40 : (size == .Large ? 60 : 50))*(hoverEffects.contains(.Expand) ? (isHovered ? 0.5 : 0.4) : 0.4))
            .padding(.leading, 5)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: size == .Small ? 11 : (size == .Large ? 15 : 13)))
                        .fontWeight(.bold)
                        .foregroundStyle("27295F".color)
                    DynamicRecipeStripItemTagView(tags: tags, size: size)
                }
                if let desc = description, !hoverEffects.contains(.Description) || isHovered {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(desc)
                        .font(.system(size: size == .Small ? 8 : (size == .Large ? 12 : 10)))
                        .foregroundStyle("666970".color)
                    }
                }
            }
            Spacer()
        }
        .frame(height: (size == .Small ? 42 : (size == .Large ? 60 : 51))*(hoverEffects.contains(.Expand) ? (isHovered ? 1 : 0.8) : 0.9))
        .background(hoverEffects.contains(.Background) ? (isHovered ? "C6C7F4".color : Color.clear) : "C6C7F4".color)
        .cornerRadius(5)
        .padding(.horizontal, paraFieldEnable ? 5 : 12)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
        .onTapGesture {
            if let operation = operation {
                for action in operation.actions {
                    action.execute()
                }
            }
        }
    }
    
}

struct DynamicRecipeStripItemTagView: View {

    struct TagView: View {

        var label: String
        var size: DynamicRecipeViewInfo.ViewItem.Size

        var body: some View {
            Text(label)
            .font(.system(size: size == .Small ? 8 : (size == .Large ? 12 : 10)))
            .frame(minWidth: (size == .Small ? 25 : (size == .Large ? 40 : 30)))
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
    var size: DynamicRecipeViewInfo.ViewItem.Size

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(tags.enumerated()), id: \.0) { (_, tg) in
                    TagView(label: tg, size: size)
                }
                Spacer()
            }
            .frame(height: (size == .Small ? 10 : (size == .Large ? 16 : 13)))
            .padding(3)
        }

    }

}
