import SwiftUI

struct DynamicRecipeParaFieldView: View {
    
    @State var fishTags: [String] = []
    
    @Binding var context: RecipeExecutionContext
    
    @State var atSetting: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Constant.commandBarBackgroundColor)
                HStack(spacing: 3) {
                    DynamicRecipeParaFieldSwitchSettingButtonView(atSetting: $atSetting)
                    Spacer()
                    DynamicRecipeParaFieldClearParaButtonView(context: $context)
                }
                .padding(.horizontal, 5)
            }
            .padding(.horizontal, 3)
            .frame(height: 32)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if let recipe = context.activeRecipe {
                        if atSetting {
                            ForEach(Array(recipe.settings.enumerated()), id: \.0) { _, para in
                                DynamicRecipeParaInputView(para: para, fishTags: fishTags, isSetting: true, context: $context)
                                Divider()
                            }
                        } else {
                            ForEach(Array(recipe.parameters.enumerated()), id: \.0) { _, para in
                                DynamicRecipeParaInputView(para: para, fishTags: fishTags, isSetting: false, context: $context)
                                Divider()
                            }
                        }

                    }
                }
            }
            .padding(5)
        }
        .onAppear {
            Task {
                if let stats = await Storage.countFish() {
                    fishTags = stats.tagCount.keys.filter { !$0.isEmpty }
                }
            }
        }
        
    }
}

struct DynamicRecipeParaFieldSwitchSettingButtonView: View {
    
    @Binding var atSetting: Bool
    
    @State var isHovering: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: atSetting ? "gearshape.fill" : "gearshape")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 20, maxHeight: 20)
            .foregroundStyle("27295F".color)
        }
        .frame(width: 25, height: 25)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill("C6C7F4".color.opacity(isHovering ? 0.6 : 0))
        )
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            atSetting.toggle()
        }
    }
}

struct DynamicRecipeParaFieldClearParaButtonView: View {
    
    @State var isHovered = false
    
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        HStack {
            Image(systemName: "delete.left")
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 18)
            .foregroundStyle("27295F".color)
        }
        .frame(width: 28, height: 25)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill("C6C7F4".color.opacity(isHovered ? 0.6 : 0))
        )
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .onTapGesture {
            Task {
                await context.clearArg()
                await context.executeIfAutomatic()
            }
        }

    }
    
}

struct DynamicRecipeParaInputView: View {
    
    var para: Recipe.Parameter
    
    var fishTags: [String]
    var isSetting: Bool
    
    @State var isListAddButtonHovered: Bool = false
    @State var addFlag: Bool = false
    
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        VStack {
            HStack {
                Text(para.name)
                    .font(.title3)
                    .bold()
                Spacer()
                if let _ = para.separator {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(isListAddButtonHovered ? "5B5BCF".color.opacity(0.8) : .gray)
                        .onHover { isHovered in
                            self.isListAddButtonHovered = isHovered
                        }
                        .onTapGesture {
                            addFlag.toggle()
                        }
                } else {
                    if para.inputer == .Check {
                        DynamicRecipeCheckParaView(name: para.name, isSetting: isSetting, context: $context)
                    }
                }
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
                if let separator = para.separator {
                    DynamicRecipeListSingleLineEditParaView(name: para.name, separator: separator, addFlag: $addFlag, isSetting: isSetting, context: $context)
                } else {
                    DynamicRecipeSingleLineEditParaView(name: para.name, isSetting: isSetting, context: $context)
                }
            case .MultLineEdit:
                if let separator = para.separator {
                    DynamicRecipeListMultLineEditParaView(name: para.name, separator: separator, addFlag: $addFlag, isSetting: isSetting, context: $context)
                } else {
                    DynamicRecipeMultLineEditParaView(name: para.name, isSetting: isSetting, context: $context)
                }
            case .Choice:
                let options = (para.options.first ?? "" == "$FISH_TAGS") ? fishTags : para.options
                if let separator = para.separator {
                    DynamicRecipeListChoiceParaView(name: para.name, options: options, separator: separator, addFlag: $addFlag, isSetting: isSetting, context: $context)
                } else {
                    DynamicRecipeChoiceParaView(name: para.name, options: options, isSetting: isSetting, context: $context)
                }
            case .Check:
                if let separator = para.separator {
                    DynamicRecipeListCheckParaView(name: para.name, separator: separator, addFlag: $addFlag, isSetting: isSetting, context: $context)
                }
            case .Slide:
                EmptyView()
            }
        }
    }
    
}

struct DynamicRecipeSingleLineEditParaView: View {
    
    var name: String
    
    @State var value: String = ""
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
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
        .onAppear {
            if isSetting {
                // todo: read setting
            } else {
                Task {
                    if let value = await context.arguments[name] {
                        self.value = value
                    } else {
                        self.value = ""
                    }
                }
            }
        }
        .onChange(of: value) {
            if !isSetting {
                Task {
                    if value == "" {
                        await context.delArg(key: name)
                    } else {
                        await context.addOrModifyArg(key: name, value: value)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            if !isSetting {
                Task {
                    if let value = await context.arguments[name] {
                        self.value = value
                    } else {
                        self.value = ""
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeListSingleLineEditParaView: View {
    
    var name: String
    var separator: String
    
    @State var values: [String] = []
    @State var isHovered: [Bool] = []
    
    @Binding var addFlag: Bool
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? "C62828".color : .gray)
                    .onHover { isHovered in
                        if idx < self.isHovered.count {
                            self.isHovered[idx] = isHovered
                        }
                    }
                    .onTapGesture {
                        self.values.remove(at: idx)
                        self.isHovered.remove(at: idx)
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke("A1A9C6".color, lineWidth: 3)
                        VStack {
                            Spacer(minLength: 0)
                            TextField("", text: $values[idx])
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.custom("Menlo", size: 16))
                            Spacer(minLength: 0)
                        }
                        .padding(5)
                    }
                    .background(Color.white)
                    .cornerRadius(5)
                }
            }
        }
        .onAppear {
            if isSetting {
                // todo: read setting
            }
        }
        .onChange(of: addFlag) {
            values.append("")
            isHovered.append(false)
        }
        .onChange(of: values) {
            if !isSetting {
                Task {
                    let value = values.filter { $0 != "" }.joined(separator: separator)
                    if value == "" {
                        await context.delArg(key: name)
                    } else {
                        await context.addOrModifyArg(key: name, value: value)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            if !isSetting {
                Task {
                    if let values = await context.parsedArguments[name] {
                        self.values = values
                        self.isHovered = Array(repeating: false, count: self.values.count)
                    } else {
                        self.values.removeAll { !$0.isEmpty }
                        self.isHovered = Array(repeating: false, count: self.values.count)
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeMultLineEditParaView: View {
    
    var name: String
    
    @State var value: String = ""
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
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
        .onAppear {
            if isSetting {
                // todo: read setting
            }
        }
        .onChange(of: value) {
            if !isSetting {
                Task {
                    if value == "" {
                        await context.delArg(key: name)
                    } else {
                        await context.addOrModifyArg(key: name, value: value)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            if !isSetting {
                Task {
                    if let value = await context.arguments[name] {
                        self.value = value
                    } else {
                        self.value = ""
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeListMultLineEditParaView: View {
    
    var name: String
    var separator: String
    
    @State var values: [String] = []
    @State var isHovered: [Bool] = []
    
    @Binding var addFlag: Bool
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? "C62828".color : .gray)
                    .onHover { isHovered in
                        if idx < self.isHovered.count {
                            self.isHovered[idx] = isHovered
                        }
                    }
                    .onTapGesture {
                        self.values.remove(at: idx)
                        self.isHovered.remove(at: idx)
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke("A1A9C6".color, lineWidth: 3)
                        VStack {
                            Spacer(minLength: 0)
                            TextEditor(text: $values[idx])
                                .font(.custom("Menlo", size: 16))
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 2)
                    }
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(height: Constant.mainWidth*0.12)
                }
            }
        }
        .onAppear {
            if isSetting {
                // todo: read setting
            }
        }
        .onChange(of: addFlag) {
            values.append("")
            isHovered.append(false)
        }
        .onChange(of: values) {
            if !isSetting {
                Task {
                    let value = values.filter { $0 != "" }.joined(separator: separator)
                    if value == "" {
                        await context.delArg(key: name)
                    } else {
                        await context.addOrModifyArg(key: name, value: value)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            if !isSetting {
                Task {
                    if let values = await context.parsedArguments[name] {
                        self.values = values
                        self.isHovered = Array(repeating: false, count: self.values.count)
                    } else {
                        self.values.removeAll { !$0.isEmpty }
                        self.isHovered = Array(repeating: false, count: self.values.count)
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeChoiceParaView: View {
    
    var name: String
    var options: [String]
    
    @State var value: String = "nothing"
    
    @State var isClearButtonHovered: Bool = false
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        Picker("", selection: $value) {
            ForEach(getOptions(options), id: \.self) { opt in
                if opt == "nothing" {
                    Text(opt)
                    .foregroundStyle(.gray)
                } else {
                    Text(opt)
                }
            }
        }
        .pickerStyle(.menu)
        .padding(.horizontal, 5)
        .onAppear {
            if isSetting {
                // todo: read setting
            }
        }
        .onChange(of: value) {
            if !isSetting {
                Task {
                    if value == "nothing" {
                        await context.delArg(key: name)
                    } else {
                        await context.addOrModifyArg(key: name, value: value)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            if !isSetting {
                Task {
                    if let value = await context.arguments[name] {
                        if options.contains(value) {
                            self.value = value
                        } else {
                            self.value = "nothing"
                        }
                    } else {
                        self.value = "nothing"
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeListChoiceParaView: View {
    
    var name: String
    var options: [String]
    var separator: String
    
    @State var values: [String] = []
    @State var isHovered: [Bool] = []
    
    @Binding var addFlag: Bool
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? "C62828".color : .gray)
                    .onHover { isHovered in
                        if idx < self.isHovered.count {
                            self.isHovered[idx] = isHovered
                        }
                    }
                    .onTapGesture {
                        self.values.remove(at: idx)
                        self.isHovered.remove(at: idx)
                    }
                    Picker("", selection: $values[idx]) {
                        ForEach(getOptions(options), id: \.self) { opt in
                            if opt == "nothing" {
                                Text(opt)
                                .foregroundStyle(.gray)
                            } else {
                                Text(opt)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 5)
                }
            }
        }
        .onAppear {
            if isSetting {
                // todo: read setting
            }
        }
        .onChange(of: addFlag) {
            values.append("nothing")
            isHovered.append(false)
        }
        .onChange(of: values) {
            if !isSetting {
                Task {
                    let value = values.filter { $0 != "nothing" }.joined(separator: separator)
                    if value == "" {
                        await context.delArg(key: name)
                    } else {
                        await context.addOrModifyArg(key: name, value: value)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            Task {
                if !isSetting {
                    if let values = await context.parsedArguments[name] {
                        let somethingCount = self.values.filter { $0 != "nothing" }.count
                        if somethingCount != values.count {
                            self.values = values.map { options.contains($0) ? $0 : "nothing" }
                            self.isHovered = Array(repeating: false, count: self.values.count)
                        } else {
                            var cnt = 0
                            for idx in self.values.indices {
                                if self.values[idx] == "nothing" {
                                    continue
                                }
                                if cnt < values.count {
                                    self.values[idx] = values[cnt]
                                } else {
                                    Log.warning("dynamicRecipeViewParaField -> received recipeStatusChanged -> modify list type singleChioce para: \(name) -> something count of field == of that in commandbar -> only modify something in paraField(keep nothing) -> code logic bug: cnt >= values.count")
                                }
                                cnt += 1
                            }
                        }
                    } else {
                        self.values = Array(repeating: "nothing", count: self.values.count)
                        self.isHovered = Array(repeating: false, count: self.values.count)
                    }
                }
            }
        }
    }
    
}

struct DynamicRecipeCheckParaView: View {
    
    var name: String
    
    @State var enable: Bool = false
    @State var value: Bool = false
    
    @State var isHovered: Bool = false
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        HStack(spacing: 10) {
            if enable {
                Image(systemName: isHovered ? "nosign.app.fill" : "nosign.app")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(.gray)
                    .onHover { isHovered in
                        self.isHovered = isHovered
                    }
                    .onTapGesture {
                        enable = false
                        value = false
                    }
            }
            Toggle(isOn: $value) {}
        }
        .padding(.horizontal, 2)
        .onAppear {
            if isSetting {
                // todo: read setting
            }
        }
        .onChange(of: value) {
            if !isSetting {
                Task {
                    if value {
                        enable = true
                        await context.addOrModifyArg(key: name, value: value ? "1" : "0")
                    } else {
                        if enable {
                            await context.addOrModifyArg(key: name, value: value ? "1" : "0")
                        } else {
                            await context.delArg(key: name)
                        }
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onChange(of: enable) {
            if !isSetting {
                Task {
                    if !enable {
                        await context.delArg(key: name)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            if !isSetting {
                Task {
                    if let value = await context.arguments[name] {
                        if value.lowercased() == "true" || value == "1" {
                            self.enable = true
                            self.value = true
                        } else if value.lowercased() == "false" || value == "0" {
                            self.enable = true
                            self.value = false
                        } else {
                            self.enable = false
                            self.value = false
                        }
                    } else {
                        self.enable = false
                        self.value = false
                    }
                }
            }
        }
    }
    
}

func getOptions(_ originOptions: [String]) -> [String] {
    var ret = ["nothing"]
    for opt in originOptions {
        if opt != "nothing" {
            ret.append(opt)
        }
    }
    return ret
}

struct DynamicRecipeListCheckParaView: View {
    
    var name: String
    var separator: String
    
    @State var values: [Bool] = []
    @State var isHovered: [Bool] = []
    
    @Binding var addFlag: Bool
    
    var isSetting: Bool
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? "C62828".color : .gray)
                        .onHover { isHovered in
                            if idx < self.isHovered.count {
                                self.isHovered[idx] = isHovered
                            }
                        }
                        .onTapGesture {
                            self.values.remove(at: idx)
                            self.isHovered.remove(at: idx)
                        }
                    Spacer()
                    Toggle(isOn: $values[idx]) {}
                    .padding(.horizontal, 2)
                }
            }
        }
        .onAppear {
            if isSetting {
                // todo: read setting
            }
        }
        .onChange(of: addFlag) {
            values.append(false)
            isHovered.append(false)
        }
        .onChange(of: values) {
            if !isSetting {
                Task {
                    let value = values.map { $0 ? "1" : "0" }.joined(separator: separator)
                    if value == "" {
                        await context.delArg(key: name)
                    } else {
                        await context.addOrModifyArg(key: name, value: value)
                    }
                }
            } else {
                // todo: modify setting
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(context.uid.uuidString))) { _ in
            if !isSetting {
                Task {
                    var newValues: [Bool] = []
                    var newIsHovered: [Bool] = []
                    if let values = context.parsedArguments[name] {
                        for value in values {
                            if value.lowercased() == "true" || value == "1" {
                                newValues.append(true)
                            } else {
                                newValues.append(false)
                            }
                            newIsHovered.append(false)
                        }
                    }
                    self.values = newValues
                    self.isHovered = newIsHovered
                }
            }
        }
    }
    
}
