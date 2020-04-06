//
//  NewSchedulePaymentResult.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewScheduledPaymentResult: Decodable {
    public var confirmationNumber: String
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case confirmationNumber = "confirmationNumber"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.confirmationNumber = try data.decode(String.self,
                                                  forKey: .confirmationNumber)
    }
}
