//
//  OutageServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct OutageServiceNew {
    static func fetchOutageStatus(accountNumber: String, premiseNumber: String, completion: @escaping (Result<NewOutageStatus, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .outageStatus(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func reportOutage(request: OutageRequest, completion: @escaping (Result<NewReportedOutageResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .reportOutage(accountNumber: request.accountNumber, encodable: request), completion: completion)
    }
    
    static func pingMeter(accountNumber: String, premiseNumber: String, completion: @escaping (Result<NewMeterPingResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .meterPing(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
}
