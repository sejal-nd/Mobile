//
//  WorkdaysRequest.swift
//  Mobile
//
//  Created by RAMAITHANI on 12/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct WorkdaysRequest: Encodable {
    let addressMrID: String
    let isGasOff: Bool
    let premiseOperationCenter: String
    let isStart: Bool

    init(addressMrID: String, isGasOff: Bool, premiseOperationCenter: String, isStart: Bool) {
        self.addressMrID = addressMrID
        self.isGasOff = isGasOff
        self.premiseOperationCenter = premiseOperationCenter
        self.isStart = isStart
    }
    
    enum CodingKeys: String, CodingKey {
        case addressMrID = "AddressMrID"
        case isGasOff = "IsGasOff"
        case premiseOperationCenter = "PremiseOperationCenter"
        case isStart = "IsStart"
    }
}
