//
//  FirebaseUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 9/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

struct AnalyticController {
    enum ScreenName: String {
        case sign_in_screen_view
        case please_sync_screen_view
        case report_outage_screen_view
        case bill_screen_view
        case outage_screen_view
        case usage_screen_view
        case account_list_screen_view
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
