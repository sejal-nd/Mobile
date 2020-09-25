//
//  PeakEnergySavingsViewModel.swift
//  Mobile
//
//  Created by Majumdar, Amit on 25/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

final class PeakEnergySavingsViewModel {
    
    let accountDetail: AccountDetail
    var opcoType: OpCo?
    
    init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
        if let opco = accountDetail.opcoType {
            opcoType = opco
        }
    }

    var programDescription: String {
        switch opcoType {
        case .pepco:
            return NSLocalizedString("A Peak Savings Day is scheduled for Pepco customers in Maryland on Friday, July 19, 2020, from 01:00 PM to 05:00 PM.", comment: "")
        case .delmarva:
            return accountDetail.isDelmarvaDelaware ?
                NSLocalizedString("A Peak Savings Day is scheduled for Delmarva Power customers in Delaware on Friday, July 19, 2020, from 01:00 PM to 05:00 PM.", comment: "") :
                NSLocalizedString("A Peak Savings Day is scheduled for Delmarva Power customers in Maryland on Friday, July 19, 2020, from 01:00 PM to 05:00 PM.", comment: "")
        default:
            return "No Peak Savings day is currently scheduled"
        }
    }

    var programSuggestion: String {
        return NSLocalizedString("Reduce your energy usage below 20,000 kWh during the Peak Savings Day on Friday, July 19, 2020, from 01:00 PM to 05:00 PM. The more you reduce, the greater the opportunity to earn a credit.", comment: "")
    }
}
