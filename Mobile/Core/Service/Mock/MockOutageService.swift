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
        let key = MockUser.current.accounts[AccountsStore.shared.currentIndex].dataKey(forFile: .outageStatus)
        
        if key == .finaled {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountFinaled.rawValue))
        } else if key == .noPay {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountNoPay.rawValue))
        } else if key == .outageNonServiceAgreement {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnNonService.rawValue))
        }
        
        return MockJSONManager.shared.rx.mappableObject(fromFile: .outageStatus, key: key)
    }
    
    func pingMeter(account: Account) -> Observable<MeterPingInfo> {
        let key = MockUser.current.accounts[AccountsStore.shared.currentIndex].dataKey(forFile: .meterPingInfo)
        return MockJSONManager.shared.rx.mappableObject(fromFile: .meterPingInfo, key: key)
    }
    
    func reportOutage(outageInfo: OutageInfo) -> Observable<Void> {
        let key = MockUser.current.accounts[AccountsStore.shared.currentIndex].dataKey(forFile: .outageStatus)
        if key == .reportOutageError {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, serviceMessage: "Mock Error"))
        }
        
        ReportedOutagesStore.shared[outageInfo.accountNumber] = ReportedOutageResult.from(NSDictionary())
        return .just(())
    }
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
        return ReportedOutagesStore.shared[accountNumber]
    }
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?) -> Observable<[OutageStatus]> {
        return .error(ServiceError())
    }
    
    func reportOutageAnon(outageInfo: OutageInfo) -> Observable<ReportedOutageResult> {
        let key = MockUser.current.accounts[AccountsStore.shared.currentIndex].dataKey(forFile: .outageStatus)
        if key == .reportOutageError {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, serviceMessage: "Mock Error"))
        }

        let reportedOutageResult = ReportedOutageResult.from(NSDictionary())!
        ReportedOutagesStore.shared[outageInfo.accountNumber] = reportedOutageResult
        return .just(reportedOutageResult)
    }
}
