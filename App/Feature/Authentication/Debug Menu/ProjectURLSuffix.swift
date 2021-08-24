//
//  ProjectURLSuffix.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 1/13/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

enum ProjectURLSuffix: String, Identifiable, Equatable, CaseIterable {
    var id: String { rawValue }
    
    case none = "None"
    case billing = "Billing Enhancements"
    case mma = "Manage My Account"
    case payments = "Payment Enhancements"
    case comet = "COMET"
    case hotfix = "Hotfix"
    case auth = "Auth"
    
    case datares = "Data Resiliency"
    case landlord = "Landlord"
    case outagejourney = "Outage Journey"
    case sam = "Smart Assistance Manager"
    case signupmove = "ISUM"
    case maintenance = "Maintenance"
}

// MARK: Convenience

extension ProjectURLSuffix {
    var projectPath: String {
        switch self {
        case .none:
            return ""
        case .billing:
            return "/billing"
        case .mma:
            return "/manage-my-account"
        case .payments:
            return "/paymentenhancements"
        case .comet:
            return "/comets4hana"
        case .hotfix:
            return "/hotfix"
        case .auth:
            return "/euauth"
        case .datares:
            return "/datares"
        case .landlord:
            return "/landlord"
        case .outagejourney:
            return "/outagejourney"
        case .sam:
            return "/sam"
        case .signupmove:
            return "/signupmove"
        case .maintenance:
            return "/maintenance"
        }
    }
    
    var projectURLString: String {
        var urlString = self.projectPath
        urlString.remove(at: urlString.startIndex)
        return urlString
    }
}
