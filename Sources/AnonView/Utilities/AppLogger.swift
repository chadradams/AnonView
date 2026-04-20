import Foundation

enum AppLogger {
    static func info(_ message: @autoclosure () -> String) {
        print("[AnonView][INFO] \(message())")
    }

    static func error(_ message: @autoclosure () -> String) {
        print("[AnonView][ERROR] \(message())")
    }
}
