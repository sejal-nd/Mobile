//
//  Logger.swift
//  Mobile
//
//  Created by Marc Shilling on 1/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

enum Log {
    enum LogLevel {
        case custom(emoji: String)
        case error
        case info
        case verbose
        case warning
        case fatal

        var emoji: String {
            switch self {
            case .custom(let emoji):
                return emoji
            case .error:
                return "❌"
            case .info:
                return "ℹ️"
            case .verbose:
                return "💬"
            case .warning:
                return "⚠️"
            case .fatal:
                return "🔥"
            }
        }
    }
    
    /// Writes out the given message closure string with the logger if the log level is allowed.
    ///
    /// - Parameters:
    ///   - message:      A closure returning the message to log.
    ///   - withLogLevel: The log level associated with the message closure.
    private static func logMessage(_ message: @escaping () -> String,
                                   _ function: String,
                                   _ filename: String,
                                   _ column: Int,
                                   _ line: Int,
                                   with logLevel: LogLevel) {
        #if DEBUG
        let dateString = Log.dateFormatter.string(from: Date())
        let message = message()
        let chunkSize = 800
        
        if message.count > chunkSize {
            let messageChunks = message.split(byChunkSize: chunkSize)
            print("\(dateString)\n[\(logLevel.emoji)] [\(messageChunks.count) Parts] [\(filename))]:\(line) \(column) \(function)")
            
            for (offset, messageChunk) in messageChunks.enumerated() {
                print("\(dateString)\n[\(logLevel.emoji)] [Part \(offset + 1)] [\(filename))]:\(line) \(column) \(function) \n\(messageChunk)")
            }
        } else {
            print("\(dateString)\n[\(logLevel.emoji)] [\(filename))]:\(line) \(column) \(function) \n\(message)")
        }
        
            #if os(watchOS)
                // Show log messages for watch in iOS console
                WatchSessionController.shared.transferUserInfo(userInfo: ["console": message])
            #endif
        #endif
    }
    
    static func custom(_ emoji: @autoclosure @escaping () -> String,
                       _ message: @autoclosure @escaping () -> String,
                       _ function: String = #function,
                       _ filename: String = #file,
                       _ column: Int = #column,
                       _ line: Int = #line) {
        logMessage(message, function, filename, column, line, with: .custom(emoji: emoji()))
    }
    
    static func error(_ message: @autoclosure @escaping () -> String,
                      _ function: String = #function,
                      _ filename: String = #file,
                      _ column: Int = #column,
                      _ line: Int = #line) {
        logMessage(message, function, filename, column, line, with: .error)
    }
    
    static func info(_ message: @autoclosure @escaping () -> String,
                     _ function: String = #function,
                     _ filename: String = #file,
                     _ column: Int = #column,
                     _ line: Int = #line) {
        logMessage(message, function, filename, column, line, with: .info)
    }
    
    static func verbose(_ message: @autoclosure @escaping () -> String,
                        _ function: String = #function,
                        _ filename: String = #file,
                        _ column: Int = #column,
                        _ line: Int = #line) {
        logMessage(message, function, filename, column, line, with: .verbose)
    }
    
    static func warning(_ message: @autoclosure @escaping () -> String,
                        _ function: String = #function,
                        _ filename: String = #file,
                        _ column: Int = #column,
                        _ line: Int = #line) {
        logMessage(message, function, filename, column, line, with: .warning)
    }
    
    static func fatal(_ message: @autoclosure @escaping () -> String,
                      _ function: String = #function,
                      _ filename: String = #file,
                      _ column: Int = #column,
                      _ line: Int = #line) {
        logMessage(message, function, filename, column, line, with: .fatal)
    }
    
    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
}

private extension String {
    func split(byChunkSize length: Int) -> [String] {
        var start = startIndex
        var results = [Substring]()
        
        while start < endIndex {
            let end = index(start, offsetBy: length, limitedBy: endIndex) ?? endIndex
            results.append(self[start..<end])
            start = end
        }
        
        return results.map(String.init)
    }
}
