import SwiftUI

struct DynamicRecipeView: View {
    
    var activeRecipe: Recipe

    @State var dynamicRecipeViewInfo: DynamicRecipeViewInfo?
    
    @State var lastRefreshTime: Date = Date()
    @State var timeCost: Int?
    
    var body: some View {
        VStack {
            if let info = dynamicRecipeViewInfo {
                VStack {
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
                        }.padding(.vertical)
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
                    Spacer()
                    HStack {
                        if info.type == .List || info.type == .Card {
                            Text("\(info.items.count) items")
                            .font(.system(.footnote, design: .monospaced))
                        }
                        Spacer()
                        HStack(spacing: 0) {
                            if let timeCost = timeCost {
                                Text(Functions.descTimeInterval(timeCost))
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
           } else {
               EmptyView()
           }
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
