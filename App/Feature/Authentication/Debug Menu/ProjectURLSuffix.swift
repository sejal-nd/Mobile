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
    case phi = "PHI"
    case hotfix = "Hotfix"
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
        case .phi:
            return "/phimobile"
        case .hotfix:
            return "/hotfix"
        }
    }
}
