//
//  DebugOptions.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

func aLog<T>( _ object: @autoclosure() -> T, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    #if DEBUG
    let value = object()
    let stringRepresentation: String
    
    if let value = value as? CustomDebugStringConvertible {
        stringRepresentation = value.debugDescription
    } else if let value = value as? CustomStringConvertible {
        stringRepresentation = value.description
    } else {
        fatalError("gLog only works for values that conform to CustomDebugStringConvertible or CustomStringConvertible")
    }
    
    let fileURL = NSURL(string: file)?.lastPathComponent ?? "Unknown file"
    let queue = Thread.isMainThread ? "UI" : "BG"
    let gFormatter = DateFormatter()
    gFormatter.dateFormat = "HH:mm:ss:SSS"
    let timestamp = gFormatter.string(from: Date())
    
    print("✅ \(timestamp) {\(queue)} \(fileURL) > \(function)[\(line)]: " + stringRepresentation + "\n")
    #endif
}
