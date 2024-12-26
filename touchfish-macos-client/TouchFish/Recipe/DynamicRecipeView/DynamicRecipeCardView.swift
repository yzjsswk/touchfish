import SwiftUI

struct DynamicRecipeCardView: View {
    
    var data: [Data]
    var item: DynamicRecipeViewInfo.DynamicRecipeViewItem
    
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
                    TabView {
                        ForEach(item.images, id: \.self) { image in
                            (item.patternToImage(pattern: image) ?? Image(systemName: "doc.plaintext"))
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
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
//        .background(Constant.mainBackgroundColor)
//        .cornerRadius(5)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                isSelected = isHovered
            }
        }
        .onTapGesture {
            for action in item.actions {
                action.execute()
            }
        }
    }
    
}
