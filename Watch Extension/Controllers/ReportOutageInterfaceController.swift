//
//  SignInInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class ReportOutageInterfaceController: WKInterfaceController {
    
    
    // MARK: - Interface Life Cycle

    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        WatchAnalyticUtility.logScreenView(.report_outage_screen_view)
    }

}
