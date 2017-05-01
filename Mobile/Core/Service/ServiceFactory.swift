//
//  ServiceFactory.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

/// Utility class for intantiating Service Instances
class ServiceFactory {
    
    //static let sharedOutageService = MockOutageService()
    static let sharedOutageService = OMCOutageService()
    
    class func createAuthenticationService() -> AuthenticationService {
        switch(Environment.sharedInstance.environmentName) {
        case "DEV", "TEST", "STAGE", "AUT":
            return OMCAuthenticationService()
        default:
            return OMCAuthenticationService()
        }
    }
    
    class func createFingerprintService() -> FingerprintService {
        return FingerprintService()
    }
    
    class func createAccountService() -> AccountService {
        //return MockAccountService()
        return OMCAccountService()
    }
    
    class func createOutageService() -> OutageService {
        return sharedOutageService
    }
    
    class func createBillService() -> BillService {
        return OMCBillService()
    }
}
