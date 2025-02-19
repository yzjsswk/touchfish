import SwiftUI
import ApplicationServices

struct HomeView: View {
    
    @State var dataServiceConnectTimeCost: Int? = nil
    @State var isAccessibilityEnable: Bool = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Welcome!")
                    .font(.title)
                    .padding(10)
                    Spacer()
                    VStack(alignment: .leading) {
                        HStack {
                            HStack {
                                Image(systemName: "fish.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Constant.selectedItemBackgroundColor.opacity(0.8))
                            }
                            .frame(width: 20)
                            if let timeOut = dataServiceConnectTimeCost {
                                if timeOut < 0 {
                                    Text("Data Server Connect Timeout" )
                                        .foregroundStyle(.red)
                                } else {
                                    Text("Data Server Connected: \(timeOut)ms" )
                                        .foregroundStyle(.green)
                                }
                            } else {
                                Text("No Data Server" )
                                    .foregroundStyle(.red)
                            }
                        }
                        HStack {
                            HStack {
                                Image(systemName: "accessibility.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.blue)
                            }
                            .frame(width: 20)
                            Text(isAccessibilityEnable ? "Accessibility Enable" : "Accessibility Disable")
                                .foregroundStyle(isAccessibilityEnable ? .green : .red)
                        }
                    }
                }
                Divider()
                StatsView()
                .padding(10)
            }
        }
        .cornerRadius(10)
        .padding(10)
        .onAppear {
            Task {
                if let config = Config.enableDataServiceConfig {
                    let timeCost = await DataService.tryConnect(host: config.host, port: config.port, timeoutSecond: 5)
                    withAnimation {
                        self.dataServiceConnectTimeCost = timeCost ?? -1
                    }
                } else {
                    withAnimation {
                        self.dataServiceConnectTimeCost = nil
                    }
                }
            }
            withAnimation {
                self.isAccessibilityEnable = AXIsProcessTrusted()
            }
        }
    }
    
}
