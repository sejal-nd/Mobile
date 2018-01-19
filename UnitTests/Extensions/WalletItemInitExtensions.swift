//
//  WalletItemInitExtensions.swift
//  Mobile
//
//  Created by Marc Shilling on 1/18/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

extension WalletItem {

    init(bankOrCard: BankOrCard = .bank) {
        self = WalletItem.from(["walletItemID": "1234", "maskedWalletItemAccountNumber": "1234"])!
        self.bankOrCard = bankOrCard
    }
    
    static func initVisaCard() -> WalletItem {
        var toReturn = WalletItem.from(["walletItemID": "1234", "cardIssuer": "Visa"])!
        toReturn.bankOrCard = .card
        return toReturn
    }
}
