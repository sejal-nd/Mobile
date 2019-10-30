//
//  ExtensionDelegate.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 8/31/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        dLog("NOTICE: Apple Watch App Did Finish Launching.")
        
        WatchSessionManager.shared.startSession()

        setInitialScreen()
    }

    
    // MARK: - Helper
    
    private func setInitialScreen() {
        let authToken = KeychainUtility.shared[keychainKeys.authToken]
        
        if authToken != nil {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: OutageInterfaceController.className, context: [:] as AnyObject),
                                                                               (name: UsageInterfaceController.className, context: [:] as AnyObject),
                                                                               (name: BillInterfaceController.className, context: [:] as AnyObject)])
        } else {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: SignInInterfaceController.className, context: [:] as AnyObject)])
        }
    }
    
}
