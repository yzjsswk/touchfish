import SwiftUI

struct QuickExecutionView: View {
    
    @State var contexts = [RecipeExecutionContext()]
        
    var body: some View {
        ZStack {
            Constant.mainBackgroundColor
            VStack {
                CommandBarView(situation: Binding<CommandBarView.Situation>(
                    get: { return .QuickExecutionRecipe(contexts[0]) },
                    set: { newValue in
                        if case let .QuickExecutionRecipe(context) = newValue {
                            self.contexts[0] = context
                        }
                    })
                )
                .id("recipe_command_bar_\(contexts[0].uid)")
                RecipeExecutionView(context: $contexts[0], isQuickExecution: true)
                .id("recipe_execution_view_\(contexts[0].uid)")
                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 5)
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
            .shadow(radius: 5)
        )
        .onReceive(NotificationCenter.default.publisher(for: .EscapeKeyWasPressed)) { _ in
            TouchFishApp.quickExecutionWindow.hide()
        }
    }
    
}
