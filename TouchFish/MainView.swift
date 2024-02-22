import SwiftUI
import Foundation

struct MainView: View {
    
    @State private var text = ""
    @State private var viewState = 0
    @State private var fishList: [Fish] = []
    
    var body: some View {
        ZStack {
            Config.it.mainBackgroundColor.color
//                .blur(radius: 5)
//                .shadow(color: .black, radius: 10)
//                .colorMultiply(Config.it.mainBackgroundColor.color)
            VStack {
                PromptBarView(text: $text)
                switch viewState {
                case 1:
                    FishRepositoryView(fishList: fishList)
                case 2:
                    WebBrowserView(text: $text)
                default:
                    ProcessView(processList: PromptManager.exec(prompt: text))
                }
                Spacer()
            }
        }
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.1), lineWidth: 1))
        .onAppear {
            fishList = Cache.FishCache.fishList
        }
        .onChange(of: text) { _ in
            if viewState == 0 && text.starts(with: "bm ") {
                viewState = 2
            }
            if viewState == 2 && !text.starts(with: "bm ") {
                viewState = 0
            }
            if viewState == 1 {
                Cache.FishCache.valueOrDesc = text
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldShowFishView)) { _ in
            viewState = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .EscapeKeyWasPressed)) { _ in
            viewState = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldRefreshFishList)) { _ in
            withAnimation {
                fishList = Cache.FishCache.fishList
            }
        }
    }
    
}
