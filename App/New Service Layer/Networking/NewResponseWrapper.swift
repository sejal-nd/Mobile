//
//  NewResponseWrapper.swift
//  Mobile
//
//  Created by Cody Dillon on 4/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewResponseContainer: Decodable { //<T: Decodable>
//    public let success: Bool
    public var data: Data?//T?
    public var error: EndpointError?
    
    enum CodingKeys: String, CodingKey {
        case data
        case success
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        print("NEW RESPONSE WRAPPER")

        // response contains data wrapper
//        if container.contains(.success) {
            print("Contains Data")
            //self.success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
            let isSuccess = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
            
            // first check for error
        if !isSuccess {//!self.success {
                print("ERROR")
                let container = try decoder.singleValueContainer()
                self.error = try container.decode(EndpointError.self)
            } else {
                print("DECODE DATA")
                self.data = try container.decode(Data.self, forKey: .data)
                print("DATA: \(data)")

            }
    
//        } else { // no response wrapper
//            print("no data")
//            let container = try decoder.singleValueContainer()
//            self.data = try container.decode(T.self)
//            self.success = true
//        }
    }
}
