import SwiftUI

struct DataServiceSettingView: View {
    
    @Binding var tempSetting: Configuration
    
    var body: some View {
        VStack {
            HStack {
                Text("Connection Info")
                    .font(.title3)
                    .bold()
                DataServiceConfigAddView(dataServiceConfigs: $tempSetting.dataServiceConfigs)
                Spacer()
            }
            .padding()
            if let enableConfig = tempSetting.dataServiceConfigs[tempSetting.enableDataServiceConfigName] {
                DataServiceConfigItemView(
                    isEnabled: true,
                    name: tempSetting.enableDataServiceConfigName,
                    host: enableConfig.host,
                    port: enableConfig.port,
                    dataServiceConfigs: $tempSetting.dataServiceConfigs,
                    enableDataServiceConfigName: $tempSetting.enableDataServiceConfigName
                )
                .padding(.horizontal)
            }
            ForEach(Array(tempSetting.dataServiceConfigs).sorted(by: { $0.key < $1.key } ), id:\.key) { config in
                if config.key != tempSetting.enableDataServiceConfigName {
                    DataServiceConfigItemView(
                        name: config.key,
                        host: config.value.host,
                        port: config.value.port,
                        dataServiceConfigs: $tempSetting.dataServiceConfigs,
                        enableDataServiceConfigName: $tempSetting.enableDataServiceConfigName
                    )
                    .padding(.horizontal)
                }
            }
            Divider()
            .padding(.horizontal)
        }
    }
    
}

struct DataServiceConfigAddView: View {
    
    @State private var isOpening = false
    
    @State private var isHovered1 = false
    @State private var isHovered2 = false
    @State private var isHovered3 = false
    
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = ""
    
    @State private var message: String = ""
    @State private var showPopover: Bool = false
    
    @Binding var dataServiceConfigs: [String:Configuration.ServerConfig]
    
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
                    if dataServiceConfigs.keys.contains(name) {
                        message = "name exists"
                        showPopover = true
                        return
                    }
                    dataServiceConfigs[name] = Configuration.ServerConfig(host: host, port: port)
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

struct EnableButtonView: View {
    
    var isEnabled: Bool
    
    @State var isHovered = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
            if isEnabled {
                Text("Enabled")
                    .font(.title3)
                    .foregroundStyle(.black)
                    .bold()
                    .frame(width: 60)
            } else {
                Text("Enable")
                    .font(.title3)
                    .foregroundStyle(isHovered ? .black : .gray)
                    .frame(width: 60)
            }

        }
        .frame(width: 65, height: 30)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
}

struct DataServiceConfigItemView: View {
    
    var isEnabled: Bool = false
    var name: String
    var host: String
    var port: String
    
    @Binding var dataServiceConfigs: [String:Configuration.ServerConfig]
    @Binding var enableDataServiceConfigName: String
    
    @State var timeCost: Int?
    
    var body: some View {
        HStack {
            EnableButtonView(isEnabled: isEnabled)
            .onTapGesture {
                enableDataServiceConfigName = name
            }
            Text("\(name)")
                .font(.title3)
            Text("[host:\(host) port:\(port)]")
                .font(.title3)
            Spacer()
            Button(action: {
                dataServiceConfigs.removeValue(forKey: name)
            }) {
                Text("Remove")
            }
            Button(action:{
//                Task {
//                    let timeCost = await DataService.tryConnect(host: host, port: port)
//                    withAnimation {
//                        self.timeCost = timeCost ?? -1
//                    }
//                }
            }) {
                Text("Try Connect")
            }
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
            }
        }
    }
    
}
