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
        Account(accountType:.Residential, accountNumber:"1234567890", address:"573 Elm Street", homeContactNumber: "4106939286"),
        Account(accountType:.Commercial, accountNumber:"9836621902", address:"E. Fort Ave, Ste. 200", homeContactNumber: "2128675309"),
        Account(accountType:.Residential, accountNumber:"7003238921", address:"E. Andre Street", homeContactNumber: "4437221234"),
        Account(accountType:.Residential, accountNumber:"5591032201", address:"7700 Presidents Street", homeContactNumber: "4102819489"),
        Account(accountType:.Residential, accountNumber:"5591032202", address:"7701 Presidents Street", homeContactNumber: "4108881324")
    ]
    
    func fetchAccounts(page: Int, offset: Int, completion: @escaping (ServiceResult<AccountPage>) -> Void) {
        completion(ServiceResult.Success(AccountPage(testAccounts, page:page, offset:offset, total:1)))
    }
    
    func fetchAccountDetail(account: Account, completion: @escaping (ServiceResult<AccountDetail>) -> Void) {
        let accountDetail = AccountDetail(accountInfo: account)
        completion(ServiceResult.Success(accountDetail))
    }
}
