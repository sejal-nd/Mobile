//
//  AnonOutageRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AnonOutageRequest: Encodable {
    let phoneNumber: String?
    let accountNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone"
        case accountNumber = "account_number"
    }
}
