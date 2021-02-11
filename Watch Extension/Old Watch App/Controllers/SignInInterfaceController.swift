//
//  SignInInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class SignInInterfaceController: WKInterfaceController {
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        AnalyticController.logScreenView(.sign_in_screen_view)
        
//        try? WatchSessionController.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate: true])
    }

}
