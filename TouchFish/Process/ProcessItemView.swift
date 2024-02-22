import SwiftUI


struct ProcessItemView: View {
    
    var name: String
    var desc: String?
    var icon: Image
    var command: String
    var isSelected: Bool
    
    init(name: String, desc: String?, icon: Image?, command: String?) {
        self.name = name
        self.desc = desc
        self.icon = icon ?? Image(systemName: "parkingsign.circle")
        self.command = command ?? ""
        self.isSelected = false
    }
    
    var body: some View {
        HStack(spacing: 10) {
            icon
            .resizable()
            .scaledToFit()
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.title3)
                        .foregroundColor(isSelected ? Color.white: Color.black)
                    Text(command)
                        .font(.footnote)
                        .fontWeight(.bold)
                }
                if let desc = desc {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(5)
        .frame(width: Config.it.processItemWidth, height: Config.it.processItemHeight)
        .background(Config.it.promptBarBackgroundColor.color)
        .cornerRadius(5)
        
    }
    
}
