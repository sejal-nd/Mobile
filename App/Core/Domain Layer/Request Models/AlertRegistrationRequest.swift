//
//  AlertRegistrationRequest.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AlertRegistrationRequest: Encodable {
    let notificationToken: String?
    let notificationProvider: String?
    let mobileClient: MobileClient
    let setDefaults: Bool
        
    public struct MobileClient: Encodable {
        let id: String
        let version: String
        let platform = "IOS"
    }
}
