import SwiftUI

struct DynamicRecipeParaFieldView: View {
    
    @State var commandBarText: String = CommandManager.commandText
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill("C6C7F4".color)
                HStack(spacing: 3) {
                    HStack {
                        Image(systemName: "clear")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle("27295F".color)
                    }
                    .frame(width: 25, height: 20)
                    Spacer()
                    HStack {
                        Image(systemName: "play.square")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle("27295F".color)
                    }
                    .frame(width: 25, height: 20)
                }
                .padding(.horizontal, 5)
                
            }
            .padding(.horizontal, 3)
            .frame(height: 40)
            ScrollView {
                VStack {
                    HStack {
                        Text("Command Bar Text")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    .padding(2)
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke("A1A9C6".color, lineWidth: 3)
                        VStack {
                            Spacer()
                            TextEditor(text: $commandBarText)
                                .font(.custom("Menlo", size: 16))
                            Spacer()
                        }.padding(.horizontal, 5)
                    }
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(height: Constant.mainWidth*0.12)
                    Divider()
                    if let recipe = RecipeManager.activeRecipe {
                        ForEach(Array(recipe.parameters.enumerated()), id: \.0) { idx, para in
                            HStack {
                                Text(para.name)
                                    .font(.title3)
                                    .bold()
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            HStack{
                                Text("the language of the application")
                                    .font(.callout)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            Divider()
                        }
                    }
                }
            }
            .padding(5)
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandTextChanged)) { notification in
            if let commandText = notification.userInfo?["commandText"] as? String {
                self.commandBarText = commandText
            }
        }
        .onChange(of: commandBarText) { _, new in
            NotificationCenter.default.post(name: .CommandTextChanged, object: nil, userInfo: ["commandText":new])
        }
    }
}
