import SwiftUI

struct CommandBarView: View {
    
    enum Situation {
        case NotRecipe
        case MainWindowRecipe(RecipeExecutionContext)
        case QuickExecutionRecipe(RecipeExecutionContext)
    }
    
    let uid = UUID()
    @State var contextUid: UUID? = nil
    
    @State var text: String = ""
    @State var cells: [String] = []
    @State var placeHolder: String = ""
    @State var lastEditTime = Date()
    
    @Binding var situation: Situation
    
    @FocusState var isFocused: Bool
    
    @State var openTextField: Bool = false
    
    var body: some View {
        ZStack {
            HStack {
                if !openTextField {
                    ForEach(Array(cells.enumerated()), id: \.0) { idx, cellText in
                        Text(getCellText(originText: cellText))
                            .background(
                                GeometryReader { geometry in
                                    Rectangle()
                                        .cornerRadius(5)
                                        .foregroundStyle(idx == 0 ? "5B5BCF".color : "C6C7F4".color)
                                        .frame(width: geometry.size.width+5, height: geometry.size.height+8)
                                        .offset(x: -2.5, y: -4)
                                }
                            )
                            .foregroundColor(idx == 0 ? .white : "666970".color)
                            .font(.custom("Menlo", size: 16))
                            .padding([.leading], 3)
                    }
                }
                ZStack {
                    CommandBarTextField(text: $text, openTextField: $openTextField)
                        .frame(height: openTextField ? 88 : Constant.commandFieldHeight)
                    .offset(y: isFocused ? 2 : 8.8)
                    .focused($isFocused)
                    if text.count == 0 {
                        HStack {
                            Text(placeHolder)
                            .font(.custom("Menlo", size: 20))
                            .foregroundStyle("A3A3A3".color)
                            .offset(x: 3, y: 1)
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    openTextField = true
                                }
                            }
                            .onTapGesture {
                                isFocused = true
                            }
                            Spacer()
                        }
                    }
                    if openTextField {
                        TextEditor(text: $text)
                        .font(.custom("Menlo", size: 14))
                        .scrollContentBackground(.hidden)
                        .background(Constant.commandBarBackgroundColor)
                        .cornerRadius(10)
                        .focused($isFocused)
                        .padding(5)
                        .padding(.leading, -6)
                    }
                }
                switch situation {
                case .NotRecipe:
                    EmptyView()
                case .MainWindowRecipe(let context),  .QuickExecutionRecipe(let context):
                    if context.activeRecipe != nil {
                        CommitRecipeButtonView(recipeExecutionContext: context)
                        .padding(.trailing, 5)
                    }
                }
            }
            .padding([.leading], 6)
            .frame(height: Constant.commandBarHeight + (openTextField ? 100 : 0))
        }
        .background(Constant.commandBarBackgroundColor)
        .cornerRadius(10)
        .onAppear {
            Task {
                switch situation {
                case .NotRecipe:
                    return
                case .MainWindowRecipe(let context), .QuickExecutionRecipe(let context):
                    self.contextUid = await context.uid
                    self.text = await context.query
                    if let recipe = await context.activeRecipe {
                        let arguments = await context.arguments
                        var cells: [String] = []
                        var placeHolder = ""
                        cells.append(recipe.name)
                        for para in recipe.parameters {
                            if let value = arguments[para.name] {
                                cells.append("\(para.name):\(value)")
                            } else {
                                placeHolder.append("\(para.name):")
                            }
                        }
                        self.cells = cells
                        self.placeHolder = placeHolder
                    } else {
                        self.text = ""
                        self.cells = []
                        self.placeHolder = "input `command`+`space` or select one"
                    }
                }
            }
        }
        .onChange(of: text) { old, new in
            let editTime = Date()
            Task {
                let finalText: String
                switch situation {
                case .NotRecipe:
                    finalText = new
                case .MainWindowRecipe(let context), .QuickExecutionRecipe(let context):
                    finalText = await self.handleCell(text: new, context: context)
                }
                if editTime > lastEditTime {
                    self.text = finalText
                    switch situation {
                    case .NotRecipe:
                        break
                    case .MainWindowRecipe(let context), .QuickExecutionRecipe(let context):
                        await context.modifyQuery(finalText)
                    }
                    lastEditTime = editTime
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if lastEditTime == editTime {
                            NotificationCenter.default.post(name: .CommandBarEndEditing.group(self.uid.uuidString), object: nil)
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandBarEndEditing.group(self.uid.uuidString))) { _ in
            Task {
                switch situation {
                case .NotRecipe:
                    break
                case .MainWindowRecipe(let context), .QuickExecutionRecipe(let context):
                    if let _ = await context.activeRecipe {
                        await context.executeIfAutomatic()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeCommited)) { _ in
           Task {
               switch situation {
               case .NotRecipe:
                   return
               case .MainWindowRecipe(let context), .QuickExecutionRecipe(let context):
                   if let _ = await context.activeRecipe {
                       await context.execute()
                   }
               }
           }
       }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(contextUid?.uuidString ?? ""))) { _ in
            Task {
                switch situation {
                case .NotRecipe:
                    return
                case .MainWindowRecipe(let context), .QuickExecutionRecipe(let context):
                    if let recipe = await context.activeRecipe {
                        let arguments = await context.arguments
                        var cells: [String] = []
                        var placeHolder = ""
                        cells.append(recipe.name)
                        for para in recipe.parameters {
                            if let value = arguments[para.name] {
                                cells.append("\(para.name):\(value)")
                            } else {
                                placeHolder.append("\(para.name):")
                            }
                        }
                        self.cells = cells
                        self.placeHolder = placeHolder
                    } else {
                        self.cells = []
                        self.placeHolder = "input `command`+`space` or select one"
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandBarShouldFocus)) { _ in
            isFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .DeleteKeyWasPressed)) { _ in
            if isFocused && text.count == 0 {
               removeCell()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ReturnKeyWasPressed)) { _ in
            if isFocused {
                NotificationCenter.default.post(name: .RecipeCommited, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldCloseCommandBar)) { _ in
            if case .QuickExecutionRecipe(_) = self.situation {
            } else {
                withAnimation {
                    openTextField = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldCloseCommandBar.group("quick"))) { _ in
            if case .QuickExecutionRecipe(_) = self.situation {
                withAnimation {
                    openTextField = false
                }
            }
        }
    }
    
    struct CommitRecipeButtonView: View {
        
        @State var isHovering: Bool = false
        
        var recipeExecutionContext: RecipeExecutionContext
        
        var body: some View {
            HStack {
                Image(systemName: "return")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 15, maxHeight: 15)
                .foregroundStyle(.black.opacity(0.6))
            }
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill("C6C7F4".color.opacity(isHovering ? 0.6 : 0.4))
            )
            .onHover { isHovering in
                self.isHovering = isHovering
            }
            .onTapGesture {
                Task {
                    await recipeExecutionContext.execute()
                }
            }
        }
    }

    
    private func handleCell(text: String, context: RecipeExecutionContext) async -> String {
        guard let (commandPart, suffixPart) = text.splitOnce(separator: Character(" ")) else {
            return text
        }
        if await context.activeRecipe == nil {
            for recipe in RecipeManager.recipes.values {
                if let command = recipe.command, commandPart == command {
                    await context.switchRecipe(recipe.bundleId)
                    return suffixPart
                }
            }
        }
        if let activeRecipe = await context.activeRecipe, let (argumentName, argumentValue) = commandPart.splitOnce(separator: Character(":")) {
            for arg in activeRecipe.parameters.map({$0.name}) {
                if arg != argumentName {
                    continue
                }
                await context.addOrModifyArg(key: argumentName, value: argumentValue)
                return suffixPart
            }
        }
        return text
    }
    
    private func removeCell() {
        Task {
            switch situation {
            case .NotRecipe:
                return
            case .MainWindowRecipe(let context), .QuickExecutionRecipe(let context):
                if await context.arguments.count > 0 {
                    await context.delLastArg()
                    await context.executeIfAutomatic()
                } else {
                    await context.switchRecipe(nil)
                }
            }
        }
    }
    
    private func getCellText(originText: String) -> String {
        let isSingleLine = !originText.contains("\n")
        let line = Functions.getLinePreview(originText)
        let tooLong = line.count > 25
        var preview = String(line.prefix(25))
        if !isSingleLine || tooLong {
            preview += "..."
        }
        return preview
    }
    
}
