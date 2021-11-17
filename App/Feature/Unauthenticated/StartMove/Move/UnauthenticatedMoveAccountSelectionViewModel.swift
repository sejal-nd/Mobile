//
//  UnauthenticatedMoveAccountSelectionViewModel.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 03/11/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
class UnauthenticatedMoveAccountSelectionViewModel {
    var accountsList = [AccountLookupResult]()
    var selectedAccount : AccountLookupResult?
    var unauthMoveData : UnauthMoveData!

    init(unauthMoveData: UnauthMoveData) {

        self.unauthMoveData = unauthMoveData
        accountsList = unauthMoveData.accountLookup
        if !unauthMoveData.selectedAccountNumber.isEmpty {
            if let selAccount = accountsList.filter({ $0.accountNumber == unauthMoveData.selectedAccountNumber }).first {
                setSelectedAccount(account: selAccount)
            }else {
                
            }
        }
    }

    var canEnableContinue: Bool {

        if let selectedAccount = selectedAccount, let selectedAccountNum = selectedAccount.accountNumber {
            if !selectedAccountNum.isEmpty {
                return true
            }
        }
        return false
    }

    func getMaskedAccountNumber(_ number:String) -> String{
        
        return String(repeating: "*", count: Swift.max(0, number.count-4)) + number.suffix(4)
    }

    func setSelectedAccount(account : AccountLookupResult){

        self.selectedAccount = account
        self.unauthMoveData.selectedAccountNumber = account.accountNumber!
    }

    func getUnauthMoveFlowData()-> UnauthMoveData {

        return unauthMoveData
    }
}
