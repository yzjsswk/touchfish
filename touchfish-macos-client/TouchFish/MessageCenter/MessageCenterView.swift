import SwiftUI

struct MessageCenterView: View {
    
    @State var messages: [MessageCenter.Message] = MessageCenter.shouldShowingMessages
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                HStack {
                    Text("total: \(MessageCenter.showLevelMessageCount)")
                        .font(.custom("Menlo", size: 13))
                        .padding(.horizontal)
                        .padding(.vertical, 3)
                    Spacer()
                    Button(action: {
                        MessageCenter.removeAllHasRead()
                        withAnimation {
                            messages = MessageCenter.shouldShowingMessages
                        }
                    }) {
                        Text("Clear All Read")
                            .font(.title2)
                            .padding(3)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 3)
                }
                Divider()
                .padding(5)
                ForEach(messages, id: \.uid) { msg in
                    MessageView(message: msg)
                }
                if MessageCenter.showLevel == nil {
                    Button(action: {
                        MessageCenter.showCount += 5
                        withAnimation {
                            messages = MessageCenter.shouldShowingMessages
                        }
                    }) {
                        Text("Load More")
                            .font(.title2)
                            .padding(3)
                            .foregroundColor(MessageCenter.showCount >= MessageCenter.messages.count ? .gray : .black)
                    }
                    .padding()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .MessageCenterHasUpdated)) { _ in
            withAnimation {
                messages = MessageCenter.shouldShowingMessages
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
            MessageCenter.showLevel = nil
            for (argName, argValue) in RecipeManager.activeRecipeArg {
                if argName == "level", argValue.count > 0, let level = MessageCenter.Message.MessageLevel(rawValue: argValue[0]) {
                    MessageCenter.showLevel = level
                }
            }
            withAnimation {
                messages = MessageCenter.shouldShowingMessages
            }
        }
        .onDisappear {
            MessageCenter.showCount = max(MessageCenter.showCount, 20)
            MessageCenter.saveToFile()
        }
    }

}

struct MessageView: View {
    
    var message: MessageCenter.Message

    @State var isHovered: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill")
                .foregroundStyle(message.hasRead ? Constant.commandBarBackgroundColor : Constant.unreadMessageTipColor)
                .padding(.leading, 10)
            HStack(spacing: 5) {
                if let source = message.source, let icon = RecipeManager.recipes[source]?.icon {
                    HStack {
                        icon
                        .resizable()
                        .scaledToFit()
                    }
                    .frame(width: 60)
                } else if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    HStack {
                        Image(nsImage: appIcon)
                        .resizable()
                        .scaledToFit()
                    }
                    .frame(width: 60)
                }
                VStack {
                    HStack {
                        Text(message.time)
                            .font(.custom("Menlo", size: 14))
                            .bold()
                            .padding(.vertical, 8)
                        if let title = message.title {
                            Text("- \(title)")
                                .font(.custom("Menlo", size: 13))
                                .bold()
                                .padding(.trailing, 8)
                                .padding(.vertical, 8)
                        }
                        Spacer()
                    }
                    HStack {
                        Text(message.content)
                            .font(.custom("Menlo", size: 12))
                            .foregroundColor(.black)
                            .padding(.bottom, 8)
                        Spacer()
                    }
                }
                Image(systemName: "checkmark.square.fill")
                    .resizable()
                    .foregroundColor(.green)
                    .frame(width: Constant.messageItemHeight*0.75, height: Constant.messageItemHeight*0.75)
                    .padding(.horizontal, 5)
                    .onTapGesture {
                        MessageCenter.remove(uid: message.uid)
                    }
                    .offset(x: isHovered ? 0 : 100, y: 0)
            }
            .background(
                message.level == .info ? Constant.commandBarBackgroundColor : (
                    message.level == .warning ? Functions.makeLinearGradient(colors: [.yellow]) : Constant.errorMessageColor
                )
            )
            .cornerRadius(10)
            .padding(.trailing)
            .padding(.vertical, 3)
        }
        .onHover { isHovered in
            if !message.hasRead {
                MessageCenter.read(uid: message.uid)
            }
            self.isHovered = isHovered
        }
    }
    
}
