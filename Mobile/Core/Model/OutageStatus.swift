//
//  OutageStatus.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct OutageStatus {
    let accountInfo: Account
    let gasOnly: Bool
    let homeContactNumbner: String
    let isPasswordProtected: Bool
    let isUserAuthenticated: Bool
    let activeOutage: Bool
    let outageMessageTitle: String
    let outageMessage: String
    let outageReported: Bool
    let accountFinaled: Bool
    let accountPaid: Bool
    var restorationTime: Date?
    var outageInfo: OutageInfo?
    
    init(accountInfo: Account,
         gasOnly: Bool,
         homeContactNumber: String,
         isPasswordProtected: Bool,
         isUserAuthenticated: Bool,
         activeOutage: Bool,
         outageMessageTitle: String,
         outageMessage: String,
         accountFinaled: Bool,
         accountPaid: Bool,
         restorationTime: Date?=nil,
         outageInfo: OutageInfo?=nil) {
        
        self.accountInfo = accountInfo
        self.gasOnly = gasOnly
        self.homeContactNumbner = homeContactNumber
        self.isPasswordProtected = isPasswordProtected
        self.isUserAuthenticated = isUserAuthenticated
        self.activeOutage = activeOutage
        self.outageMessageTitle = outageMessageTitle
        self.outageMessage = outageMessage
        self.accountFinaled = accountFinaled
        self.accountPaid = accountPaid
        
        self.outageReported = outageInfo != nil ? true : false;
        if(outageInfo != nil) {
            self.outageInfo = outageInfo!
        }
        if(restorationTime != nil) {
            self.restorationTime = restorationTime!
        }
        
    }
}
