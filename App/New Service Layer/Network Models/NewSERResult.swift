//
//  NewSERResult.swift
//  Mobile
//
//  Created by Cody Dillon on 6/30/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewSERResult: Decodable, Equatable {
    let actualKWH: Double
    let baselineKWH: Double
    let eventStart: Date
    let eventEnd: Date
    let savingDollar: Double
    let savingKWH: Double
    
    enum CodingKeys: String, CodingKey {
        case actualKWH
        case baselineKWH
        case eventStart
        case eventEnd
        case savingDollar
        case savingKWH
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        eventStart = try container.decode(Date.self, forKey: .eventStart)
        eventEnd = try container.decode(Date.self, forKey: .eventEnd)
        
        actualKWH = try extractDouble(container.decodeIfPresent(String.self, forKey: .actualKWH)) ?? 0
        baselineKWH = try extractDouble(container.decodeIfPresent(String.self, forKey: .baselineKWH)) ?? 0
        savingDollar = try extractDouble(container.decodeIfPresent(String.self, forKey: .savingDollar)) ?? 0
        savingKWH = try extractDouble(container.decodeIfPresent(String.self, forKey: .savingKWH)) ?? 0
    }
}

fileprivate func extractDouble(_ obj: String?) throws -> Double? {
    var double: Double? = nil
    if let string = obj {
        double = Double(string)
    }

    return double
}
