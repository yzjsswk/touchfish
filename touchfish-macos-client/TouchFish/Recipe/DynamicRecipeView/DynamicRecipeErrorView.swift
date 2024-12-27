import SwiftUI

struct DynamicRecipeErrorView: View {
    
    var info: DynamicRecipeViewInfo
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.red)
                }
                .frame(width: 30)
                Text("Some errors occurred while executing the recipe")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(info.items, id: \.title) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(item.title)
                                .font(.title3)
                                .bold()
                            if let desc = item.description {
                                Text(desc)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
}
