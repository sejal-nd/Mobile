//
//  GenericResponse.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct GenericResponse: Decodable {
    public var success: Bool
    public var confirmationNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case success = "success"
        case confirmationNumber = "confirmationNumber"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.success = try data.decode(Bool.self,
                                       forKey: .success)
        self.confirmationNumber = try data.decodeIfPresent(String.self,
                                                           forKey: .confirmationNumber)
    }
}
