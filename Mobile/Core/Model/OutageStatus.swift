//
//  OutageStatus.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct OutageStatus {
    let accountInfo: Account
    let gasOnly: Bool
    let homeContactNumbner: String
    let isPasswordProtected: Bool
    let isUserAuthenticated: Bool
    let activeOutage: Bool
    let outageMessageTitle: String
    let outageMessage: String
    let restorationTime: Date
    let outageReported: Bool
    let accountFinaled: Bool
    let accountPaid: Bool
    
}
