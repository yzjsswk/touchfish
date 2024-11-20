import SwiftUI

struct TopicListItemView: View {
    
    @Binding var topic: Topic

    @State var isOpening: Bool = false
    
    var body: some View {
        VStack {
            HStack(spacing: 5) {
                HStack {
                    Image(systemName: isOpening ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Constant.selectedItemBackgroundColor)
                }
                .frame(width: 10)
                .padding(.horizontal, 8)
                HStack {
                    getTopicIcon(source: topic.source)
                    .resizable()
                    .scaledToFit()
                }
                .frame(width: 40, height: 40)
                .padding(.vertical, 5)
                Text("\(topic.title)")
                    .font(.title3)
                    .bold()
                    .padding(.vertical, 8)
                Text("(\(topic.messages.count) messages)")
                    .font(.title3)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
                Spacer()
                let unreadCount = topic.messages.filter {!$0.hasRead}.count
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                        .fill(Constant.unreadMessageTipColor)
                        Text(String(unreadCount))
                        .font(.custom("Menlo", size: 12))
                        .foregroundStyle(.white)
                    }
                    .frame(width: 30, height: 30)
                    .padding(.trailing, 8)
                }
                if isOpening {
                    if unreadCount > 0 {
                        ReadAllMessageButtonView()
                        .padding(.trailing, 8)
                        .onTapGesture {
                            Task {
                                for message in topic.messages {
                                    let _ = await Storage.readMessage(topicUid: topic.uid, messageUid: message.uid)
                                }
                                NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                            }
                        }
                    }
                    RemoveTopicButtonView()
                    .padding(.trailing, 8)
                    .onTapGesture {
                        Task {
                            await Storage.removeTopic(subject: topic.subject)
                            NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                        }
                    }
                }
            }
            .background(Constant.commandBarBackgroundColor)
            .cornerRadius(10)
            .onTapGesture {
                withAnimation(.spring(duration: 0.4)) {
                    isOpening.toggle()
                }
            }
            if isOpening {
                VStack {
                    ForEach(topic.messages.sorted(by: { $0.createTime > $1.createTime }), id: \.uid) { message in
                        TopicListMessageItemView(topicUid: topic.uid, message: message)
                    }
                }
            }
        }
    }
    
}

struct TopicListMessageItemView: View {
    
    var topicUid: String
    var message: Message

    @State var isHovered: Bool = false
    
    var body: some View {
        HStack {
            HStack {
                Circle()
                .fill(message.hasRead ? Functions.makeLinearGradient(colors: ["F0F1FD"]) : Constant.selectedItemBackgroundColor)
            }
            .frame(width: 10, height: 10)
            VStack {
                HStack {
                    Text(message.createTime)
                        .font(.custom("Menlo", size: 14))
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.leading, 5)
                        .padding(.trailing, 3)
                    Text("- \(message.title)")
                        .font(.custom("Menlo", size: 13))
                        .bold()
                        .padding(.trailing, 5)
                    Spacer()
                }
                HStack {
                    Text(message.body)
                        .font(.custom("Menlo", size: 12))
                        .foregroundColor(.black)
                        .padding(.bottom, 5)
                        .padding(.leading, 5)
                    Spacer()
                }
                
            }
            .background(
                message.level == .Info ? Functions.makeLinearGradient(colors: ["F0F1FD"], start: .leading, end: .trailing) : (
                    message.level == .Warning ? Functions.makeLinearGradient(colors: [.yellow], start: .leading, end: .trailing) :
                        Functions.makeLinearGradient(colors: ["DA5448"], start: .leading, end: .trailing)
                )
            )
            .cornerRadius(10)
            .frame(width: Constant.mainWidth*0.92)
            .onHover { isHovered in
                if !message.hasRead {
                    Task {
                        let _ = await Storage.readMessage(topicUid: topicUid, messageUid: message.uid)
                        NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
                    }
                }
                self.isHovered = isHovered
            }
        }
        .padding(.leading, 5)
    }
    
}

struct RemoveTopicButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "trash.fill" : "trash")
                .resizable()
                .scaledToFit()
                .foregroundStyle("27295F".color)
        }
        .frame(width: 25, height: 25)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct ReadAllMessageButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "checkmark.circle.fill" : "checkmark.circle")
                .resizable()
                .scaledToFit()
                .foregroundStyle("27295F".color)
        }
        .frame(width: 25, height: 25)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

private func getTopicIcon(source: String) -> Image {
    if let icon = RecipeManager.recipes[source]?.icon {
        return icon
    }
    if let appIcon = NSImage(named: NSImage.applicationIconName) {
        return Image(nsImage: appIcon)
    }
    return Image(systemName: "questionmark")
}
