//
//  WatchAccount.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct WatchAccount: Identifiable {
    init(accountID: String,
         address: String,
         isResidential: Bool) {
        self.accountID = accountID
        self.address = address
        self.isResidential = isResidential
    }
    
    init(account: Account) {
        self.accountID = account.accountNumber
        self.address = account.address ?? ""
        self.isResidential = account.isResidential
        self.account = account
    }
    
    var id: UUID = UUID()
    let accountID: String
    let address: String
    let isResidential: Bool
    var account: Account? = nil
}

extension WatchAccount: Equatable {
    static func == (lhs: WatchAccount, rhs: WatchAccount) -> Bool {
        lhs.id == rhs.id
    }
}
