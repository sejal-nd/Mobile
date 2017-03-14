//
//  MockOutageService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct MockOutageService : OutageService {
    
    func fetchOutageStatus(account: Account, completion: @escaping (ServiceResult<OutageStatus>) -> Void) {
        let outageStatus = getOutageStatus(account: account)
        completion(ServiceResult.Success(outageStatus))
    }
    
    private func getOutageStatus(account: Account) -> OutageStatus {
        var status: OutageStatus
        switch account.accountNumber {
        case "1234567890":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumbner:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:"Our records show your power is on.",
                                  outageMessage:"Of you reported an outage within the past fifteen minutes it may not yet be reflected here.",
                                  restorationTime:Date(),
                                  outageReported:false,
                                  accountFinaled:false,
                                  accountPaid:true)
            break
        case "9836621902":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumbner:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:true,
                                  outageMessageTitle:"We have detected an outage in your area.",
                                  outageMessage:"As of 6:21 AM EST on 8/19/2017 we indicate that 10 customers(s) are affected by a power outage in your area. The cause of your outage is under investigation. We apologie for any inconvenience it may have caused you. The preliminary restore time is 10:30 AM EST on 8/19/2017.",
                                  restorationTime:Date().addingTimeInterval(3600),
                                  outageReported:false,
                                  accountFinaled:false,
                                  accountPaid:true)
            break
        case "7003238921":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumbner:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:"Your outage report has been received. Your confirmation number is: 84759864125",
                                  outageMessage:"As of 6:21 AM EST on 8/19/2017 we are working to identify the cause of this outage. We currently estimate your service will be restored by 10:30 AM EST on 8/19/2017.",
                                  restorationTime:Date().addingTimeInterval(3600),
                                  outageReported:true,
                                  accountFinaled:false,
                                  accountPaid:true)
            break
        case "5591032201":
            status = OutageStatus(accountInfo: account,
                                  gasOnly:true,
                                  homeContactNumbner:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:"",
                                  outageMessage:"",
                                  restorationTime:Date(),
                                  outageReported:false,
                                  accountFinaled:false,
                                  accountPaid:true)
            break
        default:
            status = OutageStatus(accountInfo: account,
                                  gasOnly:false,
                                  homeContactNumbner:"5555555555",
                                  isPasswordProtected:false,
                                  isUserAuthenticated:true,
                                  activeOutage:false,
                                  outageMessageTitle:"",
                                  outageMessage:"",
                                  restorationTime:Date(),
                                  outageReported:false,
                                  accountFinaled:false,
                                  accountPaid:false)
            break
            
        }
        return status
    }
}
