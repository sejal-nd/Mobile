//
//  AdminService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum AnonymousService {
    static func checkMinVersion(completion: @escaping (Result<String, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .minVersion) { (result: Result<MinimumVersion, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data.min))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func maintenanceMode(shouldPostNotification: Bool = false, completion: @escaping (Result<MaintenanceMode, Error>) -> ()) {
        NetworkingLayer.request(router: .maintenanceMode) { (result: Result<MaintenanceMode, NetworkingError>) in
            switch result {
            case .success(let maintenanceMode):
                if maintenanceMode.all && shouldPostNotification {
                    NotificationCenter.default.post(name: .didMaintenanceModeTurnOn, object: maintenanceMode)
                }
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
    
    static func changePasswordAnon(request: ChangePasswordRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .passwordChangeAnon(request: request), completion: completion)
    }
    
    static func lookupAccount(request: AccountLookupRequest, completion: @escaping (Result<[AccountLookupResult], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .accountLookup(request: request), completion: completion)
    }
    
    static func accountDetailsAnon(request: AccountDetailsAnonRequest, completion: @escaping (Result<UnAuthAccountDetails, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .accountDetailsAnon(request: request), completion: completion)
    }
    
    static func stopServiceVerification(unauthMoveData: UnauthMoveData? = nil, completion: @escaping (Result<StopServiceVerificationResponse, NetworkingError>) -> ()) {
        
        let stopServiceVerificationRequest = StopServiceVerificationRequest(accountDetails: unauthMoveData?.accountDetails)
        NetworkingLayer.request(router: .stopServiceVerificationAnon(request: stopServiceVerificationRequest), completion: completion)
    }
    
    static func fetchWorkdays(accountDetails: UnAuthAccountDetails,
                              completion: @escaping (Result<WorkdaysResponse, NetworkingError>) -> ()) {
        
        let addressMrID = accountDetails.premiseNumber
        let isGasOff = false
        let premiseOperationCenter = ""
        let isStart = false
        let workdaysRequest = WorkdaysRequest(addressMrID: addressMrID, isGasOff: isGasOff, premiseOperationCenter: premiseOperationCenter, isStart: isStart)
        NetworkingLayer.request(router: .workDaysAnon(request: workdaysRequest), completion: completion)
    }
}
