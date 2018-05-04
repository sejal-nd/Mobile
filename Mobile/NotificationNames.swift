//
//  NotificationNames.swift
//  Mobile
//
//  Created by Marc Shilling on 6/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

extension NSNotification.Name {
    
    static let DidReceiveInvalidAuthToken = NSNotification.Name(rawValue: "kDidReceiveInvalidAuthToken")
    static let DidMaintenanceModeTurnOn = NSNotification.Name(rawValue: "kDidMaintenanceModeTurnOn")
    static let DidSelectEnrollInAutoPay = NSNotification.Name(rawValue: "kDidSelectEnrollInAutoPay")
    static let DidChangeBudgetBillingEnrollment = NSNotification.Name(rawValue: "kDidChangeBudgetBillingEnrollment")
    static let DidTapOnPushNotification = NSNotification.Name(rawValue: "kDidTapOnPushNotification")
    static let DidTapOnShortcutItem = NSNotification.Name(rawValue: "kDidTapOnShortcutItem")
}
