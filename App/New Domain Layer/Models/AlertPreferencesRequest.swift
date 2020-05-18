//
//  AlertPreferenceRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// todo naming confusing

struct AlertPreferencesRequest: Encodable {
    let alertPreferenceRequests: [AlertPreferenceRequest]
    
    enum CodingKeys: String, CodingKey {
        case alertPreferenceRequests = "alertPreferenceRequests"
    }
}

struct AlertPreferenceRequest: Encodable {
    let isActive: Bool
    let type: String
    let programName: String
    var daysPrior: String? = nil
}
