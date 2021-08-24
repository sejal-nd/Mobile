//
//  AzureB2CError.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 8/12/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AzureB2CError: Decodable {
    public var error: String
    public var errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}
