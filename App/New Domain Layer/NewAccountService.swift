//
//  NewAccountService.swift
//  Mobile
//
//  Created by Cody Dillon on 7/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewAccountService {
    
    static func fetchAccounts(completion: @escaping (Result<[Account], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .accounts) { (result: Result<[Account], NetworkingError>) in
            switch result {
            case .success(let accounts):
                let sortedAccounts = accounts
                    .filter { !$0.isPasswordProtected } // Filter out password protected accounts
                    .sorted { ($0.isDefault && !$1.isDefault) || (!$0.isFinaled && $1.isFinaled) }
                
                AccountsStore.shared.accounts = sortedAccounts
                AccountsStore.shared.currentIndex = 0
                completion(.success(sortedAccounts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchAccountDetails(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber,
                                    payments: Bool = true,
                                    programs: Bool = true,
                                    budgetBilling: Bool = true,
                                    alertPreferenceEligibilities: Bool = false,
                                    completion: @escaping (Result<AccountDetail, NetworkingError>) -> ()) {
        
        var queryItems = [(String, String)]()
        if !payments {
            queryItems.append(("payments", "false"))
        }
        if !programs {
            queryItems.append(("programs", "false"))
        }
        if !budgetBilling {
            queryItems.append(("budgetBilling", "false"))
        }
        
        if alertPreferenceEligibilities {
            queryItems.append(("alertPreferenceEligibilities", "true"))
        }
        
        let queryStringSubSequence = queryItems
            .map { $0.0 + "=" + $0.1 }
            .reduce("?") { $0 + $1 + "&" }
            .dropLast() // drop the last "&"
        let queryString = String(queryStringSubSequence)
        
        
        NetworkingLayer.request(router: .accountDetails(accountNumber: accountNumber, queryString: queryString)) { (result: Result<AccountDetail, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data))
                //                NetworkTest.shared.wallet()
                
                //                NetworkTest.shared.payment(accountNumber: data.accountNumber)
                
                
                
                //                AuthenticatedService.fetchAlertBanner(bannerOnly: true, stormOnly: false) { (result: Result<NewSharePointAlert, NetworkingError>) in
                //                    switch result {
                //                    case .success(let data):
                //                        completion(.success(data.alerts))
                //                    case .failure(let error):
                //                        completion(.failure(error))
                //                    }
            //                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    #if os(iOS)
    static func updatePECOReleaseOfInfoPreference(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber, selectedIndex: Int, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .updateReleaseOfInfo(accountNumber: accountNumber, encodable: ReleaseOfInfoRequest(selectedIndex: selectedIndex)), completion: completion)
    }

    static func setDefaultAccount(accountNumber: String, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .setDefaultAccount(accountNumber: accountNumber), completion: completion)
    }
    
    static func setAccountNickname(nickname: String, accountNumber: String, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .setAccountNickname(request: AccountNicknameRequest(accountNumber: accountNumber, accountNickname: nickname)), completion: completion)
    }
    #endif
    
    static func fetchSSOData(accountNumber: String, premiseNumber: String) {
           
    }
    
    static func fetchFirstFuelSSOData(accountNumber: String, premiseNumber: String) {
           
    }
    
    static func fetchScheduledPayments(accountNumber: String) {
           
    }
    
    static func fetchSERResults(accountNumber: String) {
           
    }
}
