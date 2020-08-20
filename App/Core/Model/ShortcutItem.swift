//
//  QuickAction.swift
//  Mobile
//
//  Created by Samuel Francis on 4/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

enum ShortcutItem: String {
    case payBill = "PayBill"
    case reportOutage = "ReportOutage"
    case viewUsageOptions = "ViewUsageOptions"
    case alertPreferences = "AlertPreferences"
    case none = ""
    
    init(identifier: String) {
        self = ShortcutItem(rawValue: identifier) ?? .none
    }
}
