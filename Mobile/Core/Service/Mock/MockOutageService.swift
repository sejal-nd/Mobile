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
        let outageStatus = getOutageStatus(account: account)
        completion(ServiceResult.Success(outageStatus))
    }
    
    private func getOutageStatus(account: Account) -> OutageStatus {
        
        var status: OutageStatus
        
        let reportedMessage = "As of 6:21 AM EST on 8/19/2017 we are working to identify the cause of this outage. We currently estimate your service will be restored by 10:30 AM EST on 8/19/2025."
        
        switch account.accountNumber {
        case "1234567890":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": reportedMessage,
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
                "outageReported": reportedMessage,
                "status": "ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": false,
                "ETR": "2017-04-10T03:45:00-04:00"
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
                "ETR": "2017-04-10T03:45:00-04:00"
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "5591032201":
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": true,
                "contactHomeNumber": "5555555555",
                "outageReported": reportedMessage,
                "status": "NOT ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": false,
                "ETR": "2017-04-10T03:45:00-04:00"
            ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        case "5591032201":
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
        default:
            let dict: [AnyHashable: Any] = [
                "flagGasOnly": false,
                "contactHomeNumber": "5555555555",
                "outageReported": reportedMessage,
                "status": "NOT ACTIVE",
                "smartMeterStatus": false,
                "flagFinaled": false,
                "flagNoPay": false,
                ]
            status = OutageStatus.from(NSDictionary(dictionary: dict))!
        }
        return status
    }
    
    
    func reportOutage(outageInfo: OutageInfo, completion: @escaping (ServiceResult<Void>) -> Void) {
        
        if(outageInfo.accountNumber != "5591032201" && outageInfo.accountNumber != "5591032202") {
            outageMap[outageInfo.accountNumber] = ReportedOutageResult.from(NSDictionary())
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                completion(ServiceResult.Success(()))
            }
        } else {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, serviceMessage: "Invalid Account")))
        }
    }
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult? {
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
        // not implemented
    }
}
