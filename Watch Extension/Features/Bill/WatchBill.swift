//
//  WatchBill.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct WatchBill: Identifiable {
//    init(id: UUID = UUID(),
//         isPowerOn: Bool,
//         estimatedRestoration: String? = nil,
//         outageStatus: OutageStatus? = nil) {
//        self.id = id
//        self.isPowerOn = isPowerOn
//        self.estimatedRestoration = estimatedRestoration
//        self.outageStatus = outageStatus
//    }
    
//    init(accountDetails: AccountDetail) {
//
//        self.accountDetails = accountDetails
//    }
//
    var id: UUID = UUID()
//
//
//
//    let pastDueText: String
//    let pastDueAmountText: String
//    let pastDueDateText: String
//
//    let currentBillAmountText: String
//    let currentBillDateText: String
//
//    let paymentReceivedAmountText: String
//    let paymentReceivedDateText: String
//
//    let pendingPaymentsTotalText: String
//
//    let remainingBalanceDueText: String
    
    var accountDetails: AccountDetail? = nil
}

extension WatchBill: Equatable {
    static func == (lhs: WatchBill, rhs: WatchBill) -> Bool {
        lhs.id == rhs.id
    }
}
