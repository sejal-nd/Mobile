//
//  NewResponseWrapper.swift
//  Mobile
//
//  Created by Cody Dillon on 4/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AzureResponseContainer<T: Decodable>: Decodable {
    public var data: T?
    public var error: AzureError?
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let isSuccess = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        if isSuccess {
            self.data = try container.decodeIfPresent(T.self, forKey: .data)
        } else {
            let container = try decoder.singleValueContainer()
            self.error = try container.decode(AzureError.self)
        }
    }
}
