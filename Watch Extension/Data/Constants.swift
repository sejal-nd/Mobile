//
//  Constants.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

// MARK: - Notification Names

#warning("Audit, remove unused")


#warning("none of these are used anymore")
extension Notification.Name {
    static let outageReported: Notification.Name = Notification.Name(rawValue: "outageReportedNotificationName")
    static let currentAccountUpdated: Notification.Name = Notification.Name(rawValue: "currentAccountUpdated")
    
    static let accountListDidUpdate: Notification.Name = Notification.Name(rawValue: "accountListDidUpdate")
    static let defaultAccountDidUpdate: Notification.Name = Notification.Name(rawValue: "defaultAccountDidUpdate")
    static let accountDetailsDidUpdate: Notification.Name = Notification.Name(rawValue: "accountDetailsDidUpdate")
    static let outageStatusDidUpdate: Notification.Name = Notification.Name(rawValue: "outageStatusDidUpdate")
    static let billForecastDidUpdate: Notification.Name = Notification.Name(rawValue: "billForecastDidUpdate")
    static let maintenanceModeDidUpdate: Notification.Name = Notification.Name(rawValue: "maintenanceModeDidUpdate")
    static let errorDidOccur: Notification.Name = Notification.Name(rawValue: "errorDidOccur")
}


// MARK: - Assets

enum AppImage {
    case alert
    case autoPay
    case billNotReady
    case checkmark_white
    case commercial_mini_white
    case commercial
    case error
    case gasOnly
    case maintenanceMode
    case outageUnavailable
    case passwordProtected
    case paymentConfirmation
    case reportOutageSignIn
    case residential_mini_white
    case residential
    case scheduledPayment
    case signin
    case usage
    case electric
    case gas
    case usageProgress(Int)
    case onAnimation
    case offAnimation
    case residentialMenuItem
    case gasMenuItem
    case electricMenuItem
    
    var image: UIImage {
        return UIImage(imageLiteralResourceName: self.name)
    }
    
    var name: String {
        switch self {
        case .alert:
            return "alert"
        case .autoPay:
            return "autoPay"
        case .billNotReady:
            return "billNotReady"
        case .checkmark_white:
            return "checkmark_white"
        case .commercial_mini_white:
            return "commercial_mini_white"
        case .commercial:
            return "commercial"
        case .error:
            return "error"
        case .gasOnly:
            return "gasOnly"
        case .maintenanceMode:
            return "maintenanceMode"
        case .outageUnavailable:
            return "outageUnavailable"
        case .passwordProtected:
            return "passwordProtected"
        case .paymentConfirmation:
            return "paymentConfirmation"
        case .reportOutageSignIn:
            return "reportOutageSignIn"
        case .residential_mini_white:
            return "residential_mini_white"
        case .residential:
            return "residential"
        case .scheduledPayment:
            return "scheduledPayment"
        case .signin:
            return "signin"
        case .usage:
            return "usage"
        case .electric:
            return "electric"
        case .gas:
            return "gas"
        case .usageProgress(let progress):
            return "usageGraph\(progress)"
        case .onAnimation:
            return "On_"
        case .offAnimation:
            return "Out_"
        case .residentialMenuItem:
            return "residentialMenuItem"
        case .gasMenuItem:
            return "gasMenuItem"
        case .electricMenuItem:
            return "electricMenuItem"
        }
    }
}

