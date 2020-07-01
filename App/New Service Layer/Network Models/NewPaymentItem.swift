//
//  NewPaymentItem.swift
//  Mobile
//
//  Created by Cody Dillon on 7/1/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewPaymentItem: Decodable {
    
    let amount: Double
    let date: Date?
    let status: NewPaymentStatus
    
    enum CodingKeys: String, CodingKey {
        case amount = "paymentAmount"
        case date = "paymentDate"
        case status
    }
    
    enum NewPaymentStatus: String, Decodable {
        case scheduled = "scheduled"
        case pending = "pending"
        case processing = "processing"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = try container.decode(Double.self, forKey: .amount)
        
        var statusStr = try container.decode(String.self, forKey: .status)
        if statusStr.lowercased() == "processed" {
            statusStr = "processing"
        }
        
        status = NewPaymentStatus(rawValue: statusStr.lowercased())! // TODO potential future refactor - throw a Decoding error with field name and type
        date = try container.decode(Date.self, forKey: .date)
        
        // Scheduled payments require dates
        guard status != .scheduled || date != nil else {
            throw NetworkingError.invalidResponse // TODO should we have this? handle it differently?
        }
    }
}
