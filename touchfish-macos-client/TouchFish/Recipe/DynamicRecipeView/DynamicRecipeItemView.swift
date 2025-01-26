import SwiftUI

struct DynamicRecipeItemView: View {
    
    var item: DynamicRecipeViewInfo.ViewItem
    
    @Binding var info: DynamicRecipeViewInfo
    
    var body: some View {
        switch item {
        case .Info(let title, let body, let value, let selectable):
            Text(title)
        case .Warn(let title, let body, let value, let selectable):
            Text(title)
        case .Error(let title, let body, let value, let selectable):
            DynamicRecipeErrorItemView(title: title, datail: body, value: value, selectable: selectable, info: $info)
        case .Strip(
            let size, let title, let description, let iconPattern, let tags,
            let operation, let value, let selectable
        ):
            DynamicRecipeStripItemView(
                size: size, title: title, description: description, iconPattern: iconPattern,
                tags: tags, operation: operation, selectable: selectable, info: $info
            )
        case .TextCard(
            let size, let title, let description, let iconPattern, let tags,
            let body, let properties, let showProperties, let operations,
            let value, let selectable
        ):
            EmptyView()
        case .ImageCard(
            let size, let title, let description, let iconPattern, let tags,
            let imagePatterns, let properties, let showProperties, let operations,
            let value, let selectable
        ):
            EmptyView()
        }
    }
    
}

struct DynamicRecipeErrorItemView: View {

    var title: String
    var datail: String?
    var value: String?
    var selectable: Bool
    
    @Binding var info: DynamicRecipeViewInfo
    
    @State var isHovered: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.red)
                }
                .frame(width: 30)
                Text("Some errors occurred while executing the recipe")
                .font(.title2)
                .foregroundColor(.red)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                .font(.title3)
                .bold()
                if let datail = datail {
                    Text(datail)
                    .font(.body)
                }
            }
        }
    }
    
}

//import SwiftUI
//
//struct DynamicRecipeErrorView: View {
//
//    var info: DynamicRecipeViewInfo
//
//    var body: some View {
//        VStack {
//            HStack {
//                HStack {
//                    Image(systemName: "exclamationmark.circle.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(.red)
//                }
//                .frame(width: 30)
//                Text("Some errors occurred while executing the recipe")
//                .font(.title2)
//                .foregroundColor(.red)
//            }
//            ScrollView(showsIndicators: false) {
//                VStack {
//                    ForEach(info.items, id: \.title) { item in
//                        VStack(alignment: .leading, spacing: 10) {
//                            Text(item.title)
//                            .font(.title3)
//                            .bold()
//                            if let desc = item.description {
//                                Text(desc)
//                                .font(.body)
//                            }
//                        }
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//
//}

//import SwiftUI
//
//struct UserDefinedRecipeListItemView2: View {
//
//    var item: DynamicRecipeViewInfo.ViewItem
//    var defaultItemIcon: String?
//
//    @State var isSelected: Bool = false
//
//    var body: some View {
//        HStack(spacing: 10) {
//            HStack {
//                (item.icon ?? Image(systemName: "doc.plaintext"))
//                .resizable()
//                .scaledToFit()
//            }
//            .frame(width: Constant.userDefinedRecipeItemHeight*(isSelected ? 0.5 : 0.4))
//            .padding(.leading, 5)
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title)
//                .font(.title3)
////                    .fontWeight(.bold)
//                .foregroundColor(isSelected ? Color.white: Color.black)
//                if let desc = item.description, isSelected {
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        Text(desc)
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                }
//            }
//            Spacer()
//        }
//        .frame(width: Constant.mainWidth-30, height: isSelected ? Constant.userDefinedRecipeItemHeight : Constant.userDefinedRecipeItemHeight-15)
//        .background(isSelected ? Constant.selectedItemBackgroundColor : Constant.mainBackgroundColor)
//        .cornerRadius(5)
//        .onHover { isHovered in
//            withAnimation(.spring(duration: 0.1)) {
//                isSelected = isHovered
//            }
//        }
////        .onTapGesture {
////            for action in item.actions {
////                action.execute()
////            }
////        }
//    }
//
//}

//import SwiftUI
//
//struct DynamicRecipeCardView: View {
//    
//    var data: [Data]
//    var item: DynamicRecipeViewInfo.ViewItem
//    
//    @State var isSelected: Bool = false
//    
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 15)
//                .fill(Color.white)
//                .shadow(radius: 10)
//            HStack {
//                VStack {
//                    VStack(alignment: .leading, spacing: 5) {
//                        HStack {
//                            if let icon = item.icon {
//                                icon
//                                .resizable()
//                                .scaledToFit()
//                            }
//                            Text(item.title)
//                            .font(.title2)
//                            DynamicRecipeCardTagView(item: item)
//                        }
//                        .frame(height: 20)
//                        if let desc = item.description {
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                Text(desc)
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                            }
//                        }
//                    }
//                    Spacer()
//                    ZStack {
//                        TabView {
//                            ForEach(item.images, id: \.self) { pattern in
//                                if pattern == "loading" {
//                                    DynamicRecipeLoadingIconView()
//                                } else {
//                                    if let image = item.patternToImage(pattern: pattern) {
//                                        image
//                                        .resizable()
//                                        .scaledToFit()
//                                    } else {
//                                        Image(systemName: "exclamationmark.triangle.fill")
//                                        .resizable()
//                                        .scaledToFit()
//                                        .foregroundStyle(.yellow)
//                                    }
//                                }
//                            }
//                        }
//                        if isSelected {
//                            HStack {
//                                Spacer()
//                                VStack {
//                                    Spacer()
//                                    ForEach(Array(item.operations.enumerated()), id: \.0) { _, op in
//                                        DynamicRecipeCardButtonView(label: op.name)
//                                            .frame(width: 90, height: 25)
//                                            .offset(x: -5, y: -5)
//                                            .onTapGesture {
//                                                for action in op.actions {
//                                                    action.execute()
//                                                }
//                                            }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                Spacer()
//                ZStack {
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(Constant.commandBarBackgroundColor)
//                    ScrollView(showsIndicators: false) {
//                        VStack(alignment: .leading) {
//                            ForEach(Array(item.properties.enumerated()), id: \.0) { i, p in
//                                HStack {
//                                    Text(p.name)
//                                    .font(.system(.caption2, design: .monospaced))
//                                    .foregroundStyle(.black)
//                                    .bold()
//                                    Spacer()
//                                    Text(p.value)
//                                    .foregroundStyle(.black)
//                                    .font(.system(.body, design: .monospaced))
//                                }
//                            }
//                        }
//                    }
//                    .padding(.top, 8)
//                    .padding(.horizontal, 5)
//                }
//                .frame(width: Constant.mainWidth*0.2)
//            }
//            .padding()
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 10)
//        .frame(height: Constant.userDefinedRecipeItemHeight*6)
//        .onHover { isHovered in
//            withAnimation(.spring(duration: 0.1)) {
//                isSelected = isHovered
//            }
//        }
//    }
//    
//}
//
//struct DynamicRecipeCardButtonView: View {
//
//    var label: String
//    
//    @State var isHovered: Bool = false
//    
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(isHovered ? "B8B9F4".color : "D6D6F9".color, lineWidth: 2)
//                .fill(isHovered ? "F8F8FE".color : .white)
//            Text(label)
//                .font(.body)
//                .foregroundStyle(isHovered ? "27295F".color : "4C4C4C".color)
//                .padding(3)
//        }
//        .onHover { isHovered in
//            self.isHovered = isHovered
//        }
//    }
//    
//}
//
//struct DynamicRecipeCardTagView: View {
//    
//    struct TagView: View {
//        
//        var label: String
//        
//        var body: some View {
//            Text(label)
//            .frame(minWidth: 40)
//            .background(
//                GeometryReader { geometry in
//                    RoundedRectangle(cornerRadius: 5)
//                        .fill("5B5BCF".color)
//                        .frame(width: geometry.size.width+5, height: geometry.size.height+8)
//                        .offset(x: -2.5, y: -4)
//                }
//            )
//            .foregroundStyle(.white)
//        }
//    }
//    
//    var item: DynamicRecipeViewInfo.ViewItem
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack {
//                ForEach(Array(item.tags.enumerated()), id: \.0) { (_, tg) in
//                    TagView(label: tg)
//                }
//                Spacer()
//            }
//            .frame(height: 20)
//            .padding(3)
//        }
//        
//    }
//    
//}
//
//struct DynamicRecipeLoadingIconView: View {
//    
//    @State private var isAnimating = false
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
//            .resizable()
//            .scaledToFit()
//            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
//            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
//        }
//        .onAppear {
//            isAnimating = true
//        }
//    }
//    
//}
