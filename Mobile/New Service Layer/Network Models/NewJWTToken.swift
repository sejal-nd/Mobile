//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewJWTToken: Decodable {
    public var token: String?
    
//    public var errorCode: String?
//    public var errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
//        case data = "data"
//        case meta = "meta"
        case token = "access_token"
        
//        case errorCode = "code"
//        case errorDescription = "description"
    }
    
//    public init(from decoder: Decoder) throws {
//        var container = try decoder.unkeyedContainer()
//        
//        print("containre: \(container)")
//        
//        self.token = try container.decode(String.self)
////        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
////                                                 forKey: .data)
////        self.token = try container.decode(String.self, forKey: .token)
//        
////        if container.contains(.meta) {
////            let meta = try container.nestedContainer(keyedBy: CodingKeys.self,
////                                                     forKey: .meta)
////
////            self.errorCode = try meta.decode(String.self,
////                                             forKey: .errorCode)
////            self.errorDescription = try meta.decode(String.self,
////                                                    forKey: .errorDescription)
////        }
//    }
}
