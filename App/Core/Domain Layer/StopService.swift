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
}
