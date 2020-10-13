//
//  MockOutageService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Foundation

class MockOutageService: OutageService {
    
    func fetchOutageStatus(account: Account) -> Observable<OutageStatus> {
        let key = MockUser.current.currentAccount.dataKey(forFile: .outageStatus)
        
        if key == .finaled {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountFinaled.rawValue))
        } else if key == .noPay {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountNoPay.rawValue))
        } else if key == .outageNonServiceAgreement {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnNonService.rawValue))
        }
        
        return MockJSONManager.shared.rx.mappableObject(fromFile: .outageStatus, key: key)
    }
    
    func pingMeter(account: Account, premiseNumber: String?) -> Observable<MeterPingInfo> {
        let key = MockUser.current.currentAccount.dataKey(forFile: .meterPingInfo)
        return MockJSONManager.shared.rx.mappableObject(fromFile: .meterPingInfo, key: key).delay(.seconds(2), scheduler: MainScheduler.instance)
    }
    
    func pingMeterAnon(accountNumber: String) -> Observable<MeterPingInfo> {
        let key = MockUser.current.currentAccount.dataKey(forFile: .meterPingInfo)
        return MockJSONManager.shared.rx.mappableObject(fromFile: .meterPingInfo, key: key).delay(.seconds(2), scheduler: MainScheduler.instance)
    }
    
    func reportOutage(outageInfo: OutageInfo) -> Observable<Void> {
        let key = MockUser.current.currentAccount.dataKey(forFile: .reportOutage)
        if key == .reportOutageError {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, serviceMessage: "Mock Error"))
        }
        
        return MockJSONManager.shared.rx.mappableObject(fromFile: .reportOutage, key: key)
            .do(onNext: { (result: ReportedOutageResult) in
                ReportedOutagesStore.shared[key.rawValue] = result
            })
            .mapTo(())
    }
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
        let key = MockUser.current.currentAccount.dataKey(forFile: .reportOutage)
        return ReportedOutagesStore.shared[key.rawValue]
    }
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?) -> Observable<[OutageStatus]> {
        return .error(ServiceError())
    }
    
    func reportOutageAnon(outageInfo: OutageInfo) -> Observable<ReportedOutageResult> {
        let key = MockUser.current.currentAccount.dataKey(forFile: .outageStatus)
        if key == .reportOutageError {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, serviceMessage: "Mock Error"))
        }

        let reportedOutageResult = ReportedOutageResult.from(NSDictionary())!
        ReportedOutagesStore.shared[outageInfo.accountNumber] = reportedOutageResult
        return .just(reportedOutageResult)
    }
}
