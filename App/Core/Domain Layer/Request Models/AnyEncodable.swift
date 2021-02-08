//
//  AnyEncodable.swift
//  BGE
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// An Encodable wrapper that allows us to encode any type that conforms to Encodable
struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        // allow the encoder to intercept a particular types encoding behavior (ex. URL)
        var container = encoder.singleValueContainer()
        try value.encode(to: &container)
    }
}

extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
    
    func data() -> Data {
        let encodable = AnyEncodable(value: self)
            
        do {
            let data = try JSONEncoder().encode(encodable)
            
            if ProcessInfo.processInfo.arguments.contains("-shoulLog.infoAPI") {
                Log.info("Request Body:\n\(String(decoding: data, as: UTF8.self))")
            }
            return data
        } catch {
            fatalError("Error encoding object: \(error)")
        }
    }
}

// Codable protocol with a default value used with enums
protocol DefaultCaseCodable: Codable & CaseIterable & RawRepresentable
where RawValue: Decodable, AllCases: BidirectionalCollection { }

extension DefaultCaseCodable {
    init(from decoder: Decoder) throws {
        self = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? Self.allCases.last!
    }
}
