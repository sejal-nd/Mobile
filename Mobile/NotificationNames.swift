//
//  NotificationNames.swift
//  Mobile
//
//  Created by Marc Shilling on 6/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

extension NSNotification.Name {
    
    static let didReceiveInvalidAuthToken = NSNotification.Name(rawValue: "kDidReceiveInvalidAuthToken")
    static let didMaintenanceModeTurnOn = NSNotification.Name(rawValue: "kDidMaintenanceModeTurnOn")
    static let didSelectEnrollInAutoPay = NSNotification.Name(rawValue: "kDidSelectEnrollInAutoPay")
    static let didChangeBudgetBillingEnrollment = NSNotification.Name(rawValue: "kDidChangeBudgetBillingEnrollment")
    static let didTapOnPushNotification = NSNotification.Name(rawValue: "kDidTapOnPushNotification")
    static let didTapOnShortcutItem = NSNotification.Name(rawValue: "kDidTapOnShortcutItem")
    static let shouldShowIOSVersionWarning = NSNotification.Name(rawValue: "kShouldShowIOSVersionWarning")
}
