import SwiftUI

struct ProcessView: View {
    
    var processList: [Process]
    
    var body: some View {
        ProcessListView(processList: processList)
    }
    
}
