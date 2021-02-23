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
    public var isEnabled: Bool?
    public var customerType: String?
    public var modified: Date?
    public var created: Date?
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case message = "Message"
        case isEnabled = "Enable"
        case customerType = "CustomerType"
        case modified = "Modified"
        case created = "Created"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try container.decode(String.self,
                                          forKey: .title)
        self.message = try container.decode(String.self,
                                            forKey: .message)
        self.isEnabled = try container.decodeIfPresent(Bool.self,
                                              forKey: .isEnabled)
        self.customerType = try container.decodeIfPresent(String.self,
                                                 forKey: .customerType)
        self.modified = try container.decodeIfPresent(Date.self,
                                             forKey: .modified)
        self.created = try container.decodeIfPresent(Date.self,
                                            forKey: .created)
    }
}
