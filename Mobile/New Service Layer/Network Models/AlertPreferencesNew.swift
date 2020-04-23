//
//  AlertPreferencesNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AlertPreferencesContainer: Decodable {
    public var preferences: [AlertPreferenceNew]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case preferences = "preferences"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.preferences = try data.decode([AlertPreferenceNew].self,
                                           forKey: .preferences)
    }
}

public struct AlertPreferenceNew: Decodable {
    public var programName: String
    public var type: String
    public var daysPrior: Int?
    public var alertThreshold: Int?
}

