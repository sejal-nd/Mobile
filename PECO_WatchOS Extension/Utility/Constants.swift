//
//  Constants.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

struct Errors {
    
    struct Code {
        
        static let passwordProtected = "09122"
        
        static let noAccountsFound = "09121"
        
        static let invalidInformation = "87221"
        
        static let noAuthTokenFound = "981156"
        
    }
    
    static let passwordProtected = ServiceError(serviceCode: Code.passwordProtected, serviceMessage: "Account is Password Protected, cannot show data.", cause: nil)
    
    static let noAccountsFound = ServiceError(serviceCode: Code.noAccountsFound, serviceMessage: "Could not locate the current account in AccountStore.shared.getSelectedAccounts.", cause: nil)
    
    static let invalidInformation = ServiceError(serviceCode: Code.invalidInformation, serviceMessage: "Invalid Info: nil data returned for expected request without throwing an error.", cause: nil)
    
    static let noAuthTokenFound = ServiceError(serviceCode: Code.noAuthTokenFound, serviceMessage: "No Auth Token in Keychain.", cause: nil)
    
}

struct keychainKeys {
    
    static let authToken = "authToken"
    
    static let clearAuthToken = "clearAuthToken"
    
    static let askForUpdate = "askForUpdate"
    
}

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
        }
    }
}

