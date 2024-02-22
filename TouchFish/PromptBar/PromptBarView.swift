import SwiftUI

struct PromptBarView: View {
    
    @Binding var text: String
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                SearchTextField(text: $text)
                    .padding([.leading, .trailing], 8)
                Spacer()
            }
            .frame(height: Config.it.promptBarHeight)
        }
        .background(Config.it.promptBarBackgroundColor.color)
        .cornerRadius(10)
        .padding(10)
    }
}
