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
    class func createAuthenticationService() -> AuthenticationService {
        switch(Environment.sharedInstance.environmentName) {
        case "DEV", "TEST", "STAGE", "AUT":
            return OMCAuthenticationService()
        default:
            return OMCAuthenticationService()
        }
    }
    
    //TODO: UserService, BillService etc.
}
