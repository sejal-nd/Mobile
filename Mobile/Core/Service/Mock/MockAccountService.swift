//
//  MockAccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockAccountService: AccountService {
    
    var testAccounts: [Account] = []
    var testAccountDetails: [AccountDetail] = []
    
    func fetchAccounts(completion: @escaping (ServiceResult<[Account]>) -> Void) {
        AccountsStore.sharedInstance.accounts = testAccounts
        AccountsStore.sharedInstance.currentAccount = testAccounts[0]
        completion(ServiceResult.Success(testAccounts as [Account]))
    }
    
    func fetchAccountDetail(account: Account, completion: @escaping (ServiceResult<AccountDetail>) -> Void) {
        guard let accountIndex = testAccounts.index(of: account) else {
            completion(.Failure(ServiceError(serviceMessage: "No account detail found for the provided account.")))
            return
        }
        let accountDetail = testAccountDetails[accountIndex]
        completion(ServiceResult.Success(accountDetail))
    }
    
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Success(()))
    }
    
    func setDefaultAccount(account: Account, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Success(()))
    }
    
    func fetchSSOData(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<SSOData>) -> Void) {
        let ssoData = SSOData.from(["utilityCustomerId": "1234", "ssoPostURL": "https://google.com", "relayState": "https://google.com", "samlResponse": "test"])!
        completion(ServiceResult.Success(ssoData))
    }
}
