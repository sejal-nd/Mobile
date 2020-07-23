//
//  AzureResponseWrapper.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AzureResponseWrapper<T: Decodable>: Decodable {
    public let success: Bool
    public var data: T?
    public var error: EndpointError?
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        print("AzureResponseWrapper")
                
        // response contains data wrapper
        if container.contains(.success) {
            print("Contains Data 1")
            self.success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
            
            // first check for error
            if !self.success {
                print("ERROR 1")
                let container = try decoder.singleValueContainer()
                self.error = try container.decode(EndpointError.self)
            } else {
                print("DECODE DATA 1")
                self.data = try container.decode(T.self, forKey: .data)
                print("DATA 1: \(data)")
                
            }
        } else { // no response wrapper
            print("no data")
            let container = try decoder.singleValueContainer()
            self.data = try container.decode(T.self)
            self.success = true
        }
    }
}
