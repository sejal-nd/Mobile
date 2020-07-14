//
//  AdminService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AnonymousService {
    static func checkMinVersion(completion: @escaping (Result<String, Error>) -> ()) {
        NetworkingLayer.request(router: .minVersion) { (result: Result<NewVersion, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data.min))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func maintenanceMode(shouldPostNotification: Bool = false, completion: @escaping (Result<MaintenanceMode, Error>) -> ()) {
        print("maint start")
        NetworkingLayer.request(router: .maintenanceMode) { (result: Result<MaintenanceMode, NetworkingError>) in
            switch result {
            case .success(let maintenanceMode):
                if maintenanceMode.all && shouldPostNotification {
                    NotificationCenter.default.post(name: .didMaintenanceModeTurnOn, object: maintenanceMode)
                }
                print("maint succeed")
                completion(.success(maintenanceMode))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    static func recoverMaskedUsername(request: RecoverMaskedUsernameRequest, completion: @escaping (Result<ForgotMaskedUsernames, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .recoverMaskedUsername(request: request), completion: completion)
    }
    
    static func recoverUsername(request: RecoverUsernameRequest, completion: @escaping (Result<String, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .recoverUsername(request: request), completion: completion)
    }
    
    static func lookupAccount(request: AccountLookupRequest, completion: @escaping (Result<AccountLookupResults, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .accountLookup(request: request), completion: completion)
    }
}


// Account Lookup

//static func lookupAccount(request: AccountLookupRequest, completion: @escaping (Result<NewAccountLookupResult, NetworkingError>) -> ()) {
//
//    NetworkingLayer.request(router: .accountLookup(encodable: request)) { (result: Result<NewAccountLookupResult, NetworkingError>) in
//        switch result {
//        case .success(let data):
//            print("lookupAccount SUCCESS: \(data)")
//            completion(.success(data))
//
//        case .failure(let error):
//            print("lookupAccount FAIL: \(error)")
//            completion(.failure(error))
//        }
//    }
//}


// RECOVER USERNAME

// CODY SERVICE

//static func recoverUsername(request: RecoverUsernameRequest, completion: @escaping (Result<String, NetworkingError>) -> ()) {
//    
//    NetworkingLayer.request(router: .recoverUsername(encodable: request)) { (result: Result<String, NetworkingError>) in
//        switch result {
//        case .success(let data):
//            print("recoverUsername SUCCESS: \(data)")
//            completion(.success(data))
//
//        case .failure(let error):
//            print("recoverUsername FAIL: \(error)")
//            completion(.failure(error))
//        }
//    }
//}
//
//static func recoverMaskedUsername(request: RecoverMaskedUsernameRequest, completion: @escaping (Result<NewForgotMaskedUsername, NetworkingError>) -> ()) {
//    
//    NetworkingLayer.request(router: .recoverUsername(encodable: request)) { (result: Result<NewForgotMaskedUsername, NetworkingError>) in
//        switch result {
//        case .success(let data):
//            print("recoverMaskedUsername SUCCESS: \(data)")
//            completion(.success(data))
//
//        case .failure(let error):
//            print("recoverMaskedUsername FAIL: \(error)")
//            completion(.failure(error))
//        }
//    }
//}


// SERVICE

//func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]> {
//    var params = ["phone": phone]
//    if let id = identifier {
//        params["identifier"] = id
//    }
//    
//    if let accNum = accountNumber {
//        params["account_number"] = accNum
//    }
//    
//    return MCSApi.shared.post(pathPrefix: .anon, path: "recover/username", params: params)
//        .map { json in
//            guard let maskedEntries = json as? [NSDictionary] else {
//                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
//            }
//            
//            return maskedEntries.compactMap(ForgotUsernameMasked.from)
//        }
//}
//
//func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String) -> Observable<String> {
//    var params = ["phone": phone,
//                  "question_id": questionId,
//                  "security_answer": questionResponse,
//                  "cipherString": cipher] as [String : Any]
//    
//    if let id = identifier {
//        params["identifier"] = id
//    }
//    
//    if let accNum = accountNumber {
//        params["account_number"] = accNum
//    }
//    
//    return MCSApi.shared.post(pathPrefix: .anon, path: "recover/username", params: params)
//        .map { data in
//            guard let unmasked = data as? String else {
//                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue,
//                                   serviceMessage: "Unable to parse response")
//            }
//            
//            return unmasked
//        }
//}

// VIEW MODEL

//func validateAccount(onSuccess: @escaping () -> Void, onNeedAccountNumber: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
//    let acctNum: String? = accountNumber.value.isEmpty ? nil : accountNumber.value
//    let identifier: String? = identifierNumber.value.isEmpty ? nil : identifierNumber.value
//    authService.recoverMaskedUsername(phone: extractDigitsFrom(phoneNumber.value), identifier: identifier, accountNumber: acctNum)
//        .observeOn(MainScheduler.instance)
//        .subscribe(onNext: { usernames in
//            self.maskedUsernames = usernames
//            onSuccess()
//            GoogleAnalytics.log(event: .forgotUsernameAccountValidate)
//        }, onError: { error in
//            let serviceError = error as! ServiceError
//            if serviceError.serviceCode == ServiceErrorCode.fnAccountNotFound.rawValue ||
//                serviceError.serviceCode == ServiceErrorCode.fnProfNotFound.rawValue {
//                onError(NSLocalizedString("Invalid Information", comment: ""), error.localizedDescription)
//            } else if serviceError.serviceCode == ServiceErrorCode.fnMultiAccountFound.rawValue {
//                onNeedAccountNumber()
//            } else {
//                onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
//            }
//        }).disposed(by: disposeBag)
//}
//
//func submitSecurityQuestionAnswer(onSuccess: @escaping (String) -> Void, onAnswerNoMatch: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
//    let maskedUsername = maskedUsernames[selectedUsernameIndex]
//    let acctNum: String? = accountNumber.value.count > 0 ? accountNumber.value : nil
//    let identifier: String? = identifierNumber.value.count > 0 ? identifierNumber.value : nil
//    GoogleAnalytics.log(event: .forgotUsernameSecuritySubmit)
//    
//    authService.recoverUsername(phone: extractDigitsFrom(phoneNumber.value),
//                                identifier: identifier,
//                                accountNumber: acctNum,
//                                questionId: maskedUsername.questionId,
//                                questionResponse: securityQuestionAnswer.value,
//                                cipher: maskedUsername.cipher)
//        .observeOn(MainScheduler.instance)
//        .subscribe(onNext: { username in
//            onSuccess(username)
//        }, onError: { error in
//            let serviceError = error as! ServiceError
//            if serviceError.serviceCode == ServiceErrorCode.fnProfBadSecurity.rawValue {
//                onAnswerNoMatch(serviceError.localizedDescription)
//            } else {
//                onError(error.localizedDescription)
//            }
//        }).disposed(by: disposeBag)
//}
