//
//  NewResponseWrapper.swift
//  Mobile
//
//  Created by Cody Dillon on 4/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AzureResponseContainer: Decodable {
    public var data: Data?
    public var error: AzureError?
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let isSuccess = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        
        print("isSuccess: \(isSuccess)")
        
        if isSuccess {
            print("container: \(container)")
            print("test: \(try? container.decodeIfPresent(Data.self, forKey: .data))")
            self.data = try container.decodeIfPresent(Data.self, forKey: .data)
        } else {
            let container = try decoder.singleValueContainer()
            self.error = try container.decode(AzureError.self)
        }
    }
}
