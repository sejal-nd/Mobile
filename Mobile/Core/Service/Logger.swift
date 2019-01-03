//
//  Logger.swift
//  Mobile
//
//  Created by Marc Shilling on 1/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

func APILog(filename: String, requestId: String, path: String?, method: HttpMethod, message: String) {
#if DEBUG
    let logString = String(format: "[%@][%@][%@] %@ %@", filename, requestId, path ?? "", method.rawValue, message)
    let logStringLength = message.count
    let CHUNK_SIZE = 800
    let countInt = logStringLength / CHUNK_SIZE
    if logStringLength > CHUNK_SIZE {
        NSLog("--- BEGIN \(countInt + 1) PART LOG MESSAGE ---")
        for i in 0..<countInt {
            let start = String.Index(encodedOffset: i * CHUNK_SIZE)
            let end = logString.index(start, offsetBy: CHUNK_SIZE)
            NSLog("[PART %d]\n%@", i + 1, String(logString[start..<end]))
        }
        let lastChunk = logString.suffix(from: String.Index(encodedOffset: (countInt * CHUNK_SIZE)))
        NSLog("[PART %d]\n%@", countInt + 1, String(lastChunk))
        NSLog("--- END \(countInt + 1) PART LOG MESSAGE ---")
    } else {
        NSLog("%@", logString)
    }
    
    //NSLog("[MCSApi][%@][%@] %@ %@", requestId, path, method.rawValue, message)
#endif
}
