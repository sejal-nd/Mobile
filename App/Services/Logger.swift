//
//  Logger.swift
//  Mobile
//
//  Created by Marc Shilling on 1/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

enum LogType: String {
    case request = "REQUEST"
    case response = "RESPONSE"
    case error = "ERROR"
    case canceled = "CANCELED"
    
    var symbol: String {
        switch self {
        case .request:
            return "📬"
        case .response:
            return "✅"
        case .error:
            return "❌"
        case .canceled:
            return "🛑"
        }
    }
}

func dLog(_ message: @autoclosure () -> String? = nil,
          filename: String = #file,
          function: String = #function,
          line: Int = #line) {
    #if DEBUG
    if let message = message() {
        NSLog("[%@: %d] %@ - %@", (filename as NSString).lastPathComponent, line, function, message)
        #if os(watchOS)
        // Show log messages for watch in iOS console
        WatchSessionManager.shared.transferUserInfo(userInfo: ["console": message])
        #endif
    } else {
        NSLog("[%@: %d] %@", (filename as NSString).lastPathComponent, line, function)
    }
    #endif
}

fileprivate let chunkSize = 800

func APILog<T>(_ callerType: @autoclosure () -> T.Type,
               requestId: @autoclosure () -> String = "",
               path: @autoclosure () -> String?,
               method: @autoclosure () -> HttpMethod,
               logType: @autoclosure () -> LogType,
               message: @autoclosure () -> String?) {
    
    guard ProcessInfo.processInfo.arguments.contains("-shouldLogAPI") else { return }
    
    
    print("test121212")
    if let message = message() {
        print(message)
    }
    
    #if DEBUG
    let callerName = "\(callerType())"
    let requestId = requestId()
    let path = path() ?? ""
    let method = method().rawValue
    let logType = logType()
    
    guard let message = message(), !message.isEmpty else {
        NSLog("%@ [%@][%@][%@] %@ %@", logType.symbol, callerName, requestId, path, method, logType.rawValue)
        return
    }
    
    if message.count > chunkSize {
        let messageChunks = message.split(byChunkSize: chunkSize)
        NSLog("%@ [%@][%@][%@] %@ %@ [LOG SPLIT INTO %d PARTS]", logType.symbol, callerName, requestId, path, method, logType.rawValue, messageChunks.count)
        for (offset, messageChunk) in messageChunks.enumerated() {
            NSLog("✂️ [%@ PART %d] %@", requestId, offset + 1, messageChunk)
        }
    } else {
        NSLog("%@ [%@][%@][%@] %@ %@: %@", logType.symbol, callerName, requestId, path, method, logType.rawValue, message)
    }
    #endif
}

extension String {
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
