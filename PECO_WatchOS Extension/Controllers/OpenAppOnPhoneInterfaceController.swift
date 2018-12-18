//
//  OpenAppOnPhoneInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Jester, Carlton (US - Arlington) on 11/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit
import Foundation


class OpenAppOnPhoneInterfaceController: WKInterfaceController {

    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        GATracker.shared.screenView(screenName: OpenAppOnPhoneInterfaceController.className, customParameters: nil)
        try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate: true])
    }

}
