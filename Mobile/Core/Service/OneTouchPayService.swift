//
//  OneTouchPayService.swift
//  Mobile
//
//  Created by Marc Shilling on 5/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class OneTouchPayService {
    
    func getOneTouchPayDictionary() -> [String: WalletItem] {
        let oneTouchPayDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.OneTouchPayDictionary)!
        var toReturn = [String: WalletItem]()
        for (key, value) in oneTouchPayDictionary {
            toReturn[key] = WalletItem.from(value as! NSDictionary)
        }
        return toReturn
    }
    
    func oneTouchPayItem(forCustomerNumber customerNumber: String) -> WalletItem? {
        let oneTouchPayDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.OneTouchPayDictionary)!
        if let walletItemDict = oneTouchPayDictionary[customerNumber] as? NSDictionary {
            return WalletItem.from(walletItemDict)!
        }
        return nil
    }
    
    func setOneTouchPayItem(walletItemID: String, maskedWalletItemAccountNumber: String, bankOrCard: BankOrCard, forCustomerNumber number: String?) {
        if let customerNumber = number {
            var oneTouchPayDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.OneTouchPayDictionary)!
            oneTouchPayDictionary[customerNumber] = [
                "walletItemID": walletItemID,
                "maskedWalletItemAccountNumber": maskedWalletItemAccountNumber,
                "paymentCategoryType": bankOrCard == .bank ? PaymentCategoryType.check.rawValue : PaymentCategoryType.credit.rawValue,
                "bankAccountType": bankOrCard == .bank ? BankAccountType.checking.rawValue : BankAccountType.card.rawValue
            ]
            UserDefaults.standard.set(oneTouchPayDictionary, forKey: UserDefaultKeys.OneTouchPayDictionary)
        } else {
            dLog(message: "ERROR: Could not set One Touch Pay item because customer number is nil")
        }
    }
    
    func deleteTouchPayItem(forCustomerNumber customerNumber: String) {
        var oneTouchPayDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.OneTouchPayDictionary)!
        oneTouchPayDictionary.removeValue(forKey: customerNumber)
        UserDefaults.standard.set(oneTouchPayDictionary, forKey: UserDefaultKeys.OneTouchPayDictionary)
    }
    
    func getOneTouchPayDisplayString(forCustomerNumber customerNumber: String) -> String {
        if let oneTouchPayItem = self.oneTouchPayItem(forCustomerNumber: customerNumber) {
            switch oneTouchPayItem.bankOrCard {
            case .bank:
                return String(format: NSLocalizedString("You are currently using bank account %@ for One Touch Pay.", comment: ""), "**** \(oneTouchPayItem.maskedWalletItemAccountNumber!)")
            case .card:
                return String(format: NSLocalizedString("You are currently using card %@ for One Touch Pay.", comment: ""), "**** \(oneTouchPayItem.maskedWalletItemAccountNumber!)")
            }
        }
        return NSLocalizedString("Turn on One Touch Pay to easily pay from the Home screen and set this payment account as default.", comment: "")
    }

}
