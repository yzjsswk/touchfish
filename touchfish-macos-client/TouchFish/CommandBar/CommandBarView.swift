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
    
    var body: some View {
        ZStack {
            HStack {
                ForEach(Array(cells.enumerated()), id: \.0) { _, cellText in
                    Text(getCellText(originText: cellText))
                        .background(
                            GeometryReader { geometry in
                                Rectangle()
                                    .cornerRadius(5)
                                    .foregroundStyle("5B5BCF".color)
                                    .frame(width: geometry.size.width+5, height: geometry.size.height+8)
                                    .offset(x: -2.5, y: -4)
                            }
                        )
                        .foregroundColor(.white)
                        .font(.custom("Menlo", size: 16))
                        .padding([.leading], 3)
                }
                ZStack {
                    CommandBarTextField(text: $text)
                    .frame(height: Constant.commandFieldHeight)
                    .offset(y: isFocused ? 2 : 8.8)
                    .focused($isFocused)
                    if text.count == 0 {
                        HStack {
                            Text(placeHolder)
                                .font(.custom("Menlo", size: 20))
                                .foregroundStyle("A3A3A3".color)
                                .offset(x: 3, y: 1)
                                .onTapGesture {
                                    isFocused = true
                                }
                            Spacer()
                        }
                    }
                }
                switch situation {
                case .NotRecipe:
                    EmptyView()
                case .MainWindowRecipe(let context):
                    if context.activeRecipe != nil {
                        CommitRecipeButtonView(recipeExecutionContext: context)
                        .padding(.trailing, 5)
                    }
                case .QuickExecutionRecipe(let context):
                    if context.activeRecipe != nil {
                        CommitRecipeButtonView(recipeExecutionContext: context)
                        .padding(.trailing, 5)
                    }
                }
                
            }
            .padding([.leading], 6)
            .frame(height: Constant.commandBarHeight)
        }
        .background(Constant.commandBarBackgroundColor)
        .cornerRadius(10)
        .onAppear {
            Task {
                switch situation {
                case .NotRecipe:
                    return
                case .MainWindowRecipe(let context):
                    self.contextUid = await context.uid
                    self.text = await context.query
                    if let recipe = await context.activeRecipe {
                        var cells: [String] = []
                        cells.append(recipe.name)
                        for (name, value) in await context.arguments {
                            cells.append("\(name):\(value)")
                        }
                        self.cells = cells
                        self.placeHolder = ""
                    } else {
                        self.text = ""
                        self.cells = []
                        self.placeHolder = "input `command`+`space` or select one"
                    }
                case .QuickExecutionRecipe(let context):
                    self.contextUid = await context.uid
                    self.text = await context.query
                    if let recipe = await context.activeRecipe {
                        self.cells = [recipe.name]
                        self.placeHolder = ""
                    } else {
                        self.text = ""
                        self.cells = []
                        self.placeHolder = "input `command`+`space` or select one"
                    }
                }
            }
        }
        .onChange(of: uid) { old, new in
            Log.debug("main view rebuild")
        }
        .onChange(of: text) { old, new in
            let editTime = Date()
            Task {
                let finalText: String
                switch situation {
                case .NotRecipe:
                    finalText = new
                case .MainWindowRecipe(let context):
                    finalText = await self.handleCell(text: new, context: context)
                case .QuickExecutionRecipe(let context):
                    finalText = await self.handleCell(text: new, context: context)
                }
                if editTime > lastEditTime {
//                    Log.debug("text changed at \(editTime): [\(old)] -> [\(new)] => [\(finalText)]")
                    self.text = finalText
                    switch situation {
                    case .NotRecipe:
                        break
                    case .MainWindowRecipe(let context):
                        await context.modifyQuery(finalText)
                    case .QuickExecutionRecipe(let context):
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
                case .MainWindowRecipe(let context):
                    if let _ = await context.activeRecipe {
                        await context.executeIfAutomatic()
                    }
                case .QuickExecutionRecipe(let context):
                    if let _ = await context.activeRecipe {
                        await context.executeIfAutomatic()
                    }
                }
            }
        }
        // todo: carefully controll event, avoid repeat execute
       .onReceive(NotificationCenter.default.publisher(for: .RecipeCommited)) { _ in
           Task {
               switch situation {
               case .NotRecipe:
                   return
               case .MainWindowRecipe(let context):
                   if let _ = await context.activeRecipe {
                       await context.execute()
                   }
               case .QuickExecutionRecipe(let context):
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
                case .MainWindowRecipe(let context):
                    if let recipe = await context.activeRecipe {
                        var cells: [String] = []
                        cells.append(recipe.name)
                        for (name, value) in await context.arguments {
                            cells.append("\(name):\(value)")
                        }
//                        self.text = await context.query
                        self.cells = cells
                        self.placeHolder = ""
                    } else {
//                        self.text = ""
                        self.cells = []
                        self.placeHolder = "input `command`+`space` or select one"
                    }
                case .QuickExecutionRecipe(let context):
                    if let recipe = await context.activeRecipe {
//                        self.text = await context.query
                        self.cells = [recipe.name]
                        self.placeHolder = ""
                    } else {
//                        self.text = ""
                        self.cells = []
                        self.placeHolder = "input `command`+`space` or select one"
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CommandBarShouldFocus)) { _ in
            isFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .ShouldBack)) { _ in
            removeCell()
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
            case .MainWindowRecipe(let context):
                if await context.arguments.count > 0 {
                    await context.delLastArg()
                } else {
                    await context.switchRecipe(nil)
                }
            case .QuickExecutionRecipe(let context):
                if await context.arguments.count > 0 {
                    await context.delLastArg()
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




