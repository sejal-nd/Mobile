//
//  OutageService.swift
//  Mobile
//
//  Created by Cody Dillon on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct OutageService {
    static func fetchOutageStatus(accountNumber: String, premiseNumber: String, completion: @escaping (Result<OutageStatus, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .outageStatus(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    // todo may want to relocate ect?
    static func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
        return ReportedOutagesStore.shared[accountNumber]
    }
    
    static func reportOutage(outageRequest: OutageRequest, completion: @escaping (Result<ReportedOutageResult, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .reportOutage(accountNumber: outageRequest.accountNumber, encodable: outageRequest)) { (result: Result<ReportedOutageResult, NetworkingError>) in
            switch result {
            case .success(let reportOutageResult):
                ReportedOutagesStore.shared[outageRequest.accountNumber] = reportOutageResult
                completion(.success(reportOutageResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func pingMeter(accountNumber: String, premiseNumber: String, completion: @escaping (Result<MeterPingResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .meterPing(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    // MARK: Anon
    
    static func fetchAnonOutageStatus(phoneNumber: String?, accountNumber: String?, completion: @escaping (Result<AnonOutageStatus, NetworkingError>) -> ()) {
        let anonOutageRequest = AnonOutageRequest(phoneNumber: phoneNumber, accountNumber: accountNumber)
        NetworkingLayer.request(router: .outageStatusAnon(request: anonOutageRequest), completion: completion)
    }
    
    static func reportOutageAnon(outageRequest: OutageRequest, completion: @escaping (Result<ReportedOutageResult, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .reportOutageAnon(encodable: outageRequest)) { (result: Result<ReportedOutageResult, NetworkingError>) in
            switch result {
            case .success(let reportOutageResult):
                ReportedOutagesStore.shared[outageRequest.accountNumber] = reportOutageResult
                completion(.success(reportOutageResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}




// anon outage reporting

//    func reportOutageAnon(outageInfo: OutageInfo) -> Observable<ReportedOutageResult> {
//        var params = [ReportOutageParams.AccountNumber.rawValue: outageInfo.accountNumber,
//                      ReportOutageParams.Phone.rawValue: outageInfo.phoneNumber,
//                      ReportOutageParams.OutageIssue.rawValue: outageInfo.issue.rawValue]
//        if let ext = outageInfo.phoneExtension {
//            params[ReportOutageParams.PhoneExt.rawValue] = ext
//        }
//        if let locationId = outageInfo.locationId {
//            params[ReportOutageParams.LocationId.rawValue] = locationId
//        }
//        if let comment = outageInfo.comment, !comment.isEmpty {
//            params[ReportOutageParams.Unusual.rawValue] = "Yes"
//            if let data = comment.data(using: .nonLossyASCII) { // Emojis would cause request to fail
//                params[ReportOutageParams.UnusualSpecify.rawValue] = String(data: data, encoding: .utf8)
//            } else {
//                params[ReportOutageParams.UnusualSpecify.rawValue] = comment
//            }
//        }
//        
//        return MCSApi.shared.post(pathPrefix: .anon, path: "outage", params: params)
//            .map { json in
//                guard let dict = json as? NSDictionary,
//                    let reportedOutage = ReportedOutageResult.from(dict) else {
//                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
//                }
//
//                ReportedOutagesStore.shared[outageInfo.accountNumber] = reportedOutage
//                return reportedOutage
//            }
//    }
