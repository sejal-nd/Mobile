//
//  NewResponseWrapper.swift
//  Mobile
//
//  Created by Cody Dillon on 4/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewResponseWrapper<T: Decodable>: Decodable, EndpointErrorable {
    public let success: Bool?
    public let data: T?
    
    // endpoint error
    var errorCode: String?
    var errorMessage: String?
    
    public var error: EndpointErrorable? {
        get {
            if errorCode != nil && errorMessage != nil {
                return self
            }
            else {
                return nil
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
        case errorCode
        case errorMessage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.data) {
            self.data = try container.decode(T.self, forKey: .data)
            self.success = try container.decodeIfPresent(Bool.self, forKey: .success)
        }
        else {
            var container = try decoder.unkeyedContainer()
            self.data = try container.decode(T.self)
            self.success = true
        }
        
        self.errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}
