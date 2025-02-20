import SwiftUI

struct DynamicRecipeTopicSideView: View {
    
    @State var topics: [Topic] = []
    @State var selectedTopic: Topic?
    
    var body: some View {
        VStack {
            if let selectedTopic = selectedTopic {
                DynamicRecipeTopicSideTopicItemView(topic: selectedTopic, unreadMessageCount: selectedTopic.unreadCount, isSelected: true)
                .id(selectedTopic.uid)
                .onTapGesture {
                    withAnimation {
                        self.selectedTopic = nil
                    }
                }
                .transition(.move(edge: .bottom))
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 7) {
                        ForEach(selectedTopic.messages.sorted(by: { $0.createTime > $1.createTime }), id: \.uid) { message in
                            DynamicRecipeTopicSideMessageItemView(message: message, topicUid: selectedTopic.uid)
                        }
                    }
                    .padding(.vertical, 3)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    ForEach(topics, id: \.uid) { topic in
                        DynamicRecipeTopicSideTopicItemView(topic: topic, unreadMessageCount: topic.unreadCount)
                        .id(topic.uid)
                        .onTapGesture {
                            withAnimation {
                                self.selectedTopic = topic
                            }
                        }
                        .transition(.move(edge: .top))
                    }
                }
            }
        }
        .onAppear {
            NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRefreshTopic)) { _ in
            Task {
                let topics = await Storage.listTopic()
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.topics = topics.sorted(by: { $0.createTime < $1.createTime })
                    if let selectedTopic = selectedTopic {
                        for topic in topics {
                            if topic.uid == selectedTopic.uid {
                                self.selectedTopic = topic
                            }
                        }
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeTopicSideMessageItemView: View {
    
    var message: Message
    var topicUid: String
    
    @State var readEnable: Bool = false
    
    var backgroundColor: Color {
        switch message.level {
        case .Info:
            return "EEF2FD".color
        case .Warning:
            return "FFF9E6".color
        case .Error:
            return "FDEDED".color
        }
    }
    
    var titleColor: Color {
        switch message.level {
        case .Info:
            return "5B5BCF".color
        case .Warning:
            return "D48806".color
        case .Error:
            return "C62828".color
        }
    }
    
    var borderColor: Color {
        switch message.level {
        case .Info:
            return "C6C7F4".color
        case .Warning:
            return "FFE08A".color
        case .Error:
            return "F8B4B4".color
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .stroke(borderColor, lineWidth: 1)
            HStack {
                VStack(alignment: .leading) {
                    Text(message.title)
                    .font(.system(size: 13))
                    .foregroundStyle(message.hasRead ? .gray : titleColor)
                    Text(message.createTime)
                    .font(.callout)
                    .foregroundStyle(message.hasRead ? .gray : "6C757D".color)
                    Text(message.body)
                    .font(.system(size: 12))
                    .foregroundStyle(message.hasRead ? .gray : "212529".color)
                }
                Spacer()
            }
            .padding(5)
        }
        .padding(.horizontal, 6)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                readEnable = true
            }
        }
        .onHover { isHovered in
            if isHovered && !message.hasRead && readEnable {
                Task {
                    let _ = await Storage.readMessage(topicUid: topicUid, messageUid: message.uid)
                    NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                }
            }
        }
    }
    
}

struct DynamicRecipeTopicSideTopicItemView: View {
    
    var topic: Topic
    var unreadMessageCount: Int
    
    var isSelected: Bool = false
    
    @State var isHovered: Bool = false
    @State var unReadCircleBouncing = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
            .fill((isHovered || isSelected) ? "C6C7F4".color : "EEF2FD".color)
            HStack {
                HStack {
                    getTopicIcon(source: topic.source)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle("27295F".color)
                }
                .frame(width: 30, height: 30)
                .padding(.leading, 5)
                VStack {
                    HStack {
                        Text(topic.title)
                        .foregroundStyle("27295F".color)
                        Spacer()
                        if topic.unreadCount > 0 {
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Constant.unreadMessageTipColor)
                                Text(String(topic.unreadCount))
                                    .font(.custom("Menlo", size: 9))
                                    .foregroundStyle(.white)
                            }
                            .padding([.top, .trailing], -3)
                            .offset(x: unReadCircleBouncing ? -2 : -3, y: unReadCircleBouncing ? -7 : 3)
                            .scaleEffect(unReadCircleBouncing ? 1.2 : 1.0)
                            .animation(
                                Animation.interpolatingSpring(stiffness: 200, damping: 5).repeatCount(1),
                                value: unReadCircleBouncing
                            )
                        }
                    }
                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(Color.blue)
                            .frame(width: 10, height: 10)
                            Text("\(topic.infoCount)")
                            .font(.callout)
                            .foregroundStyle("666970".color)
                            Circle().fill(Color.yellow)
                            .frame(width: 10, height: 10)
                            Text("\(topic.warningCount)")
                            .font(.callout)
                            .foregroundStyle("666970".color)
                            Circle().fill(Color.red)
                            .frame(width: 10, height: 10)
                            Text("\(topic.errorCount)")
                            .font(.callout)
                            .foregroundStyle("666970".color)
                        }
                        Spacer()
                        Text("\(topic.messages.count) messages")
                        .font(.callout)
                        .foregroundStyle("666970".color)
                    }
                }
            }
            .padding(.leading, 1)
            .padding(.vertical, 5)
            .padding(.trailing, 5)
        }
        .frame(height: 40)
        .padding(5)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .onChange(of: unreadMessageCount) { old, new in
            if new > old {
                unReadCircleBouncing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    unReadCircleBouncing = false
                }
            }
        }
    }
    
}

private func getTopicIcon(source: String) -> Image {
    if let icon = RecipeManager.recipes[source]?.icon {
        return icon
    }
    for recipes in RecipeManager.allRecipes.values {
        for recipe in recipes {
            if let dotIndex = recipe.bundleId.firstIndex(of: ".") {
                let startIndex = recipe.bundleId.index(after: dotIndex)
                let noServerBundleId = String(recipe.bundleId[startIndex...])
                if source == noServerBundleId {
                    return recipe.icon
                }
            }
        }
    }
    if let appIcon = NSImage(named: NSImage.applicationIconName) {
        return Image(nsImage: appIcon)
    }
    return Image(systemName: "questionmark")
}
