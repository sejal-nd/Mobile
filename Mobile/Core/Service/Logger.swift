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
}

func APILog(filename: String,
            requestId: String,
            path: String?,
            method: HttpMethod,
            logType: LogType,
            message: String?) {
#if DEBUG
    let messageLength = message?.count ?? 0
    let CHUNK_SIZE = 800
    let countInt = messageLength / CHUNK_SIZE
    if messageLength > CHUNK_SIZE {
        NSLog("[%@][%@][%@] %@ %@ [LOG SPLIT INTO %d PARTS]", filename, requestId, path ?? "", method.rawValue, logType.rawValue, countInt + 1)
        for i in 0..<countInt {
            let start = String.Index(encodedOffset: i * CHUNK_SIZE)
            let end = message!.index(start, offsetBy: CHUNK_SIZE)
            NSLog("[%@ PART %d]\n%@", requestId, i + 1, String(message![start..<end]))
        }
        let lastChunk = message!.suffix(from: String.Index(encodedOffset: (countInt * CHUNK_SIZE)))
        NSLog("[%@ PART %d]\n%@", requestId, countInt + 1, String(lastChunk))
        //NSLog("--- END \(countInt + 1) PART LOG MESSAGE ---")
    } else {
        if let message = message, !message.isEmpty {
            NSLog("[%@][%@][%@] %@ %@: %@", filename, requestId, path ?? "", method.rawValue, logType.rawValue, message)
        } else {
            NSLog("[%@][%@][%@] %@ %@", filename, requestId, path ?? "", method.rawValue, logType.rawValue)
        }
    }
#endif
}
