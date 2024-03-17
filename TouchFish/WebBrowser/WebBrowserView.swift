import SwiftUI

struct WebBrowserView: View {
    
    @Binding var text: String
    @State var webURLs: [(Int, String, String)] = []
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(webURLs, id: \.0) { id, desc, url in
                        ListItemView(
                            name: desc,
                            desc: url,
                            isSelected: false,
                            icon: Image(systemName: "link")
//                            icon: Image(nsImage: NSImage(named: "baidu")!)
                        ) {
                            //                        NSWorkspace.shared.open(URL(string: url)!)
                            TouchFishApp.deactivate()
                            AppleScriptRunner.openWebUrl(with: "Google Chrome", url: url)
                        }
                        .frame(width: Config.it.mainWidth - 30, height: Config.it.webURLItemHeight)
                    }
                }
            }
            Text("total count: \(String(webURLs.count))").font(.footnote)
        }
        .onAppear {
            var newWebURLs: [(Int, String, String)] = []
            let ws = text.split(separator: " ")
            if ws.count < 1 || ws[0] != "bm" || text == "bm" {
                return
            }
            let res = ws.count == 1 ? DB.searchFish(type: [.text], tag: ["weburl"], limitNum: 300) :
            DB.searchFish(valueOrDesc: String(ws[1]), type: [.text], tag: ["weburl"], limitNum: 300)
            for r in res {
                var detail = ""
                for t in r.tag {
                    if t == "weburl" {
                        continue
                    }
                    detail += "[\(t)]"
                }
                detail += r.value
                newWebURLs.append((r.id, r.description, detail))
            }
//            withAnimation {
            webURLs = newWebURLs
//            }
        }
        .onChange(of: text) { _ in
            var newWebURLs: [(Int, String, String)] = []
            let ws = text.split(separator: " ")
            if ws.count < 1 || ws[0] != "bm" || text == "bm" {
                return
            }
            let res = ws.count == 1 ? DB.searchFish(type: [.text], tag: ["weburl"], limitNum: 300) :
            DB.searchFish(valueOrDesc: String(ws[1]), type: [.text], tag: ["weburl"], limitNum: 300)
            for r in res {
                var detail = ""
                for t in r.tag {
                    if t == "weburl" {
                        continue
                    }
                    detail += "[\(t)]"
                }
                detail += r.value
                newWebURLs.append((r.id, r.description, detail))
            }
//            withAnimation {
            webURLs = newWebURLs
//            }
        }
    }

}
