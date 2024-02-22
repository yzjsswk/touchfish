import SwiftUI

struct FishFilterView: View {
    
    @State private var typeFilterCheck: [Bool] = []
    @State private var sourceFilterCheck: [Bool] = []
    @State private var tagFilterCheck: [Bool] = []
    private var tagCheckIndexMap: [String:Int] = [:]
    
    init() {
        var typeFilterCheck: [Bool] = []
        for _ in FishType.allCases {
            typeFilterCheck.append(false)
        }
        for t in Cache.FishCache.type ?? [] {
            typeFilterCheck[t.index!] = true
        }
        self._typeFilterCheck = State(initialValue: typeFilterCheck)
        
        var sourceFilterCheck: [Bool] = []
        for _ in Source.allCases {
            sourceFilterCheck.append(false)
        }
        for s in Cache.FishCache.source ?? [] {
            sourceFilterCheck[s.index!] = true
        }
        self._sourceFilterCheck = State(initialValue: sourceFilterCheck)
        
        var tagFilterCheck: [Bool] = []
        Cache.TagCache.refresh()
        for (tg, _) in Cache.TagCache.tagMap.sorted(by: { $0.key < $1.key }) {
            tagFilterCheck.append(Cache.FishCache.tag?.contains(tg) ?? false)
            tagCheckIndexMap[tg] = tagFilterCheck.count - 1
        }
        self._tagFilterCheck = State(initialValue: tagFilterCheck)
    }
    
    var body: some View {
        ScrollView {
            VStack() {
                
                HStack {
                    Text("Type")
                        .font(.title2)
                    Spacer()
                }
                .padding()
                VStack(alignment: .leading) {
                    ForEach(0..<FishType.allCases.count) { idx in
                        Toggle(isOn: $typeFilterCheck[idx]) {
                            Text(FishType.allCases[idx].rawValue)
                        }
                        .onChange(of: typeFilterCheck[idx]) { _ in
                            if typeFilterCheck.allSatisfy( {$0 == false} ) {
                                Cache.FishCache.type = nil
                            } else {
                                var filteredTypes: [FishType] = []
                                for (i, check) in typeFilterCheck.enumerated() {
                                    if check {
                                        filteredTypes.append(FishType.allCases[i])
                                    }
                                }
                                Cache.FishCache.type = filteredTypes
                            }
                        }
                    }
                }
                
                HStack {
                    Text("Source")
                        .font(.title2)
                    Spacer()
                }
                .padding()
                VStack(alignment: .leading) {
                    ForEach(0..<Source.allCases.count) { idx in
                        Toggle(isOn: $sourceFilterCheck[idx]) {
                            Text(Source.allCases[idx].rawValue)
                        }
                        .onChange(of: sourceFilterCheck[idx]) { _ in
                            if sourceFilterCheck.allSatisfy( {$0 == false} ) {
                                Cache.FishCache.source = nil
                            } else {
                                var filteredSources: [Source] = []
                                for (i, check) in sourceFilterCheck.enumerated() {
                                    if check {
                                        filteredSources.append(Source.allCases[i])
                                    }
                                }
                                Cache.FishCache.source = filteredSources
                            }
                        }
                    }
                }
                
                HStack {
                    Text("Tag")
                        .font(.title2)
                    Spacer()
                }
                .padding()
                VStack(alignment: .leading) {
                    ForEach(tagCheckIndexMap.sorted(by: { $0.key < $1.key }), id: \.key) { tg, idx in
                        Toggle(isOn: $tagFilterCheck[idx]) {
                            Text(tg)
                        }
                        .onChange(of: tagFilterCheck[idx]) { _ in
                            
                            if tagFilterCheck.allSatisfy( {$0 == false} ) {
                                Cache.FishCache.tag = nil
                            } else {
                                var filteredTags: [String] = []
                                for (tg, idx) in tagCheckIndexMap {
                                    if tagFilterCheck[idx] {
                                        filteredTags.append(tg)
                                    }
                                }
                                Cache.FishCache.tag = filteredTags
                            }
                        }
                    }
                }
                
            }
        }
        .onAppear {

        }
    }
    
}
