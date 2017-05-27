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
    
    func oneTouchPayItem(forCustomerNumber number: String?) -> WalletItem? {
        if let customerNumber = number {
            let oneTouchPayDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.OneTouchPayDictionary)!
            if let walletItemDict = oneTouchPayDictionary[customerNumber] as? NSDictionary {
                return WalletItem.from(walletItemDict)!
            }
        } else {
            dLog(message: "ERROR: Could not set One Touch Pay item because customer number is nil")
        }
        return nil
    }
    
    func setOneTouchPayItem(_ item: WalletItem, forCustomerNumber number: String?) {
        if let customerNumber = number {
            var oneTouchPayDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.OneTouchPayDictionary)!
            oneTouchPayDictionary[customerNumber] = ["walletItemID": item.walletItemID!]
            UserDefaults.standard.set(oneTouchPayDictionary, forKey: UserDefaultKeys.OneTouchPayDictionary)
        } else {
            dLog(message: "ERROR: Could not set One Touch Pay item because customer number is nil")
        }
    }

}
