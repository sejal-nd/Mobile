//
//  AccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

///Defines a single paginated result set of an accounts list.
//struct AccountPage {
//    let accounts: [Account]
//    let page: Int
//    let offset: Int
//    let total: Int
//    
//    init(_ accounts:[Account], page: Int, offset: Int, total:Int) {
//        self.accounts = accounts
//        self.page = page
//        self.offset = offset
//        self.total = total
//    }
//}

/// The AccountService protocol defines the interface necessary
/// to deal with fetching and updating accoutns associated with
/// the currently logged in customer.
protocol AccountService {

    
    /// Fetch a page of accounts for the current customer.
    ///
    /// - Parameters:
    ///   - page: the page number to fetch
    ///   - offset: the page offset
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain an AccountPage on success, or a ServiceError on failure.
    func fetchAccounts(completion: @escaping (_ result: ServiceResult<[Account]>) -> Swift.Void)
    
    
    /// Fetch an accounts detailed information.
    ///
    /// - Parameters:
    ///   - account: the account to fetch
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the AccountDetails on success, or a ServiceErro on failure.
    func fetchAccountDetail(account: Account, completion: @escaping (_ result: ServiceResult<AccountDetail>) -> Swift.Void)
}
