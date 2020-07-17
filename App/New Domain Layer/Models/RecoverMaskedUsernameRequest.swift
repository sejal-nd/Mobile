//
//  RecoverMaskedUsernameRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/16/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct RecoverMaskedUsernameRequest: Encodable {
    let phone: String
    let identifier: String
    let accountNumber: String
    
    enum CodingKeys: String, CodingKey {
        case phone
        case identifier
        case accountNumber = "account_number"
    }
}
