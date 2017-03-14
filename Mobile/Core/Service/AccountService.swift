//
//  AccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct AccountPage {
    let accounts: [Account]
    let page: Int
    let offset: Int
    let total: Int
    
    init(_ accounts:[Account], page: Int, offset: Int, total:Int) {
        self.accounts = accounts
        self.page = page
        self.offset = offset
        self.total = total
    }
}

protocol AccountService {

    func fetchAccounts(page: Int, offset: Int, completion: @escaping (_ result: ServiceResult<AccountPage>) -> Swift.Void)
    
    func fetchAccountDetail(account: Account, completion: @escaping (_ result: ServiceResult<AccountDetail>) -> Swift.Void)
}
