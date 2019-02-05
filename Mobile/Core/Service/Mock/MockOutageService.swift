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
        let key = MockUser.current.accounts[AccountsStore.shared.currentIndex].outageStatusKey
        
        if key == MockDataKey.finaled.rawValue {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountFinaled.rawValue))
        } else if key == MockDataKey.noPay.rawValue {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountNoPay.rawValue))
        } else if key == MockDataKey.outageNonServiceAgreement.rawValue {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnNonService.rawValue))
        }
        
        
//        var accountNum = account.accountNumber
//
//        if accountNum == "80000000000" {
//            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountFinaled.rawValue))
//        }
//        else if accountNum == "70000000000" {
//            return .error(ServiceError(serviceCode: ServiceErrorCode.fnAccountNoPay.rawValue))
//        }
//        else if accountNum == "60000000000" {
//            return .error(ServiceError(serviceCode: ServiceErrorCode.fnNonService.rawValue))
//        }
//        else {
//            let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
//            if loggedInUsername == "outageTestPowerOn" {
//                accountNum = "1234567890"
//            } else if loggedInUsername == "outageTestPowerOut" {
//                accountNum = "9836621902"
//            } else if loggedInUsername == "outageTestGasOnly" {
//                accountNum = "5591032201"
//            } else if loggedInUsername == "outageTestFinaled" {
//                accountNum = "75395146464"
//            } else if loggedInUsername == "outageTestNoPay" {
//                accountNum = "5591032203"
//            } else if loggedInUsername == "outageTestReport" {
//                accountNum = "7003238921"
//            } else if loggedInUsername == "outageTestError" {
//                return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
//            }
//
//            let outageStatus = getOutageStatus(accountNumber: accountNum)
//            return .just(outageStatus)
//        }
        
//        let dict: [AnyHashable: Any] = [
//            "flagGasOnly": false,
//            "contactHomeNumber": "5555555555",
//            "outageReported": "test power on message",
//            "status": "NOT ACTIVE",
//            "smartMeterStatus": false,
//            "flagFinaled": false,
//            "flagNoPay": false,
//        ]
//        return Observable.just(OutageStatus.from(NSDictionary(dictionary: dict))!)
        do {
            let outageStatus: OutageStatus = try MockJSONManager.shared.mappableObject(fromFile: .outage, key: key)
            return .just(outageStatus)
        } catch {
            return .error(error)
        }
        
    }
    
    private func getOutageStatus(accountNumber: String) -> OutageStatus {
        
        var status: OutageStatus
        
        let reportedMessage = "As of 6:21 AM EST on 8/19/2017 we are working to identify the cause of this outage. We currently estimate your service will be restored by 10:30 AM EST on 8/19/2025."
        
        let etr = Calendar.opCo.date(from: DateComponents(year: 2017, month: 4, day: 10, hour: 3, minute: 45))
        let opCoGMTOffset = abs(Int(TimeZone.opCo.secondsFromGMT(for: etr!)) / 3600)
        
        switch accountNumber {
        case "1234567890":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": "test power on message",
                "status": "NOT ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": false,
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "9836621902":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": "test power out message",
                "status": "ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": false,
                "ETR": "2017-04-10T03:45:00-0\(opCoGMTOffset):00"
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "7003238921":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": reportedMessage,
                "status": "NOT ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": false,
                "ETR": "2017-04-10T03:45:00-0\(opCoGMTOffset):00"
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "5591032201":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": true,
                "contactHomeNumber": "5555555555",
                "outageReported": "test gas only message",
                "status": "NOT ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": false,
                "ETR": "2017-04-10T03:45:00-0\(opCoGMTOffset):00"
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "5591032203":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "4444444444",
                "outageReported": reportedMessage,
                "status": "ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": true,
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "3216544560":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": reportedMessage,
                "status": "ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": true,
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "75395146464":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": reportedMessage,
                "status": "NOT ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": true,
                "flagNoPay": false,
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        default:
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": reportedMessage,
                "status": "NOT ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": true,
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        }
        return status
    }
    
    func pingMeter(account: Account) -> Observable<MeterPingInfo> {
        var meterPing: MeterPingInfo?
        switch account.accountNumber {
        case "1234567890":
            meterPing = MeterPingInfo(preCheckSuccess: true, pingResult: true, voltageResult: true, voltageReads: "proper")
        default:
            meterPing = nil
        }
        
        if let mp = meterPing {
            return .just(mp)
        } else {
            return .error(ServiceError())
        }
        
    }
    
    
    func reportOutage(outageInfo: OutageInfo) -> Observable<Void> {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        if loggedInUsername == "outageTestPowerOn" { // UI testing
            ReportedOutagesStore.shared["outageTestPowerOn"] = ReportedOutageResult.from(NSDictionary())
            return Observable.just(()).delay(2, scheduler: MainScheduler.instance)
        }
        if outageInfo.accountNumber != "5591032201" && outageInfo.accountNumber != "5591032202" {
            ReportedOutagesStore.shared[outageInfo.accountNumber] = ReportedOutageResult.from(NSDictionary())
            return Observable.just(()).delay(2, scheduler: MainScheduler.instance)
        } else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, serviceMessage: "Invalid Account"))
        }
    }
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        if loggedInUsername == "outageTestPowerOn" { // UI testing
            return ReportedOutagesStore.shared["outageTestPowerOn"]
        }
        return ReportedOutagesStore.shared[accountNumber]
    }
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?) -> Observable<[OutageStatus]> {
        return .error(ServiceError())
    }
    
    func reportOutageAnon(outageInfo: OutageInfo) -> Observable<ReportedOutageResult> {
        if outageInfo.accountNumber != "5591032201" && outageInfo.accountNumber != "5591032202" {
            let reportedOutageResult = ReportedOutageResult.from(NSDictionary())!
            ReportedOutagesStore.shared[outageInfo.accountNumber] = reportedOutageResult
            return Observable.just(reportedOutageResult).delay(2, scheduler: MainScheduler.instance)
        } else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, serviceMessage: "Invalid Account"))
        }
    }
}
