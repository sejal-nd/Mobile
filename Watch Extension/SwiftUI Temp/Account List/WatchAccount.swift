//
//  WatchAccount.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct WatchAccount: Identifiable {
    init(id: UUID = UUID(),
         accountID: String,
         address: String,
         isResidential: Bool,
         details: AccountDetail? = nil) {
        self.id = id
        self.accountID = accountID
        self.address = address
        self.isResidential = isResidential
        self.details = details
    }
    
    init(details: AccountDetail) {
        self.accountID = details.accountNumber
        self.address = details.address ?? ""
        self.isResidential = details.isResidential
        self.details = details
    }
    
    var id: UUID = UUID()
    let accountID: String
    let address: String
    let isResidential: Bool
    var details: AccountDetail? = nil
}

extension WatchAccount: Equatable {
    static func == (lhs: WatchAccount, rhs: WatchAccount) -> Bool {
        lhs.id == rhs.id
    }
}
