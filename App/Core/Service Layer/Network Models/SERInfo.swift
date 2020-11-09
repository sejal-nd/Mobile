//
//  SERInfo.swift
//  Mobile
//
//  Created by Cody Dillon on 6/30/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct SERInfo: Decodable {
    let controlGroupFlag: String?
    let eventResults: [SERResult]
    
    enum CodingKeys: String, CodingKey {
        case controlGroupFlag = "ControlGroupFlag"
        case eventResults
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        controlGroupFlag = try container.decodeIfPresent(String.self, forKey: .controlGroupFlag)
        eventResults = try container.decodeIfPresent([SERResult].self, forKey: .eventResults) ?? []
    }
}

public struct SERContainer: Decodable {
    let serInfo: SERInfo
    
    enum CodingKeys: String, CodingKey {
        case serInfo = "SERInfo"
    }
}
