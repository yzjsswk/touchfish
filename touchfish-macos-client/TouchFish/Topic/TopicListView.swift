import SwiftUI

struct TopicListView: View {
    
    @Binding var topics: [Topic]
    
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
        
    }
    
}
