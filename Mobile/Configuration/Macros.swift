//
//  Macros.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

func dLog(_ message: String? = nil, filename: String = #file, function: String = #function, line: Int = #line) {
    if Environment.shared.environmentName != .prod {
        if let message = message {
            NSLog("[%@: %d] %@ - %@", (filename as NSString).lastPathComponent, line, function, message)
        } else {
            NSLog("[%@: %d] %@", (filename as NSString).lastPathComponent, line, function)
        }
    }
}
