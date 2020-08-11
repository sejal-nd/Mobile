//
//  DateRequest.swift
//  BGE
//
//  Created by Cody Dillon on 8/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct DateRequest: Encodable {
    let date: String
    
    init(date: Date) {
        self.date = DateFormatter.apiFormatterGMT.string(from: date)
    }
}
