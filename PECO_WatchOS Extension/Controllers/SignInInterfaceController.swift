//
//  SignInInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class SignInInterfaceController: WKInterfaceController {
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Alerts if auth token changes
        WatchSessionManager.shared.authTokenChangeDelegate = self
    }
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        GATracker.shared.screenView(screenName: SignInInterfaceController.className, customParameters: nil)
    }

}


// MARK: - Auth Token Change Delegate Method

extension SignInInterfaceController: AuthTokenChangeDelegate {
    
    func authTokenSuccess() {
        // Replace lock screen with main app
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: OutageInterfaceController.className, context: [:] as AnyObject), (name: UsageInterfaceController.className, context: [:] as AnyObject), (name: BillInterfaceController.className, context: [:] as AnyObject)])
    }
    
    func authTokenFailure() {
        aLog("Auth Token Was Not Recieved.")
    }

}
