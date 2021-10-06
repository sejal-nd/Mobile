//
//  ValidateZipCodeRequest.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 01/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ValidateZipCodeRequest: Encodable {
    var zipCode: String = ""

    enum CodingKeys: String, CodingKey {
        case zipCode = "zipCode"
    }
}
