//
//  MoveServiceFlowData.swift
//  Mobile
//
//  Created by RAMAITHANI on 11/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct MoveServiceFlowData {
    
    let workDays: [WorkdaysResponse.WorkDay]
    var stopServiceDate: Date
    let currentPremise: PremiseInfo
    let currentAccount: Account
    let currentAccountDetail: AccountDetail
    let verificationDetail: StopServiceVerificationResponse?
    var startServiceDate: Date?
    var isOwner: Bool = true
    var addressLookupResponse: [AddressLookupResponse]?
}
