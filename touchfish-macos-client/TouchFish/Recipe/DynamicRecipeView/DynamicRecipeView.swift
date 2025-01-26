import SwiftUI

struct DynamicRecipeView: View {
    
    var activeRecipe: Recipe

    @State var dynamicRecipeViewInfo: DynamicRecipeViewInfo?
    
    @State var paraFieldEnbale: Bool = Config.paraFieldEnable
    @State var fishSideEnable: Bool = Config.fishSideEnable
    @State var topicSideEnable: Bool = Config.topicSideEnable
    
    @State var lastRefreshTime: Date = Date(timeIntervalSince1970: 0)
    @State var timeCost: Int?
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                if fishSideEnable {
                    DynamicRecipeFishSideView()
                    .frame(width: Constant.sideWidth)
                    Divider()
                }
                if paraFieldEnbale {
                    DynamicRecipeParaFieldView()
                    .frame(width: Constant.mainWidth * 0.3)
                    .padding(5)
                    Divider()
                }
                if fishSideEnable || paraFieldEnbale {
                    Spacer(minLength: 0)
                }
                if let info = dynamicRecipeViewInfo {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 5) {
                            ForEach(info.items) { item in
                                DynamicRecipeItemView(item: item, info: .constant(info))
                            }
                        }
                        .padding(.vertical)
                    }
//                    switch info.type {
//                    case .Empty:
//                        EmptyView()
//                    case .Error:
//                        DynamicRecipeErrorView(info: info)
//                    case.Text:
//                        VStack {
//                            ForEach(info.items, id: \.title) { item in
//                                Text(item.title)
//                            }
//                        }
//                    case .List:
//                        ScrollView(showsIndicators: false) {
//                            VStack(spacing: 5) {
//                                ForEach(info.items, id: \.title) { item in
//                                    DynamicRecipeListView(data: info.data, item: item)
//                                }
//                            }
//                            .padding(.vertical)
//                        }
//                    case .Card:
//                        ScrollView(showsIndicators: false) {
//                            VStack {
//                                ForEach(info.items, id: \.title) { item in
//                                    DynamicRecipeCardView(data: info.data, item: item)
//                                }
//                            }
//                            .padding(.vertical)
//                        }
//                    }
                } else {
                    EmptyView()
                }
                if topicSideEnable {
                    Spacer()
                    Divider()
                    DynamicRecipeTopicSideView()
                    .frame(width: Constant.sideWidth)
                }
            }
            Spacer()
            HStack {
                HStack(spacing: 10) {
                    DynamicRecipeViewShowFishSideButtonView(fishSideEnable: $fishSideEnable)
                    if let info = self.dynamicRecipeViewInfo, info.items.count > 0 && info.items.count > 0 {
                        DynamicRecipeViewShowParaFieldButtonView(withAnima: true, paraFieldEnable: $paraFieldEnbale)
                    } else {
                        DynamicRecipeViewShowParaFieldButtonView(withAnima: false, paraFieldEnable: $paraFieldEnbale)
                    }
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
        .onAppear {
            if fishSideEnable && topicSideEnable {
                TouchFishApp.mainWindow.setFrame(NSRect(
                    x: TouchFishApp.mainWindow.frame.origin.x - Constant.sideWidth,
                    y: TouchFishApp.mainWindow.frame.origin.y,
                    width: TouchFishApp.mainWindow.frame.width + Constant.sideWidth*2,
                    height: TouchFishApp.mainWindow.frame.height
                ), display: true, animate: false)
            }
            if fishSideEnable && !topicSideEnable {
                TouchFishApp.mainWindow.setFrame(NSRect(
                    x: TouchFishApp.mainWindow.frame.origin.x - Constant.sideWidth,
                    y: TouchFishApp.mainWindow.frame.origin.y,
                    width: TouchFishApp.mainWindow.frame.width + Constant.sideWidth,
                    height: TouchFishApp.mainWindow.frame.height
                ), display: true, animate: false)
            }
            if !fishSideEnable && topicSideEnable {
                TouchFishApp.mainWindow.setFrame(NSRect(
                    x: TouchFishApp.mainWindow.frame.origin.x,
                    y: TouchFishApp.mainWindow.frame.origin.y,
                    width: TouchFishApp.mainWindow.frame.width + Constant.sideWidth,
                    height: TouchFishApp.mainWindow.frame.height
                ), display: true, animate: false)
            }
        }
        .onChange(of: fishSideEnable) {
            if fishSideEnable {
                TouchFishApp.mainWindow.setFrame(NSRect(
                    x: TouchFishApp.mainWindow.frame.origin.x - Constant.sideWidth,
                    y: TouchFishApp.mainWindow.frame.origin.y,
                    width: TouchFishApp.mainWindow.frame.width + Constant.sideWidth,
                    height: TouchFishApp.mainWindow.frame.height
                ), display: true, animate: true)
            } else {
                TouchFishApp.mainWindow.setFrame(NSRect(
                    x: TouchFishApp.mainWindow.frame.origin.x + Constant.sideWidth,
                    y: TouchFishApp.mainWindow.frame.origin.y,
                    width: TouchFishApp.mainWindow.frame.width - Constant.sideWidth,
                    height: TouchFishApp.mainWindow.frame.height
                ), display: true, animate: true)
            }
        }
        .onChange(of: topicSideEnable) {
            if topicSideEnable {
                TouchFishApp.mainWindow.setFrame(NSRect(
                    x: TouchFishApp.mainWindow.frame.origin.x,
                    y: TouchFishApp.mainWindow.frame.origin.y,
                    width: TouchFishApp.mainWindow.frame.width + Constant.sideWidth,
                    height: TouchFishApp.mainWindow.frame.height
                ), display: true, animate: true)
            } else {
                TouchFishApp.mainWindow.setFrame(NSRect(
                    x: TouchFishApp.mainWindow.frame.origin.x,
                    y: TouchFishApp.mainWindow.frame.origin.y,
                    width: TouchFishApp.mainWindow.frame.width - Constant.sideWidth,
                    height: TouchFishApp.mainWindow.frame.height
                ), display: true, animate: true)
            }
        }
        .onDisappear {
            TouchFishApp.mainWindow.setFrame(NSRect(
                x: TouchFishApp.mainWindow.frame.origin.x + (fishSideEnable ? Constant.sideWidth : 0),
                y: TouchFishApp.mainWindow.frame.origin.y,
                width: Constant.mainWidth,
                height: Constant.mainHeight
            ), display: true, animate: false)
        }
    }
    
}

struct DynamicRecipeViewShowParaFieldButtonView: View {
    
    var withAnima: Bool = true
    
    @State var isHovered: Bool = false
    @Binding var paraFieldEnable: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "square.split.2x1.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(paraFieldEnable ? "27295F".color : .gray)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isHovered ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 5)
            )
        }
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .onTapGesture {
            if withAnima {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.paraFieldEnable.toggle()
                }
            } else {
                self.paraFieldEnable.toggle()
            }
            Config.paraFieldEnable = paraFieldEnable
            let _ = Config.save()

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
            .foregroundStyle(fishSideEnable ? "27295F".color : .gray)
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
                Config.fishSideEnable = fishSideEnable
                let _ = Config.save()
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
            .foregroundStyle(topicSideEnable ? "27295F".color : .gray)
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
                Config.topicSideEnable = topicSideEnable
                let _ = Config.save()
            }
        }
    }
    
}
