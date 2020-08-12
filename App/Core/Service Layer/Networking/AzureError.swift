//
//  NetworkError.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AzureError: Decodable {
    public var code: String
    public var description: String?
    public var context: String?
    
    enum CodingKeys: String, CodingKey {
        case meta = "meta"
        
        case code = "code"
        case description = "description"
        case context = "context"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metaContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                          forKey: .meta)
        
        self.code = try metaContainer.decode(String.self,
                                             forKey: .code)
        self.description = try metaContainer.decodeIfPresent(String.self,
                                                             forKey: .description)
        self.context = try metaContainer.decodeIfPresent(String.self,
                                                         forKey: .context)
    }
}
