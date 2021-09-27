//
//  StopServiceFlowData.swift
//  EUMobile
//
//  Created by RAMAITHANI on 16/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct StopServiceFlowData {
    
    let workDays: [WorkdaysResponse.WorkDay]
    var selectedDate: Date
    let currentPremise: PremiseInfo
    let currentAccount: Account
    let currentAccountDetail: AccountDetail
    let hasCurrentServiceAddressForBill: Bool
    var mailingAddress: MailingAddress?
}
