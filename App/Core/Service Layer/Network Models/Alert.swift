//
//  Alert.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct Alert: Decodable {
    public var title: String
    public var message: String
    public var order: Int
    public var type: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case message = "Message"
        case order = "Order"
        case type = "AlertTypeString"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try container.decodeIfPresent(String.self,
                                          forKey: .title) ?? ""
        self.message = try container.decodeIfPresent(String.self,
                                            forKey: .message) ?? ""
        self.order = try container.decodeIfPresent(Int.self,
                                                 forKey: .order) ?? 0
        self.type = try container.decodeIfPresent(String.self,
                                                 forKey: .type) ?? "None"
    }
}
