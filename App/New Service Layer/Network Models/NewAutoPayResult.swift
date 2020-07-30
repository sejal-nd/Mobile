//
//  NewSchedulePaymentResult.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewAutoPayResult: Decodable {
    public var header: String
    public var message: String
    
    enum CodingKeys: String, CodingKey {
        case header = "header"
        case message = "message"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.header = try container.decode(String.self,
                                      forKey: .header)
        self.message = try container.decode(String.self,
                                       forKey: .message)
    }
}
