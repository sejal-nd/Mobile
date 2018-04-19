//
//  MockOutageService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockOutageService: OutageService {
    
    private var outageMap = [String: ReportedOutageResult]()
    
    func fetchOutageStatus(account: Account, completion: @escaping (ServiceResult<OutageStatus>) -> Void) {
        var accountNum = account.accountNumber
        
        if accountNum == "80000000000" {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAccountFinaled.rawValue)))
        }
        else if accountNum == "70000000000" {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAccountNoPay.rawValue)))
        }
        else if accountNum == "60000000000" {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnNonService.rawValue)))
        }
        else {
            let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.LoggedInUsername)
            if loggedInUsername == "outageTestPowerOn" {
                accountNum = "1234567890"
            } else if loggedInUsername == "outageTestPowerOut" {
                accountNum = "9836621902"
            } else if loggedInUsername == "outageTestGasOnly" {
                accountNum = "5591032201"
            } else if loggedInUsername == "outageTestFinaled" {
                accountNum = "75395146464"
            } else if loggedInUsername == "outageTestReport" {
                accountNum = "7003238921"
            }
            let outageStatus = getOutageStatus(accountNumber: accountNum)
            completion(ServiceResult.Success(outageStatus))
        }
        
    }
    
    private func getOutageStatus(accountNumber: String) -> OutageStatus {
        
        var status: OutageStatus
        
        let reportedMessage = "As of 6:21 AM EST on 8/19/2017 we are working to identify the cause of this outage. We currently estimate your service will be restored by 10:30 AM EST on 8/19/2025."
        
        let opCoGMTOffset = abs(Int(TimeZone.opCo.secondsFromGMT() / 3600))
        
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
                "meterInfo": [
                    "preCheckSuccess": true,
                    "pingResult": true,
                    "voltageResult": true,
                    "voltageReads": "yeah!"
                ]
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
                "meterInfo": [
                    "preCheckSuccess": true,
                    "pingResult": true,
                    "voltageResult": true,
                    "voltageReads": "yeah!"
                ]
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
                "meterInfo": [
                    "preCheckSuccess": true,
                    "pingResult": true,
                    "voltageResult": true,
                    "voltageReads": "yeah!"
                ]
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
    
    
    func reportOutage(outageInfo: OutageInfo, completion: @escaping (ServiceResult<Void>) -> Void) {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.LoggedInUsername)
        if loggedInUsername == "outageTestPowerOn" { // UI testing
            outageMap["outageTestPowerOn"] = ReportedOutageResult.from(NSDictionary())
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                completion(ServiceResult.Success(()))
            }
        }
        if outageInfo.accountNumber != "5591032201" && outageInfo.accountNumber != "5591032202" {
            outageMap[outageInfo.accountNumber] = ReportedOutageResult.from(NSDictionary())
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                completion(ServiceResult.Success(()))
            }
        } else {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, serviceMessage: "Invalid Account")))
        }
    }
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.LoggedInUsername)
        if loggedInUsername == "outageTestPowerOn" { // UI testing
            return self.outageMap["outageTestPowerOn"]
        }
        return self.outageMap[accountNumber]
    }
    
    func clearReportedOutageStatus(accountNumber: String?) {
        if let accountNumber = accountNumber {
            self.outageMap[accountNumber] = nil
        } else {
            self.outageMap.removeAll()
        }
    }
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?, completion: @escaping (ServiceResult<[OutageStatus]>) -> Void) {
        // not implemented
    }
    
    func reportOutageAnon(outageInfo: OutageInfo, completion: @escaping (ServiceResult<ReportedOutageResult>) -> Void) {
        if outageInfo.accountNumber != "5591032201" && outageInfo.accountNumber != "5591032202" {
            let reportedOutageResult = ReportedOutageResult.from(NSDictionary())!
            outageMap[outageInfo.accountNumber] = reportedOutageResult
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                completion(ServiceResult.Success(reportedOutageResult))
            }
        } else {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, serviceMessage: "Invalid Account")))
        }
    }
}
