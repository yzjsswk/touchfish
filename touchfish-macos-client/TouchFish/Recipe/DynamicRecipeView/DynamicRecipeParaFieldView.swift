import SwiftUI

struct DynamicRecipeParaFieldView: View {
    
    @State var fishTags: [String] = []
    
    @Binding var context: RecipeExecutionContext
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill("C6C7F4".color)
                HStack(spacing: 3) {
                    // todo: setting button
                    Spacer()
                    DynamicRecipeParaFieldClearParaButtonView()
                }
                .padding(.horizontal, 5)
            }
            .padding(.horizontal, 3)
            .frame(height: 32)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if let recipe = context.activeRecipe {
                        ForEach(Array(recipe.parameters.enumerated()), id: \.0) { _, para in
                            DynamicRecipeParaInputView(para: para, fishTags: fishTags)
                            Divider()
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

struct DynamicRecipeParaInputView: View {
    
    var para: Recipe.Parameter
    
    var fishTags: [String]
    
    @State var isListAddButtonHovered: Bool = false
    @State var addFlag: Bool = false
    
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
                        .foregroundStyle(isListAddButtonHovered ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
                        .onHover { isHovered in
                            self.isListAddButtonHovered = isHovered
                        }
                        .onTapGesture {
                            addFlag.toggle()
                        }
                } else {
                    if para.inputer == .Check {
                        DynamicRecipeCheckParaView(name: para.name)
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
                    DynamicRecipeListSingleLineEditParaView(name: para.name, separator: separator, addFlag: $addFlag)
                } else {
                    DynamicRecipeSingleLineEditParaView(name: para.name)
                }
            case .MultLineEdit:
                if let separator = para.separator {
                    DynamicRecipeListMultLineEditParaView(name: para.name, separator: separator, addFlag: $addFlag)
                } else {
                    DynamicRecipeMultLineEditParaView(name: para.name)
                }
            case .Choice:
                let options = (para.options.first ?? "" == "$FISH_TAGS") ? fishTags : para.options
                if let separator = para.separator {
                    DynamicRecipeListChoiceParaView(name: para.name, options: options, separator: separator, addFlag: $addFlag)
                } else {
                    DynamicRecipeChoiceParaView(name: para.name, options: options)
                }
            case .Check:
                if let separator = para.separator {
                    DynamicRecipeListCheckParaView(name: para.name, separator: separator, addFlag: $addFlag)
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
//        .onChange(of: value) {
//            if value == "" {
//                RecipeManager.delArg(key: name)
//            } else {
//                RecipeManager.modifyArg(key: name, value: value)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            if let value = RecipeManager.activeRecipeOriginalArg[name] {
//                self.value = value
//            } else {
//                self.value = ""
//            }
//        }
    }
    
}

struct DynamicRecipeListSingleLineEditParaView: View {
    
    var name: String
    var separator: String
    
    @State var values: [String] = []
    @State var isHovered: [Bool] = []
    
    @Binding var addFlag: Bool
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
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
        .onChange(of: addFlag) {
            values.append("")
            isHovered.append(false)
        }
//        .onChange(of: values) {
//            let value = values.filter { $0 != "" }.joined(separator: separator)
//            if value == "" {
//                RecipeManager.delArg(key: name)
//            } else {
//                RecipeManager.modifyArg(key: name, value: value)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            if let values = RecipeManager.activeRecipeArg[name] {
//                self.values = values
//                self.isHovered = Array(repeating: false, count: self.values.count)
//            } else {
//                self.values.removeAll { !$0.isEmpty }
//                self.isHovered = Array(repeating: false, count: self.values.count)
//            }
//        }
    }
    
}

struct DynamicRecipeMultLineEditParaView: View {
    
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
//        .onChange(of: value) {
//            if value == "" {
//                RecipeManager.delArg(key: name)
//            } else {
//                RecipeManager.modifyArg(key: name, value: value)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            if let value = RecipeManager.activeRecipeOriginalArg[name] {
//                self.value = value
//            } else {
//                self.value = ""
//            }
//        }
    }
    
}

struct DynamicRecipeListMultLineEditParaView: View {
    
    var name: String
    var separator: String
    
    @State var values: [String] = []
    @State var isHovered: [Bool] = []
    
    @Binding var addFlag: Bool
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
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
        .onChange(of: addFlag) {
            values.append("")
            isHovered.append(false)
        }
//        .onChange(of: values) {
//            let value = values.filter { $0 != "" }.joined(separator: separator)
//            if value == "" {
//                RecipeManager.delArg(key: name)
//            } else {
//                RecipeManager.modifyArg(key: name, value: value)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            if let values = RecipeManager.activeRecipeArg[name] {
//                self.values = values
//                self.isHovered = Array(repeating: false, count: self.values.count)
//            } else {
//                self.values.removeAll { !$0.isEmpty }
//                self.isHovered = Array(repeating: false, count: self.values.count)
//            }
//        }
    }
    
}

struct DynamicRecipeChoiceParaView: View {
    
    var name: String
    var options: [String]
    
    @State var value: String = "nothing"
    
    @State var isClearButtonHovered: Bool = false
    
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
//        .onChange(of: value) {
//            if value == "nothing" {
//                RecipeManager.delArg(key: name)
//            } else {
//                RecipeManager.modifyArg(key: name, value: value)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            if let value = RecipeManager.activeRecipeOriginalArg[name] {
//                if options.contains(value) {
//                    self.value = value
//                } else {
//                    self.value = "nothing"
//                }
//            } else {
//                self.value = "nothing"
//            }
//        }
    }
    
}

struct DynamicRecipeListChoiceParaView: View {
    
    var name: String
    var options: [String]
    var separator: String
    
    @State var values: [String] = []
    @State var isHovered: [Bool] = []
    
    @Binding var addFlag: Bool
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
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
        .onChange(of: addFlag) {
            values.append("nothing")
            isHovered.append(false)
        }
//        .onChange(of: values) {
//            let value = values.filter { $0 != "nothing" }.joined(separator: separator)
//            if value == "" {
//                RecipeManager.delArg(key: name)
//            } else {
//                RecipeManager.modifyArg(key: name, value: value)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            if let values = RecipeManager.activeRecipeArg[name] {
//                let somethingCount = self.values.filter { $0 != "nothing" }.count
//                if somethingCount != values.count {
//                    self.values = values.map { options.contains($0) ? $0 : "nothing" }
//                    self.isHovered = Array(repeating: false, count: self.values.count)
//                } else {
//                    var cnt = 0
//                    for idx in self.values.indices {
//                        if self.values[idx] == "nothing" {
//                            continue
//                        }
//                        if cnt < values.count {
//                            self.values[idx] = values[cnt]
//                        } else {
//                            Log.warning("dynamicRecipeViewParaField -> received recipeStatusChanged -> modify list type singleChioce para: \(name) -> something count of field == of that in commandbar -> only modify something in paraField(keep nothing) -> code logic bug: cnt >= values.count")
//                        }
//                        cnt += 1
//                    }
//                }
//            } else {
//                self.values = Array(repeating: "nothing", count: self.values.count)
//                self.isHovered = Array(repeating: false, count: self.values.count)
//            }
//        }
    }
    
}

struct DynamicRecipeCheckParaView: View {
    
    var name: String
    
    @State var enable: Bool = false
    @State var value: Bool = false
    
    @State var isHovered: Bool = false
    
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
//        .onChange(of: value) {
//            if value {
//                enable = true
//                RecipeManager.modifyArg(key: name, value: value ? "1" : "0")
//            } else {
//                if enable {
//                    RecipeManager.modifyArg(key: name, value: value ? "1" : "0")
//                } else {
//                    RecipeManager.delArg(key: name)
//                }
//            }
//        }
//        .onChange(of: enable) {
//            if !enable {
//                RecipeManager.delArg(key: name)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            if let value = RecipeManager.activeRecipeOriginalArg[name] {
//                if value.lowercased() == "true" || value == "1" {
//                    self.enable = true
//                    self.value = true
//                } else if value.lowercased() == "false" || value == "0" {
//                    self.enable = true
//                    self.value = false
//                } else {
//                    self.enable = false
//                    self.value = false
//                }
//            } else {
//                self.enable = false
//                self.value = false
//            }
//        }
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
    
    var body: some View {
        VStack {
            ForEach(Array(values.enumerated()), id: \.0) { idx, _ in
                HStack {
                    Image(systemName: "minus.circle")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle((idx < isHovered.count && isHovered[idx]) ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
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
        .onChange(of: addFlag) {
            values.append(false)
            isHovered.append(false)
        }
//        .onChange(of: values) {
//            let value = values.map { $0 ? "1" : "0" }.joined(separator: separator)
//            if value == "" {
//                RecipeManager.delArg(key: name)
//            } else {
//                RecipeManager.modifyArg(key: name, value: value)
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .RecipeStatusChanged)) { _ in
//            var newValues: [Bool] = []
//            var newIsHovered: [Bool] = []
//            if let values = RecipeManager.activeRecipeArg[name] {
//                for value in values {
//                    if value.lowercased() == "true" || value == "1" {
//                        newValues.append(true)
//                    } else {
//                        newValues.append(false)
//                    }
//                    newIsHovered.append(false)
//                }
//            }
//            self.values = newValues
//            self.isHovered = newIsHovered
//        }
    }
    
}

struct DynamicRecipeParaFieldClearParaButtonView: View {
    
    @State var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "delete.left.fill" : "delete.left")
            .resizable()
            .scaledToFit()
            .foregroundStyle("27295F".color)
            .frame(width: isHovered ? 27 : 25, height: isHovered ? 22 : 20)
        }
        .frame(width: 27, height: 22)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
//        .onTapGesture {
//            NotificationCenter.default.post(name: .CommandTextChanged, object: nil, userInfo: ["commandText":""])
//            RecipeManager.clearArg()
//        }

    }
    
}

//struct DynamicRecipeParaFieldExecuteRecipeButtonView: View {
//    
//    @State var isHovered = false
//    
//    var body: some View {
//        HStack {
//            Image(systemName: isHovered ? "play.square.fill" : "play.square")
//            .resizable()
//            .scaledToFit()
//            .foregroundStyle("27295F".color)
//            .frame(width: isHovered ? 27 : 25, height: isHovered ? 22 : 20)
//        }
//        .frame(width: 27, height: 22)
//        .onHover { isHovered in
//            withAnimation(.spring(duration: 0.1)) {
//                self.isHovered = isHovered
//            }
//        }
//        .onTapGesture {
//            NotificationCenter.default.post(name: .RecipeCommited, object: nil)
//        }
//
//    }
//    
//}
