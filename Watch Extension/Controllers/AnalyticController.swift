//
//  FirebaseUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 9/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

enum AnalyticController {
    enum ScreenName: String {
        case signIn = "sign_in_screen_view"
        case reportOuage = "report_outage_screen_view"
        case bill = "bill_screen_view"
        case outage = "outage_screen_view"
        case usage = "usage_screen_view"
        case accountList = "account_list_screen_view"
    }
    
    static func logScreenView(_ screenName: ScreenName) {
        WatchSessionController.shared.transferUserInfo(userInfo: ["screenName": screenName.rawValue])
    }
    
    /// Used for relaying apple watch device log to iPhone console
    /// - Parameter value: Value to be displayed in log
    static func logConsole(_ value: String) {
        WatchSessionController.shared.transferUserInfo(userInfo: ["console": value])
    }
}
