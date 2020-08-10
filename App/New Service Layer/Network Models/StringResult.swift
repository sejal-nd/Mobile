//
//  StringResult.swift
//  BGE
//
//  Created by Cody Dillon on 8/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct StringResult: Decodable {
    let value: String
    
    public init(from decoder: Decoder) throws {
        value = try decoder.singleValueContainer().decode(String.self)
    }
}
