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
        return MCSApi.shared.get(path: "auth_\(MCSApi.API_VERSION)/accounts")
            .map { accounts in
                let accountArray = (accounts as! [[String: Any]])
                    .compactMap { Account.from($0 as NSDictionary) }
                
                if accountArray.count == 0 {
                    throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue,
                                       serviceMessage: NSLocalizedString("No accounts found", comment: ""))
                }
                
                let sortedAccounts = accountArray.sorted {
                    ($0.isDefault && !$1.isDefault) || (!$0.isFinaled && $1.isFinaled)
                }
                
                AccountsStore.shared.accounts = sortedAccounts
                AccountsStore.shared.currentAccount = sortedAccounts[0]
                
                return sortedAccounts
        }
    }
    
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        return MCSApi.shared.get(path: "auth_\(MCSApi.API_VERSION)/accounts/\(account.accountNumber)")
            .map { json in
                guard let dict = json as? NSDictionary, let accountDetail = AccountDetail.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return accountDetail
        }
    }
    
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int) -> Observable<Void> {
        let valueString = "0\(selectedIndex + 1)"
        let params = ["release_info_value": valueString]
        return MCSApi.shared.put(path: "auth_\(MCSApi.API_VERSION)/accounts/\(account.accountNumber)/preferences/release", params: params)
            .mapTo(())
    }
    
    func setDefaultAccount(account: Account) -> Observable<Void> {
        return MCSApi.shared.put(path: "auth_\(MCSApi.API_VERSION)/accounts/\(account.accountNumber)/default", params: nil)
            .mapTo(())
    }
    
    func fetchSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData> {
        return MCSApi.shared.get(path: "auth_\(MCSApi.API_VERSION)/accounts/\(accountNumber)/premises/\(premiseNumber)/ssodata")
            .map { json in
                guard let dict = json as? NSDictionary, let ssoData = SSOData.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return ssoData
        }
    }
    
}
