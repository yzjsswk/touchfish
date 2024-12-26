import SwiftUI

struct DynamicRecipeView: View {
    
    var activeRecipe: Recipe

    @State var dynamicRecipeViewInfo: DynamicRecipeViewInfo?
    
    @State var lastRefreshTime: Date = Date()
    @State var timeCost: Int?
    
    var body: some View {
        VStack {
            switch activeRecipe.type {
            case .Task, .Commit:
                EmptyView()
            case .View:
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
                                Text("total: \(info.items.count)")
                                    .font(.system(.footnote, design: .monospaced))
                            }
                            Spacer()
                            HStack(spacing: 0) {
                                if let timeCost = timeCost {
                                    Text("timeCost: ")
                                        .font(.system(.footnote, design: .monospaced))
                                    Text("\(timeCost)")
                                        .font(.system(.footnote, design: .monospaced))
                                        .foregroundStyle(timeCost < 200 ? .green : (timeCost < 500 ? .yellow : .red))
                                    Text(" ms")
                                        .font(.system(.footnote, design: .monospaced))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
               } else {
                   EmptyView()
               }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .DynamicRecipeViewChanged)) { notification in
            if let timeCost = notification.userInfo?["timeCost"] as? Int {
                self.timeCost = timeCost
            }
            if let startTime = notification.userInfo?["startTime"] as? Date,
               let info = notification.userInfo?["info"] as? DynamicRecipeViewInfo {
                if startTime > self.lastRefreshTime {
                    withAnimation(.spring) {
                        self.dynamicRecipeViewInfo = info
                    }
                }
                self.lastRefreshTime = startTime
            }
        }
    }
    
}
