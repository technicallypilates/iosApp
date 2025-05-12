import Foundation
import os.log

struct Trace: Codable {
    let message: String
    let file: String
    let line: Int
    let timestamp: Date
}

class CrashReportingManager {
    static let shared = CrashReportingManager()
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "Crash")

    private init() {}

    func logCrash(message: String, file: String = #file, line: Int = #line) {
        let trace = Trace(message: message, file: file, line: line, timestamp: Date())
        os_log("Crash Logged: %{public}@", log: logger, type: .error, trace.message)
        
        // Save or send trace to server here...
    }

    func reportError(_ error: Error, context: String) {
        os_log("CrashReportingManager Error: %{public}@ | Context: %{public}@", log: logger, type: .error, error.localizedDescription, context)
    }
}

