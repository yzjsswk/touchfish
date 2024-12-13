import SwiftUI

struct RecipeServiceConfigListView: View {
    
    @Binding var tempSetting: Configuration
    
    var body: some View {
        if tempSetting.recipeServiceConfigs.count > 0 {
            VStack(spacing: 10) {
                ForEach(tempSetting.recipeServiceConfigs.indices, id: \.self) { idx in
                    RecipeServiceConfigItemView(
                        config: $tempSetting.recipeServiceConfigs[idx],
                        recipeServiceConfigs: $tempSetting.recipeServiceConfigs
                    )
                }
            }
        } else {
            Text("-- Empty --")
                .font(.custom("Menlo", size: 13))
                .foregroundStyle(.gray)
        }
    }
    
}

struct RecipeServiceConfigItemView: View {
    
    struct RemoveButtonView: View {
        
        @Binding var recipeServiceConfigs: [Configuration.RecipeServerConfig]
        @State var isHovered: Bool = false
        var name: String
        
        var body: some View {
            Image(systemName: "minus.circle")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(isHovered ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .onTapGesture {
                recipeServiceConfigs.removeAll(where: { $0.name == name })
            }
        }
        
    }

    @Binding var config: Configuration.RecipeServerConfig
    @Binding var recipeServiceConfigs: [Configuration.RecipeServerConfig]
    
    @State var timeCost: Int?
    
    var body: some View {
        HStack {
            Toggle("", isOn: $config.enable)
            .toggleStyle(SwitchToggleStyle())
            .padding(.leading, -8)
            Text("\(config.name)")
            .font(.title3)
            .bold()
            .frame(width: 60, alignment: .leading)
            Text("host: \(config.host)")
            .font(.title3)
            Text("port: \(config.port)")
            .font(.title3)
            Spacer()
            if config.enable {
                if let timeCost = timeCost {
                    if timeCost == -1 {
                        Image(systemName: "xmark")
                            .foregroundStyle(.red)
                    } else {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                        Text("\(timeCost)ms")
                            .foregroundStyle(.green)
                    }
                } else {
                    Image(systemName: "circle.dotted")
                }
            }
            RemoveButtonView(recipeServiceConfigs: $recipeServiceConfigs, name: config.name)
        }
        .onAppear {
            if config.enable {
                Task {
                    let timeCost = await RecipeService(host: config.host, port: config.port).tryConnect(timeoutSecond: 5)
                    withAnimation {
                        self.timeCost = timeCost ?? -1
                    }
                }
            }
        }
        .onChange(of: config.enable) { old, new in
            timeCost = nil
            if new {
                Task {
                    let timeCost = await RecipeService(host: config.host, port: config.port).tryConnect(timeoutSecond: 5)
                    withAnimation {
                        self.timeCost = timeCost ?? -1
                    }
                }
            }
        }
    }
    
}

struct RecipeServiceConfigAddView: View {
    
    @State private var isOpening = false
    
    @State private var isHovered1 = false
    @State private var isHovered2 = false
    @State private var isHovered3 = false
    
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = ""
    
    @State private var message: String = ""
    @State private var showPopover: Bool = false
    
    @Binding var recipeServiceConfigs: [Configuration.RecipeServerConfig]
    
    var body: some View {
        
        if !isOpening {
            Image(systemName: "plus.circle")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(isHovered1 ? Constant.selectedItemBackgroundColor : Functions.makeLinearGradient(colors: [.gray]))
            .onHover { isHovered in
                self.isHovered1 = isHovered
            }
            .onTapGesture {
                isOpening = true
            }
        } else {
            HStack {
                TextField("name", text: $name)
                .frame(width: 100, height: 20)
                TextField("host", text: $host)
                .frame(width: 100, height: 20)
                TextField("port", text: $port)
                .frame(width: 100, height: 20)
                Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isHovered2 ? .green : .gray)
                .onHover { isHovered in
                    self.isHovered2 = isHovered
                }
                // todo: fix: popover show empty string when first appear
                .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                    Text(message)
                        .padding()
                }
                .onTapGesture {
                    if name.count <= 0 {
                        message = "name can not be empty"
                        showPopover = true
                        return
                    }
                    if host.count <= 0 {
                        message = "host can not be empty"
                        showPopover = true
                        return
                    }
                    if port.count <= 0 {
                        message = "port can not be empty"
                        showPopover = true
                        return
                    }
                    if recipeServiceConfigs.contains(where: { $0.name == name }) {
                        message = "name exists"
                        showPopover = true
                        return
                    }
                    recipeServiceConfigs.append(Configuration.RecipeServerConfig(name: name, host: host, port: port, enable: false))
                    isOpening = false
                    name = ""
                    host = ""
                    port = ""
                    message = ""
                    showPopover = false
                }
                Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isHovered3 ? .red : .gray)
                .onHover { isHovered in
                    self.isHovered3 = isHovered
                }
                .onTapGesture {
                    isOpening = false
                    name = ""
                    host = ""
                    port = ""
                    message = ""
                    showPopover = false
                }
            }
        }
    }

}
