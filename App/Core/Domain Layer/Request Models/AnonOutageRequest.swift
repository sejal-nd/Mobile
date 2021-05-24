//
//  AnonOutageRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// Used for outage status
public struct AnonOutageRequest: Encodable {
    let phoneNumber: String?
    let accountNumber: String?
    let auid: String?
    
    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone"
        case accountNumber = "account_number"
        case auid
    }
}
