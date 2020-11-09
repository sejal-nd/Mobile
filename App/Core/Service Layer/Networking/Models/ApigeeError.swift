//
//  ApigeeError.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ApigeeError: Decodable {
    public var error: String
    public var errorCode: String
    public var errorDescription: String
    
    enum CodingKeys: String, CodingKey {
        case error = "error"
        case errorCode = "error_code"
        case errorDescription = "error_description"
    }
}
