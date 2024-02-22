import SwiftUI

struct ProcessListView: View {
    
    var processList: [Process]
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
                        ], spacing: 20)  {
                            ForEach(processList, id: \.id) { process in
                                ProcessItemView(
                                    name: process.name,
                                    desc: process.desc,
                                    icon: process.icon,
                                    command: process.command
                                )
                                .onTapGesture(count: 1, perform: process.action)
                            }
                        }
                        .padding()
                    }
                    
        }
    }
    
}
