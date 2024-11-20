import SwiftUI

struct TopicListView: View {
    
    @State var topics: [Topic] = []
    
    var body: some View {

        VStack {
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach($topics, id: \.uid) { topic in
                        TopicListItemView(topic: topic)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            NotificationCenter.default.post(name: .ShouldRefreshTopic, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRefreshTopic)) { _ in
            Task {
                let topics = await Storage.listTopic()
                withAnimation(.spring(duration: 0.2)) {
                    self.topics = topics.sorted(by: { $0.createTime > $1.createTime })
                }
            }

        }
        
    }
    
}
