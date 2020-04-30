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
    public var error: EndpointErrorable?
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
        case errorCode = "code"
        case errorMessage = "description"
        case meta
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // first check for error
        if container.contains(.meta) {
            self.success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
            let meta = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .meta)
            let errorCode = try meta.decodeIfPresent(String.self, forKey: .errorCode)
            let errorMessage = try meta.decodeIfPresent(String.self, forKey: .errorMessage)
            
            self.error = EndpointError(errorCode: errorCode, errorMessage: errorMessage)
        }
        else {
            // check for and decode data object
            if container.contains(.data) {
                self.success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
                self.data = try container.decode(T.self, forKey: .data)
            }
            else {
                // if data is not present, then decode the data object as a single value container
                let container = try decoder.singleValueContainer()
                self.data = try container.decode(T.self)
                self.success = true
            }
        }
    }
}
