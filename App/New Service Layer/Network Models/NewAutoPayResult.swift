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
        case data = "data"
        
        case header = "header"
        case message = "message"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        
        self.header = try data.decode(String.self,
                                      forKey: .header)
        self.message = try data.decode(String.self,
                                       forKey: .message)
    }
}
