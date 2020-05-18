//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewSAMLToken: Decodable {
    public var token: String?
    
    public var errorCode: String?
    public var errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case meta = "meta"
        case token = "assertion"
        
        case errorCode = "code"
        case errorDescription = "description"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.token = try data.decode(String.self,
                                     forKey: .token)
        
        if container.contains(.meta) {
            let meta = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                     forKey: .meta)
            
            self.errorCode = try meta.decode(String.self,
                                             forKey: .errorCode)
            self.errorDescription = try meta.decode(String.self,
                                                    forKey: .errorDescription)
        }
    }
}
