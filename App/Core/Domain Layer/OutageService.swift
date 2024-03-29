//
//  OutageService.swift
//  Mobile
//
//  Created by Cody Dillon on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum OutageService {
    static func fetchOutageStatus(accountNumber: String, premiseNumberString: String, completion: @escaping (Result<OutageStatus, NetworkingError>) -> ()) {
        var summaryQueryItem: URLQueryItem? = nil
        if StormModeStatus.shared.isOn && (Configuration.shared.opco != .bge && !Configuration.shared.opco.isPHI) {
            summaryQueryItem = URLQueryItem(name: "&summary", value: "true")
        }
        NetworkingLayer.request(router: .outageStatus(accountNumber: accountNumber, summaryQueryItem: summaryQueryItem)) { (result: Result<OutageStatusContainer, NetworkingError>) in
            switch result {
            case .success(let outageStatusContainer):
                let statuses = outageStatusContainer.statuses
                
                if statuses.count == 1 {
                    completion(.success(statuses[0]))
                } else {
                    guard let outageStatusForPremise = statuses.filter({ $0.premiseNumber == premiseNumberString }).first else {
                        completion(.failure(.decoding))
                        return
                    }
                    completion(.success(outageStatusForPremise))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }        
    }
    
    static func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
        return ReportedOutagesStore.shared[accountNumber]
    }
    
    static func reportOutage(outageRequest: OutageRequest, completion: @escaping (Result<ReportedOutageResult, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .reportOutage(accountNumber: outageRequest.accountNumber, request: outageRequest)) { (result: Result<ReportedOutageResult, NetworkingError>) in
            switch result {
            case .success(var reportOutageResult):
                reportOutageResult.reportedTime = outageRequest.reportedTime
                ReportedOutagesStore.shared[outageRequest.accountNumber] = reportOutageResult
                completion(.success(reportOutageResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func pingMeter(accountNumber: String, premiseNumber: String?, completion: @escaping (Result<MeterPingResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .meterPing(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    // MARK: Anon
    
    static func fetchAnonOutageStatus(phoneNumber: String?, accountNumber: String?, auid: String?, completion: @escaping (Result<AnonOutageStatusContainer, NetworkingError>) -> ()) {
        let anonOutageRequest = AnonOutageRequest(phoneNumber: phoneNumber, accountNumber: accountNumber, auid: auid)
        NetworkingLayer.request(router: .outageStatusAnon(request: anonOutageRequest), completion: completion)
    }
    
    static func reportOutageAnon(outageRequest: OutageRequest, completion: @escaping (Result<ReportedOutageResult, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .reportOutageAnon(request: outageRequest)) { (result: Result<ReportedOutageResult, NetworkingError>) in
            switch result {
            case .success(var reportOutageResult):
                reportOutageResult.reportedTime = outageRequest.reportedTime
                ReportedOutagesStore.shared[outageRequest.accountNumber] = reportOutageResult
                completion(.success(reportOutageResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func pingMeterAnon(accountNumber: String, completion: @escaping (Result<MeterPingResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .meterPingAnon(request: AnonMeterPingRequest(accountNumber: accountNumber)),
                                completion: completion)
    }
    
    static func fetchOutageTracker(accountNumber: String, deviceId: String, servicePointId: String, completion: @escaping (Result<OutageTracker, NetworkingError>) -> ()) {
        let request = OutageTrackerRequest(accountID: accountNumber, deviceID: deviceId, servicePointID: servicePointId)
        NetworkingLayer.request(router: .outageTracker(accountNumber: accountNumber, request: request)) { (result: Result<OutageTracker, NetworkingError>) in
            switch result {
                case .success(let outageTracker):
                    completion(.success(outageTracker))
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
}
