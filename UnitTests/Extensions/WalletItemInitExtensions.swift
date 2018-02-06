//
//  WalletItemInitExtensions.swift
//  Mobile
//
//  Created by Marc Shilling on 1/18/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

extension WalletItem {
    
    init(walletItemID: String? = "1234",
         walletExternalID: String? = "1234",
         maskedWalletItemAccountNumber: String? = "1234",
         nickName: String? = nil,
         walletItemStatusType: WalletItemStatusType? = .validated,
         walletItemStatusTypeBGE: WalletItemStatusTypeBGE? = .active,
         bankAccountNumber: String? = nil,
         bankAccountName: String? = nil,
         isDefault: Bool = false,
         cardIssuer: String? = nil,
         bankOrCard: BankOrCard = .bank) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        var map = [String: Any]()
        map["walletItemID"] = walletItemID
        map["walletExternalID"] = walletExternalID
        map["maskedWalletItemAccountNumber"] = maskedWalletItemAccountNumber
        map["nickName"] = nickName
        map["walletItemStatusType"] = walletItemStatusType
        map["walletItemStatusTypeBGE"] = walletItemStatusTypeBGE
        map["bankAccountNumber"] = bankAccountNumber
        map["bankAccountName"] = bankAccountName
        map["isDefault"] = isDefault
        map["cardIssuer"] = cardIssuer
        
        self = WalletItem.from(map as NSDictionary)!
        self.bankOrCard = bankOrCard
    }
}
