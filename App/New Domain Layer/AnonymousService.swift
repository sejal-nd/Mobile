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
    
    static func recoverPassword(request: UsernameRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .recoverPassword(request: request), completion: completion)
    }
    
    static func changePassword(request: ChangePasswordRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .passwordChange(request: request), completion: completion)
    }
    
    // todo
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
