//
//  Macros.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

func dLog(_ message: String? = nil, filename: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
        var logString = "[\((filename as NSString).lastPathComponent):\(line)] \(function)"
        if let message = message {
            logString += " - \(message)"
        }
        NSLog(logString)
    #endif
}
