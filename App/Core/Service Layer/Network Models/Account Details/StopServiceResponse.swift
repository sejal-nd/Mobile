//
//  StopServiceResponse.swift
//  Mobile
//
//  Created by RAMAITHANI on 29/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct StopServiceResponse: Decodable {
    
    let confirmationNo: String?
    let isManualCallResult: Bool?
    let confirmationMessage: String

    enum CodingKeys: String, CodingKey {
        
        case confirmationNo = "ConfirmationNo"
        case isManualCallResult = "IsManualCallResult"
        case confirmationMessage = "ConfirmationMessage"
    }
}
