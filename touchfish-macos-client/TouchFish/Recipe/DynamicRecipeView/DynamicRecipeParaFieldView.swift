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
                        Image(systemName: "delete.left")
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
            .frame(height: 32)
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
                            Spacer(minLength: 0)
                            TextEditor(text: $commandBarText)
                                .font(.custom("Menlo", size: 16))
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 2)
                    }
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(height: Constant.mainWidth*0.12)
                    Divider()
                    if let recipe = RecipeManager.activeRecipe {
                        ForEach(Array(recipe.parameters.enumerated()), id: \.0) { _, para in
                            DynamicRecipeParaInputView(para: para)
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

struct DynamicRecipeParaInputView: View {
    
    var para: Recipe.Parameter
    
    var body: some View {
        HStack {
            Text(para.name)
                .font(.title3)
                .bold()
            Spacer()
        }
        .padding(.vertical, 2)
        if let desc = para.description {
            HStack{
                Text(desc)
                    .font(.callout)
                    .foregroundStyle(.gray)
                Spacer()
            }
        }
        switch para.inputer {
        case .SingleLineEdit:
            DynamicRecipeSingleLineEditView(name: para.name)
        case .MultLineEdit:
            DynamicRecipeMultLineEditView(name: para.name)
        }
    }
    
}

struct DynamicRecipeSingleLineEditView: View {
    
    var name: String
    
    @State var value: String = ""
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke("A1A9C6".color, lineWidth: 3)
            VStack {
                Spacer(minLength: 0)
                TextField("", text: $value)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.custom("Menlo", size: 16))
                Spacer(minLength: 0)
            }
            .padding(5)
        }
        .background(Color.white)
        .cornerRadius(5)
        .onChange(of: value) {
            if value == "" {
                RecipeManager.delArg(key: name)
            } else {
                RecipeManager.modifyArg(key: name, value: value)
            }
        }
    }
    
}

struct DynamicRecipeMultLineEditView: View {
    
    var name: String
    
    @State var value: String = ""
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke("A1A9C6".color, lineWidth: 3)
            VStack {
                Spacer(minLength: 0)
                TextEditor(text: $value)
                    .font(.custom("Menlo", size: 16))
                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 2)
        }
        .background(Color.white)
        .cornerRadius(5)
        .frame(height: Constant.mainWidth*0.12)
        .onChange(of: value) {
            if value == "" {
                RecipeManager.delArg(key: name)
            } else {
                RecipeManager.modifyArg(key: name, value: value)
            }
        }
    }
    
}
