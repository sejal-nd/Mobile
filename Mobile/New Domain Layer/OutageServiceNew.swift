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
        
        NetworkingLayer.request(router: .outageStatus(accountNumber: accountNumber, premiseNumber: premiseNumber)) { (result: Result<NewOutageStatus, NetworkingError>) in
            switch result {
            case .success(let data):
                print("outageStatus SUCCESS: \(data)")
                completion(.success(data))

            case .failure(let error):
                print("outageStatus FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    static func reportOutage(request: OutageRequest, completion: @escaping (Result<NewReportedOutageResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .reportOutage(accountNumber: request.accountNumber, encodable: request)) { (result: Result<NewReportedOutageResult, NetworkingError>) in
            switch result {
            case .success(let data):
                print("reportOutage SUCCESS: \(data)")
                completion(.success(data))

            case .failure(let error):
                print("reportOutage FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    static func pingMeter(accountNumber: String, premiseNumber: String, completion: @escaping (Result<NewMeterPingResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .meterPing(accountNumber: accountNumber, premiseNumber: premiseNumber)) { (result: Result<NewMeterPingResult, NetworkingError>) in
            switch result {
            case .success(let data):
                print("meterPing SUCCESS: \(data)")
                completion(.success(data))

            case .failure(let error):
                print("meterPing FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
}
