//
//  MockAccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockAccountService: AccountService {
    
    var mockAccounts: [Account] = [
        Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!,
        Account.from(["accountNumber": "9836621902", "address": "E. Fort Ave, Ste. 200"])!,
    ]
    var mockAccountDetails: [AccountDetail] = [
        AccountDetail.from(["accountNumber": "1234567890", "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])!,
        AccountDetail.from(["accountNumber": "9836621902", "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])!,
    ]
    
    func fetchAccounts(completion: @escaping (ServiceResult<[Account]>) -> Void) {
        AccountsStore.sharedInstance.accounts = mockAccounts
        AccountsStore.sharedInstance.currentAccount = mockAccounts[0]
        completion(ServiceResult.Success(mockAccounts as [Account]))
    }
    
    func fetchAccountDetail(account: Account, completion: @escaping (ServiceResult<AccountDetail>) -> Void) {
        guard let accountIndex = mockAccounts.index(of: account) else {
            completion(.Failure(ServiceError(serviceMessage: "No account detail found for the provided account.")))
            return
        }
        let accountDetail = mockAccountDetails[accountIndex]
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
