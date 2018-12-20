//
//  MCSAccountService.swift
//  Mobile
//
//  Created by Marc Shilling on 3/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

struct MCSAccountService: AccountService {
    
    func fetchAccounts() -> Observable<[Account]> {
        return MCSApi.shared.get(path: "accounts")
            .map { accounts in
                let accountArray = (accounts as! [[String: Any]])
                    .compactMap { Account.from($0 as NSDictionary) }
                
                guard !accountArray.isEmpty else {
                    throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue,
                                       serviceMessage: NSLocalizedString("No accounts found", comment: ""))
                }
                
                // Error if the first account is password protected.
                guard !accountArray[0].isPasswordProtected else {
                    throw ServiceError(serviceCode: ServiceErrorCode.fnAccountProtected.rawValue)
                }
                
                let sortedAccounts = accountArray
                    .filter { !$0.isPasswordProtected } // Filter out password protected accounts
                    .sorted { ($0.isDefault && !$1.isDefault) || (!$0.isFinaled && $1.isFinaled) }
                
                AccountsStore.shared.accounts = sortedAccounts
                AccountsStore.shared.currentAccount = sortedAccounts[0]
                
                return sortedAccounts
        }
    }
    
    #if os(iOS)
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        return fetchAccountDetail(account: account, payments: false, programs: false)
    }
    #elseif os(watchOS)
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        return fetchAccountDetail(account: account, payments: true, programs: false)
    }
    #endif
    
    private func fetchAccountDetail(account: Account, payments: Bool, programs: Bool) -> Observable<AccountDetail> {
        var path = "accounts/\(account.accountNumber)"
        
        var queryItems = [(String, String)]()
        if !payments {
            queryItems.append(("payments", "false"))
        }
        
        if !programs {
            queryItems.append(("programs", "false"))
        }
        
        let queryString = queryItems
            .map { $0.0 + "=" + $0.1 }
            .reduce("?") { $0 + $1 + "&" }
            .dropLast() // drop the last "&"
        
        path.append(String(queryString))
        
        return MCSApi.shared.get(path: path)
            .map { json in
                guard let dict = json as? NSDictionary, let accountDetail = AccountDetail.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return accountDetail
        }
    }
    
    #if os(iOS)
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int) -> Observable<Void> {
        let valueString = "0\(selectedIndex + 1)"
        let params = ["release_info_value": valueString]
        return MCSApi.shared.put(path: "accounts/\(account.accountNumber)/preferences/release", params: params)
            .mapTo(())
    }
    
    func setDefaultAccount(account: Account) -> Observable<Void> {
        return MCSApi.shared.put(path: "accounts/\(account.accountNumber)/default", params: nil)
            .mapTo(())
    }
    #endif
    
    func fetchSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData> {
        return MCSApi.shared.get(path: "accounts/\(accountNumber)/premises/\(premiseNumber)/ssodata")
            .map { json in
                guard let dict = json as? NSDictionary, let ssoData = SSOData.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return ssoData
        }
    }
    
    func fetchRecentPayments(accountNumber: String) -> Observable<RecentPayments> {
        return MCSApi.shared.get(path: "accounts/\(accountNumber)/payments")
            .map { json in
                guard let dict = json as? NSDictionary,
                    let payments = RecentPayments.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return payments
        }
    }
    
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        switch Environment.shared.opco {
        case .peco:
            return .just([])
        case .comEd, .bge:
            return MCSApi.shared.get(path: "accounts/\(accountNumber)/programs")
                .map { json in
                    guard let dict = json as? NSDictionary,
                        let serInfo = dict["SERInfo"] as? NSDictionary,
                        let array = serInfo["eventResults"] as? NSArray,
                        let serResults = SERResult.from(array) else {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    return serResults
            }
        }
    }
}
