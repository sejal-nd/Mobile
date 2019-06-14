//
//  MCSOutageService.swift
//  Mobile
//
//  Created by Marc Shilling on 3/30/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

private enum ReportOutageParams: String {
    case AccountNumber = "account_number"
    case Phone = "phone"
    case PhoneExt = "ext"
    case OutageIssue = "outage_issue"
    case LocationId = "location_id"
    case Unusual = "unusual"
    case UnusualSpecify = "unusual_specify"
}

class MCSOutageService: OutageService {
    
    private var outageMap = [String: ReportedOutageResult]()
    
    func pingMeter(account: Account) -> Observable<MeterPingInfo> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(account.accountNumber)/outage/ping")
            .map { json in
                guard let dict = json as? NSDictionary,
                    let meterPingDict = dict["meterInfo"] as? NSDictionary,
                    let meterPingInfo = MeterPingInfo.from(meterPingDict) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return meterPingInfo
            }
    }
    
    func fetchOutageStatus(account: Account) -> Observable<OutageStatus> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(account.accountNumber)/outage?meterPing=false")
            .map { jsonArray in
                guard let outageStatusArray = jsonArray as? NSArray else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                if account.isMultipremise {
                    let outageStatusModels = outageStatusArray.map { $0 as! NSDictionary }
                    guard let premiseNumber = account.currentPremise?.premiseNumber,
                        let dict = outageStatusModels.filter({ $0["premiseNumber"] as! String == premiseNumber }).first,
                        let outageStatus = OutageStatus.from(dict as NSDictionary) else {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    return outageStatus
                } else {
                    guard let dict = outageStatusArray[0] as? NSDictionary,
                        let outageStatus = OutageStatus.from(dict) else {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    return outageStatus
                }
            }
    }
    
    #if os(iOS)
    func reportOutage(outageInfo: OutageInfo) -> Observable<Void> {
        var params = [ReportOutageParams.AccountNumber.rawValue: outageInfo.accountNumber,
                      ReportOutageParams.Phone.rawValue: outageInfo.phoneNumber,
                      ReportOutageParams.OutageIssue.rawValue: outageInfo.issue.rawValue]
        if let ext = outageInfo.phoneExtension {
            params[ReportOutageParams.PhoneExt.rawValue] = ext
        }
        if let locationId = outageInfo.locationId {
            params[ReportOutageParams.LocationId.rawValue] = locationId
        }
        if let comment = outageInfo.comment, !comment.isEmpty {
            params[ReportOutageParams.Unusual.rawValue] = "Yes"
            if let data = comment.data(using: .nonLossyASCII) { // Emojis would cause request to fail
                params[ReportOutageParams.UnusualSpecify.rawValue] = String(data: data, encoding: .utf8)
            } else {
                params[ReportOutageParams.UnusualSpecify.rawValue] = comment
            }
        }
        
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(outageInfo.accountNumber)/outage", params: params)
            .do(onNext: { json in
                guard let dict = json as? NSDictionary,
                    let reportedOutage = ReportedOutageResult.from(dict) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                ReportedOutagesStore.shared[outageInfo.accountNumber] = reportedOutage
            })
            .mapTo(())
    }
    #endif
    
    func reportOutageAnon(outageInfo: OutageInfo) -> Observable<ReportedOutageResult> {
        var params = [ReportOutageParams.AccountNumber.rawValue: outageInfo.accountNumber,
                      ReportOutageParams.Phone.rawValue: outageInfo.phoneNumber,
                      ReportOutageParams.OutageIssue.rawValue: outageInfo.issue.rawValue]
        if let ext = outageInfo.phoneExtension {
            params[ReportOutageParams.PhoneExt.rawValue] = ext
        }
        if let locationId = outageInfo.locationId {
            params[ReportOutageParams.LocationId.rawValue] = locationId
        }
        if let comment = outageInfo.comment, !comment.isEmpty {
            params[ReportOutageParams.Unusual.rawValue] = "Yes"
            if let data = comment.data(using: .nonLossyASCII) { // Emojis would cause request to fail
                params[ReportOutageParams.UnusualSpecify.rawValue] = String(data: data, encoding: .utf8)
            } else {
                params[ReportOutageParams.UnusualSpecify.rawValue] = comment
            }
        }
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "outage", params: params)
            .map { json in
                guard let dict = json as? NSDictionary,
                    let reportedOutage = ReportedOutageResult.from(dict) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                ReportedOutagesStore.shared[outageInfo.accountNumber] = reportedOutage
                return reportedOutage
            }
    }
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
        return ReportedOutagesStore.shared[accountNumber]
    }
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?) -> Observable<[OutageStatus]> {
        var params: [String: String] = [:]
        if let phone = phoneNumber {
            params["phone"] = phone
        }
        
        if let accountNum = accountNumber {
            params["account_number"] = accountNum
        }
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "outage/query", params: params)
            .map { json in
                guard let outageStatusArray = json as? [[String: Any]] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                var outageArray = [OutageStatus]()
                var multipremiseDict = [String: Int]()
                for status in outageStatusArray {
                    let outageStatusModel = OutageStatus.from(status as NSDictionary)!
                    outageArray.append(outageStatusModel)
                    if let accountNumber = outageStatusModel.accountNumber {
                        if let count = multipremiseDict[accountNumber] {
                            multipremiseDict[accountNumber] = count + 1
                        } else {
                            multipremiseDict[accountNumber] = 1
                        }
                    }
                }
                
                var finalOutageArray = [OutageStatus]()
                for outageStatus in outageArray {
                    if let accountNumber = outageStatus.accountNumber, let count = multipremiseDict[accountNumber], count > 1 {
                        var newOutageStatus = outageStatus
                        newOutageStatus.multipremiseAccount = true
                        finalOutageArray.append(newOutageStatus)
                    } else {
                        finalOutageArray.append(outageStatus)
                    }
                }
                
                return finalOutageArray
            }
    }
}
