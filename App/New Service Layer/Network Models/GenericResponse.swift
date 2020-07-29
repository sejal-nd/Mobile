//
//  GenericResponse.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct GenericResponse: Decodable {
    public var confirmationNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case confirmationNumber = "confirmationNumber"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.confirmationNumber = try container.decodeIfPresent(String.self,
                                                           forKey: .confirmationNumber)
    }
}
