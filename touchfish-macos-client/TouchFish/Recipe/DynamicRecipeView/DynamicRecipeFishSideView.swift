import SwiftUI

struct DynamicRecipeFishSideView: View {
    
    @State var fishList: [Fish] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView(showsIndicators: false) {
                ForEach(fishList, id: \.uid) { fish in
                    DynamicRecipeFishSideItemView(fish: fish)
                }
            }
        }
        .padding(5)
        .onAppear {
            Task {
                let fish = await Storage.searchFish()
                self.fishList = fish.values.sorted(by: { $0.updateTime > $1.updateTime })
            }
        }
    }
    
}

struct DynamicRecipeFishSideItemView: View {
    
    var fish: Fish
    
    @State var isHovered: Bool = false
    
    var body: some View {
        HStack {
            HStack {
                fish.fishIcon
                .resizable()
                .scaledToFit()
                .foregroundColor(isHovered ? "27295F".color : Color.black)
            }
            .frame(height: 16)
            if fish.isMarked {
                Text(fish.linePreview)
                    .font(.body)
                    .foregroundColor(isHovered ? Color.black: "222D59".color)
            } else {
                Text(fish.linePreview)
                    .font(.body)
                    .foregroundColor(isHovered ? "666970".color : Color.gray )
            }
            Spacer()
        }
        .padding(5)
        .background(isHovered ? "EEF2FD".color : .clear)
        .cornerRadius(5)
        .frame(height: 20)
        .onHover { isHovered in
            self.isHovered = isHovered
            TouchFishApp.mainWindow.isMovableByWindowBackground = !isHovered
        }
        .onDrag {
            let provider = NSItemProvider(object: NSString(string: fish.identity))
            return provider
        }
    }
    
}
