//
//  UnauthIdentityVerificationViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 02/11/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxCocoa

class UnauthIdentityVerificationViewModel {
    
    var phoneNumber = ""
    var ssn = ""
    var accounts: [AccountLookupResult] = []
    var accountDetail: UnAuthAccountDetails?
    
    lazy var isAccountResidential: Bool = {
        
        guard let currentAccount = self.accountDetail, let customerType = accountDetail?.customerInfo.customerType, customerType == "COMM" else { return true }
        return false
    }()
    
    let moveServiceWebURL: URL? = {
        switch Configuration.shared.opco {
        case .bge:
            return URL(string: "https://\(Configuration.shared.associatedDomain)/CustomerServices/service/start")
        default:
            return nil
        }
    }()

    func isValidSSN(_ ssn: String)-> Bool {
        
        return (ssn.count == 4)
    }
    
    func isValidPhoneNumber(_ phoneNumber: String)-> Bool {
        
        return (phoneNumber.count == 10)
    }
    
    func validation()-> Bool {
        
        return (ssn.count  == 4 && phoneNumber.count == 10)
    }
    
    func isValidSSN(ssn: String, inputString: String)-> Bool {
        
        let isValidTextCount = self.extractDigitsFrom(ssn).count <= 4
        let char = inputString.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        if isBackSpace == -92 {
            return true
        }
        return isValidTextCount
    }
    
    func isValidPhoneNumber(phoneNumber: String, inputString: String)-> Bool {
        
        let isValidTextCount = self.extractDigitsFrom(phoneNumber).count <= 10
        let char = inputString.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        if isBackSpace == -92 {
            return true
        }
        return isValidTextCount
    }
    
    private func phoneNumberHasTenDigits(text: String)-> Bool {
        
        let digitsOnlyString = self.extractDigitsFrom(text)
        return digitsOnlyString.count == 10
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
    func getUnauthMoveFlowData()-> UnauthMoveData {
        
        var unauthData = UnauthMoveData()
        unauthData.isUnauthMove = true
        unauthData.accountLookup = accounts
        unauthData.accountDetails = accountDetail
        unauthData.selectedAccountNumber = accounts.count == 1 ? (accounts.first?.accountNumber ?? "") : ""
        unauthData.accountDetails?.accountNumber = accounts.first?.accountNumber
        unauthData.phoneNumber = phoneNumber
        unauthData.ssn = ssn
        return unauthData
    }
    
    func loadAccounts(onSuccess: @escaping () -> Void, onError: @escaping (NetworkingError) -> Void) {
        
        let accountLookupRequest = AccountLookupRequest(phone: extractDigitsFrom(phoneNumber), identifier: ssn)
        AnonymousService.lookupAccount(request: accountLookupRequest) { [weak self] result in
            switch result {
            case .success(let accountLookupResults):
                self?.accounts = accountLookupResults
                self?.loadAccountDetails(onSuccess: onSuccess, onError: onError)
            case .failure(let error):
                onError(error)
            }
        }
    }
    
    func loadAccountDetails(onSuccess: @escaping () -> Void, onError: @escaping (NetworkingError) -> Void) {
        
        let accountDetailRequest = AccountDetailsAnonRequest(phoneNumber: extractDigitsFrom(phoneNumber), accountNumber: self.accounts.first?.accountNumber ?? "", identifier: ssn)
        AnonymousService.accountDetailsAnon(request: accountDetailRequest) { [weak self] result in
            switch result {
            case .success(let accountDteails):
                self?.accountDetail = accountDteails
                onSuccess()
            case .failure(let error):
                onError(error)
            }
        }
    }
}
