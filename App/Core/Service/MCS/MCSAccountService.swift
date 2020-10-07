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
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts").map { accounts in
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
            AccountsStore.shared.currentIndex = 0
            
            return sortedAccounts
        }
    }
    
    #if os(iOS)
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        return fetchAccountDetail(account: account, payments: false, programs: false, budgetBilling: false, alertPreferenceEligibilities: false)
    }
    
    #elseif os(watchOS)
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        return fetchAccountDetail(account: account, payments: true, programs: false, budgetBilling: false, alertPreferenceEligibilities: false)
    }
    #endif
    
    func fetchAccountDetail(account: Account, alertPreferenceEligibilities: Bool) -> Observable<AccountDetail> {
        return fetchAccountDetail(account: account, payments: false, programs: false, budgetBilling: false, alertPreferenceEligibilities: alertPreferenceEligibilities)
    }
    
    private func fetchAccountDetail(account: Account, payments: Bool, programs: Bool, budgetBilling: Bool, alertPreferenceEligibilities: Bool = false) -> Observable<AccountDetail> {
        var path = "accounts/\(account.accountNumber)"
        
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
        
        let queryString = queryItems
            .map { $0.0 + "=" + $0.1 }
            .reduce("?") { $0 + $1 + "&" }
            .dropLast() // drop the last "&"
        
        path.append(String(queryString))
        
        return MCSApi.shared.get(pathPrefix: .auth, path: path).map { json in
            guard let dict = json as? NSDictionary, let accountDetail = AccountDetail.from(dict) else {
                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
            }
            
            // Firebase Analytic User Properties
            #if os(iOS)
            // Customer Type
            let customerType: String
            if accountDetail.isResidential {
                customerType = "residential"
            } else {
                customerType = "commercial"
            }
            FirebaseUtility.setUserProperty(.customerType, value: customerType)

            // Service Type
            if let serviceType = accountDetail.serviceType {
                let serviceTypeString: String
                
                if serviceType == "GAS" {
                    serviceTypeString = "gas"
                } else if serviceType == "ELECTRIC" {
                    serviceTypeString = "electric"
                } else {
                    serviceTypeString = "both"
                }
                
                FirebaseUtility.setUserProperty(.serviceType, value: serviceTypeString)
            }
            
            // Control Group
            if Environment.shared.opco == .bge {
                FirebaseUtility.setUserProperty(.isControlGroup, value: accountDetail.isBGEControlGroup.description)
            }
            #endif
            
            return accountDetail
        }
    }
    
    #if os(iOS)
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int) -> Observable<Void> {
        let valueString = "0\(selectedIndex + 1)"
        let params = ["release_info_value": valueString]
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(account.accountNumber)/preferences/release", params: params)
            .mapTo(())
    }
    
    func setDefaultAccount(account: Account) -> Observable<Void> {
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(account.accountNumber)/default", params: nil)
            .mapTo(())
    }
    
    func setAccountNickname(nickname: String, accountNumber: String) -> Observable<Void> {
        let params = ["accountNickname": nickname, "accountNumber": accountNumber]
        return MCSApi.shared.post(pathPrefix: .auth, path: "profile/update/account/nickname", params: params)
            .mapTo(())
    }
    #endif
    
    func fetchSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/ssodata")
            .map { json in
                guard let dict = json as? NSDictionary, let ssoData = SSOData.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return ssoData
        }
    }
    
    func fetchFirstFuelSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/ffssodata")
            .map { json in
                guard let dict = json as? NSDictionary, let ssoData = SSOData.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return ssoData
        }
    }
    
    func fetchScheduledPayments(accountNumber: String) -> Observable<[PaymentItem]> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments")
            .map { json in
                guard let dict = json as? NSDictionary,
                    let billingInfo = dict["BillingInfo"] as? NSDictionary,
                    let payments = billingInfo["payments"] as? [NSDictionary] else {
                        return []
                }
                let paymentItems = payments.compactMap(PaymentItem.from).filter { $0.status == .scheduled }
                return paymentItems
        }
        .catchError { error in
            let serviceError = error as? ServiceError ?? ServiceError(cause: error)
            if Environment.shared.opco == .bge && serviceError.serviceCode == ServiceErrorCode.fnNotFound.rawValue {
                return Observable.just([])
            } else if (Environment.shared.opco == .comEd || Environment.shared.opco == .peco) && serviceError.serviceCode ==  ServiceErrorCode.failed.rawValue {
                return Observable.just([])
            } else {
                throw serviceError
            }
        }
    }
    
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        switch Environment.shared.opco {
        case .comEd, .bge:
            return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/programs")
                .map { json in
                    guard let dict = json as? NSDictionary,
                        let serInfo = dict["SERInfo"] as? NSDictionary,
                        let array = serInfo["eventResults"] as? NSArray,
                        let serResults = SERResult.from(array) else {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    // Ensure the array is always sorted most recent to oldest
                    let sortedResults = serResults.sorted { (a, b) -> Bool in
                        a.eventStart > b.eventStart
                    }
                    return sortedResults
            }
            .catchError { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                if Environment.shared.opco == .bge && serviceError.serviceCode == ServiceErrorCode.functionalError.rawValue {
                    return Observable.just([])
                } else {
                    throw serviceError
                }
            }
        case .ace, .delmarva, .peco, .pepco:
            return .just([])
        }
    }
}
