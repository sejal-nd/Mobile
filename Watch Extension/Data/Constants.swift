//
//  Constants.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

enum AppConstant {
    enum WatchSessionKey {
        static let consoleUser = "console"
        static let screenName = "screenName"
        static let authToken = "authToken"
        static let outageReported = "outageReported"
    }
    
    enum ImageName: String {
        case alert
        case autoPay
        case billNotReady
        case electric
        case error
        case gas
        case maintenanceMode
        case noOutageData
        case noUsageData
        case passwordProtected
        case reportOutageSignIn
        case scheduledPayment
        case signIn
        case thankYouPayment
    }
}
