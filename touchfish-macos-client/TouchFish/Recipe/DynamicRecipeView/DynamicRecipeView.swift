import SwiftUI

struct DynamicRecipeView: View {
    
    var activeRecipe: Recipe

    @State var dynamicRecipeViewInfo: DynamicRecipeViewInfo?
    
    @State var paraFieldEnbale: Bool = false
    @State var fishSideEnable: Bool = false
    @State var topicSideEnable: Bool = false
    
    @State var lastRefreshTime: Date = Date(timeIntervalSince1970: 0)
    @State var timeCost: Int?
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                if paraFieldEnbale {
                    DynamicRecipeParaFieldView()
                        .frame(width: Constant.mainWidth * 0.3)
                        .padding(5)
                    Divider()
                    Spacer(minLength: 0)
                }
                if let info = dynamicRecipeViewInfo {
                    switch info.type {
                    case .Empty:
                        EmptyView()
                    case .Error:
                        DynamicRecipeErrorView(info: info)
                    case.Text:
                        VStack {
                            ForEach(info.items, id: \.title) { item in
                                Text(item.title)
                            }
                        }
                    case .List:
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 5) {
                                ForEach(info.items, id: \.title) { item in
                                    DynamicRecipeListView(data: info.data, item: item)
                                }
                            }
                            .padding(.vertical)
                        }
                    case .Card:
                        ScrollView(showsIndicators: false) {
                            VStack {
                                ForEach(info.items, id: \.title) { item in
                                    DynamicRecipeCardView(data: info.data, item: item)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                } else {
                    EmptyView()
                }
            }
            Spacer()
            HStack {
                HStack(spacing: 10) {
                    DynamicRecipeViewShowFishSideButtonView(fishSideEnable: $fishSideEnable)
                    DynamicRecipeViewShowParaFieldButtonView(paraFieldEnable: $paraFieldEnbale)
                    DynamicRecipeViewShowTopicSideButtonView(topicSideEnable: $topicSideEnable)
                }
                .frame(height: 16)
                Spacer()
                if let info = dynamicRecipeViewInfo {
                    HStack(spacing: 20) {
                        if info.type == .List || info.type == .Card {
                            Text("\(info.items.count) items")
                                .font(.callout)
                                .foregroundStyle(.gray)
                        }
                        if let timeCost = timeCost {
                            Text(Functions.descTimeInterval(timeCost))
                                .font(.callout)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .onReceive(NotificationCenter.default.publisher(for: .DynamicRecipeViewChanged)) { notification in
            if let startTime = notification.userInfo?["executeTime"] as? Date,
               let info = notification.userInfo?["info"] as? DynamicRecipeViewInfo {
                if startTime >= self.lastRefreshTime {
                    if let timeCost = notification.userInfo?["timeCost"] as? Int {
                        self.timeCost = timeCost
                    }
                    self.lastRefreshTime = startTime
                    withAnimation(.spring) {
                        self.dynamicRecipeViewInfo = info
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeViewShowParaFieldButtonView: View {
    
    @State var isHovered: Bool = false
    @Binding var paraFieldEnable: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "square.split.2x1.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(paraFieldEnable ? .black : .gray)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isHovered ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 5)
            )
        }
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.paraFieldEnable.toggle()
            }
        }
    }
    
}

struct DynamicRecipeViewShowFishSideButtonView: View {
    
    @State var isHovered: Bool = false
    @Binding var fishSideEnable: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "square.lefthalf.filled")
            .resizable()
            .scaledToFit()
            .foregroundStyle(fishSideEnable ? .black : .gray)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isHovered ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 5)
            )
        }
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.fishSideEnable.toggle()
            }
        }
    }
    
}

struct DynamicRecipeViewShowTopicSideButtonView: View {
    
    @State var isHovered: Bool = false
    @Binding var topicSideEnable: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "square.righthalf.filled")
            .resizable()
            .scaledToFit()
            .foregroundStyle(topicSideEnable ? .black : .gray)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isHovered ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 5)
            )
        }
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.topicSideEnable.toggle()
            }
        }
    }
    
}
