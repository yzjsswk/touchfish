import SwiftUI

struct Process {
    
    var id: Int
    var name: String
    var desc: String?
    var icon: Image?
    var args: [String] = []
    var command: String?
    var action: () -> Void = {}
    
}

