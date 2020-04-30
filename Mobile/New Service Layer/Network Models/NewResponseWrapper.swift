//
//  NewResponseWrapper.swift
//  Mobile
//
//  Created by Cody Dillon on 4/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewResponseWrapper<T: Decodable>: Decodable {
    public let success: Bool?
    public let data: T?
    public var error: EndpointErrorable?
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
        case errorCode
        case errorMessage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // first check for error
        if container.contains(.errorMessage) {
            let errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
            let errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
            
            self.data = nil
            self.success = false
            self.error = EndpointError(errorCode: errorCode, errorMessage: errorMessage)
        }
        else {
            // check for and decode data object
            if container.contains(.data) {
                self.data = try container.decode(T.self, forKey: .data)
                self.success = try container.decodeIfPresent(Bool.self, forKey: .success)
            }
            else {
                // if data is not present, then decode the data object as the parent
                let container = try decoder.singleValueContainer()
                self.data = try container.decode(T.self)
                self.success = true
            }
        }
    }
}
