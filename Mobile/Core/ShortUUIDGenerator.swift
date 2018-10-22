//
//  ShortUUIDGenerator.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

struct ShortUUIDGenerator {
    private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    private static let maxBase = 62
    
    static func getUUID(withBase base: Int = maxBase, length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int.random(in: 0..<min(base, maxBase))
            code.append(base62chars[random])
        }
        return code
    }
}
