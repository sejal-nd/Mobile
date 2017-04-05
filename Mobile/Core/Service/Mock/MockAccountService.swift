//
//  MockAccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct MockAccountService : AccountService {
    
    let testAccounts = [
        Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"]),
        Account.from(["accountNumber": "9836621902", "address": "E. Fort Ave, Ste. 200"]),
        Account.from(["accountNumber": "7003238921", "address": "E. Andre Street"]),
        Account.from(["accountNumber": "5591032201", "address": "7700 Presidents Street"]),
        Account.from(["accountNumber": "5591032202", "address": "7701 Presidents Street"]),
    ]
    
    func fetchAccounts(completion: @escaping (ServiceResult<[Account]>) -> Void) {
        completion(ServiceResult.Success(testAccounts as! [Account]))
    }
    
    func fetchAccountDetail(account: Account, completion: @escaping (ServiceResult<AccountDetail>) -> Void) {
        let accountDetail = AccountDetail(accountInfo: account)
        completion(ServiceResult.Success(accountDetail))
    }
}
