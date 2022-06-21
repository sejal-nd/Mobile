//
//  B2CJWTRequest.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 8/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct B2CJWTRequest: Encodable {
    let customerID: String
    var ebillEligible: Bool = true
    var type: String = "residential"
    var lastname: String?
}
