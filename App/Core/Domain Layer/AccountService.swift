//
//  AccountService.swift
//  Mobile
//
//  Created by Cody Dillon on 7/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum AccountService {
    
    static func fetchAccounts(completion: @escaping (Result<[Account], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .accounts) { (result: Result<[Account], NetworkingError>) in
            switch result {
            case .success(let accounts):
                let sortedAccounts = accounts
                    .filter { !$0.isPasswordProtected } // Filter out password protected accounts
                    .sorted { ($0.isDefault && !$1.isDefault) || (!$0.isFinaled && $1.isFinaled) }
                
                AccountsStore.shared.accounts = sortedAccounts
                AccountsStore.shared.currentIndex = 0
                // Assign the Quick Actions
                RxNotifications.shared.configureQuickActions.onNext(true)
                completion(.success(sortedAccounts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchAccountSummary(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber,
                                    includeDevice: Bool = false,
                                    includeMDM: Bool = false,
                                    completion: @escaping (Result<AccountSummary, NetworkingError>) -> ()) {
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "summary", value: "true"))
        
        if includeDevice {
            queryItems.append(URLQueryItem(name: "includeDevice", value: "true"))
        }
        
        if includeMDM {
            queryItems.append(URLQueryItem(name: "includeMDM", value: "true"))
        }
    
        NetworkingLayer.request(router: .accountDetails(accountNumber: accountNumber, queryItems: queryItems), completion: completion)
    }
    
    static func fetchAccountDetails(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber,
                                    payments: Bool = true,
                                    programs: Bool = true,
                                    budgetBilling: Bool = true,
                                    alertPreferenceEligibilities: Bool = false,
                                    isGetRCDCapable: Bool = false,
                                    completion: @escaping (Result<AccountDetail, NetworkingError>) -> ()) {
        
        var queryItems = [URLQueryItem]()
        if !payments {
            queryItems.append(URLQueryItem(name: "payments", value: "false"))
        }
        if !programs {
            queryItems.append(URLQueryItem(name: "programs", value: "false"))
        }
        if !budgetBilling {
            queryItems.append(URLQueryItem(name: "budgetBilling", value: "false"))
        }
        
        if alertPreferenceEligibilities {
            queryItems.append(URLQueryItem(name: "alertPreferenceEligibilities", value: "true"))
        }
        
        if isGetRCDCapable {
            queryItems.append(URLQueryItem(name: "isGetRCDCapable", value: "true"))
        }
    
        NetworkingLayer.request(router: .accountDetails(accountNumber: accountNumber, queryItems: queryItems), completion: completion)
    }
    
    #if os(iOS)
    static func updatePECOReleaseOfInfoPreference(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber, selectedPreference: String, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .updateReleaseOfInfo(accountNumber: accountNumber, encodable: ReleaseOfInfoRequest(value: selectedPreference)), completion: completion)
    }

    static func setDefaultAccount(accountNumber: String, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .setDefaultAccount(accountNumber: accountNumber), completion: completion)
    }
    
    static func setAccountNickname(nickname: String, accountNumber: String, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .setAccountNickname(request: AccountNicknameRequest(accountNumber: accountNumber, accountNickname: nickname)), completion: completion)
    }
    #endif
    
    static func fetchSSOData(accountNumber: String, premiseNumber: String, completion: @escaping (Result<SSODataResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .ssoData(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func fetchFirstFuelSSOData(accountNumber: String, premiseNumber: String, completion: @escaping (Result<SSODataResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .ffssoData(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func fetchiTronSSOData(accountNumber: String, premiseNumber: String, completion: @escaping (Result<SSODataResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .iTronssoData(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func fetchScheduledPayments(accountNumber: String, completion: @escaping (Result<[PaymentItem], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .payments(accountNumber: accountNumber)) { (result: Result<Payments, NetworkingError>) in
            switch result {
            case .success(let payments):
                completion(.success(payments.billingInfo?.payments ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func fetchSERResults(accountNumber: String, completion: @escaping (Result<[SERResult], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .energyRewardsLoad(accountNumber: accountNumber)) { (result: Result<SERContainer, NetworkingError>) in
            switch result {
            case .success(let serContainer):
                completion(.success(serContainer.serInfo.eventResults))
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
    }
    
    static func fetchDDE(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber,
                         completion: @escaping (Result<DueDateElibility, NetworkingError>) ->()) {
        NetworkingLayer.request(router: .fetchDueDate(accountNumber: accountNumber), completion: completion)
    }
    
    static func fetchDPA(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber,
                         customerNumber: String,
                         premiseNumber: String,
                         paymentAmount: String,
                         completion: @escaping (Result<PaymentArrangement, NetworkingError>) ->()) {
        NetworkingLayer.request(router: .fetchDPA(accountNumber: accountNumber, encodable: DPARequest(customerNumber: customerNumber,
                                                                                                      premiseNumber: premiseNumber, paymentAmount: paymentAmount,
                                                                                                      months: "0")), completion: completion)
    }
}
