import SwiftUI

struct HomeView: View {
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                Text("Welcome!")
                .font(.title)
                .padding(10)
                Divider()
                StatsView()
                .padding(10)
            }
        }
        .cornerRadius(10)
        .padding(10)
    }
    
}
