//
//  MockOutageService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockOutageService : OutageService {
    
    var outageMap = [String:OutageInfo]()
    
    func fetchOutageStatus(account: Account, completion: @escaping (ServiceResult<OutageStatus>) -> Void) {
        let outageStatus = getOutageStatus(account: account)
        completion(ServiceResult.Success(outageStatus))
    }
    
    private func getOutageStatus(account: Account) -> OutageStatus {
        
        let outageInfo = outageMap[account.accountNumber]
        var status: OutageStatus
        
        let reportedTitle = "Your outage report has been received. Your confirmation number is: 84759864125"
        let reportedMessage = "As of 6:21 AM EST on 8/19/2017 we are working to identify the cause of this outage. We currently estimate your service will be restored by 10:30 AM EST on 8/19/2025."
        
        switch account.accountNumber {
        case "1234567890":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumber:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:outageInfo == nil ? "Our records show your power is on." : reportedTitle,
                                  outageMessage:outageInfo == nil ? "If you reported an outage within the past fifteen minutes it may not yet be reflected here." : reportedMessage,
                                  accountFinaled:false,
                                  accountPaid:true,
                                  outageInfo:outageInfo)
            break
        case "9836621902":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumber:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:true,
                                  outageMessageTitle:outageInfo == nil ? "We have detected an outage in your area." : reportedTitle,
                                  outageMessage:outageInfo == nil ? "As of 6:21 AM EST on 8/19/2017 we indicate that 10 customers(s) are affected by a power outage in your area. The cause of your outage is under investigation. We apologize for any inconvenience it may have caused you. The preliminary restore time is 10:30 AM EST on 8/19/2017." : reportedMessage,
                                  accountFinaled:false,
                                  accountPaid:true,
                                  restorationTime:Date().addingTimeInterval(3600))
            break
        case "7003238921":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumber:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:outageInfo == nil ? "Our records show your power is on." : reportedTitle,
                                  outageMessage:outageInfo == nil ? "If you reported an outage within the past fifteen minutes it may not yet be reflected here." : reportedMessage,
                                  accountFinaled:false,
                                  accountPaid:true,
                                  outageInfo:outageInfo)
            break
        case "5591032201":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:true,
                                  homeContactNumber:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:"",
                                  outageMessage:"",
                                  accountFinaled:false,
                                  accountPaid:true)
            break
        case "5591032201":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumber:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:"",
                                  outageMessage:"",
                                  accountFinaled:false,
                                  accountPaid:false)
            break
            default:
                status = OutageStatus(accountInfo: account,
                                      gasOnly:false,
                                      homeContactNumber:"5555555555",
                                      isPasswordProtected:false,
                                      isUserAuthenticated:true,
                                      activeOutage:false,
                                      outageMessageTitle:"",
                                      outageMessage:"",
                                      accountFinaled:false,
                                      accountPaid:false)
            break
        }
        return status
    }
    
    
    func reportOutage(outageInfo: OutageInfo, completion: @escaping (ServiceResult<Void>) -> Void) {
        
        if(outageInfo.account.accountNumber != "5591032201" &&
            outageInfo.account.accountNumber != "5591032202") {
            outageMap[outageInfo.account.accountNumber] = outageInfo
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                completion(ServiceResult.Success())
            }
        } else {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.TcAcctInvalid.rawValue, serviceMessage: "Invalid Account")))
        }
    }
}
