//
//  ValidateCodeRequest.swift
//  Mobile
//
//  Created by Tiwari, Anurag on 29/05/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ValidateCodeRequest: Encodable {
    let phone: String
    let flowType: String
    let pin: String
}
