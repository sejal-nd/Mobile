//
//  StopService.swift
//  EUMobile
//
//  Created by RAMAITHANI on 09/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
enum StopService {
    
    static func fetchWorkdays(addressMrID: String = AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "",
                              isGasOff: Bool = false,
                              premiseOperationCenter: String = "",
                              isStart: Bool = false,
                              completion: @escaping (Result<WorkdaysResponse, NetworkingError>) -> ()) {
        let workdaysRequest = WorkdaysRequest(addressMrID: addressMrID, isGasOff: isGasOff, premiseOperationCenter: premiseOperationCenter, isStart: isStart)
        NetworkingLayer.request(router: .workDays(request: workdaysRequest), completion: completion)
    }
    
    static func stopServiceVerification(completion: @escaping (Result<StopServiceVerificationResponse, NetworkingError>) -> ()) {
        
        let stopServiceVerificationRequest = StopServiceVerificationRequest()
        NetworkingLayer.request(router: .stopServiceVerification(request: stopServiceVerificationRequest), completion: completion)
    }
    
    
    static func stopService(stopFlowData: StopServiceFlowData, completion: @escaping (Result<StopServiceResponse, NetworkingError>) -> ()) {

        let stopISUMServiceRequest = StopISUMServiceRequest(stopFlowData: stopFlowData)
        NetworkingLayer.request(router: .stopISUMService(request: stopISUMServiceRequest), completion: completion)
    }

}
