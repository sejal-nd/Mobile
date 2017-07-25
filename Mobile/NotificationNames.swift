//
//  NotificationNames.swift
//  Mobile
//
//  Created by Marc Shilling on 6/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

extension NSNotification.Name {
    
    static let DidReceiveInvalidAuthToken = NSNotification.Name(rawValue: "kDidReceiveInvalidAuthToken")
    static let DidTapAccountVerificationDeepLink = NSNotification.Name(rawValue: "kDidTapAccountVerificationDeepLink")
    static let DidMaintenanceModeTurnOn = NSNotification.Name(rawValue : "kDidMaintenanceModeTurnOn")
}
