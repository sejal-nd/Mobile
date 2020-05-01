//
//  NewResponseWrapper.swift
//  Mobile
//
//  Created by Cody Dillon on 4/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewResponseWrapper<T: Decodable>: Decodable {
    public let success: Bool
    public var data: T?
    public var error: EndpointError?
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // response contains data wrapper
        if container.contains(.success) {
            self.success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
            
            // first check for error
            if !self.success {
                let container = try decoder.singleValueContainer()
                self.error = try container.decode(EndpointError.self)
            } else {
                self.data = try container.decode(T.self, forKey: .data)
            }
        } else { // no response wrapper
            let container = try decoder.singleValueContainer()
            self.data = try container.decode(T.self)
            self.success = true
        }
    }
}
