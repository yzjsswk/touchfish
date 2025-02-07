import SwiftyBeaver
import AppKit

let Log = SwiftyBeaverLogger.logger

struct SwiftyBeaverLogger {
    
    static let logger = SwiftyBeaver.self
    static private let consoleDst = ConsoleDestination()
    static private let fileDst = FileDestination()
    
    static func startConsoleLogging(minLevel: SwiftyBeaver.Level) {
        consoleDst.minLevel = minLevel
        SwiftyBeaver.addDestination(consoleDst)
    }
    
    static func startFileLogging(minLevel: SwiftyBeaver.Level, logFileUrl: URL) {
        fileDst.minLevel = minLevel
        fileDst.logFileURL = logFileUrl
        fileDst.logFileMaxSize = 10
        fileDst.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"
        fileDst.colored = true
        SwiftyBeaver.addDestination(fileDst)
    }
    
    static func stopConsoleLogging() {
        SwiftyBeaver.removeDestination(consoleDst)
    }
    
    static func stopFileLogging() {
        SwiftyBeaver.removeDestination(fileDst)
    }
    
}
