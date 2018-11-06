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
        aLog("NOTICE: Apple Watch App Did Finish Launching.")
        
        WatchSessionManager.shared.startSession()

        // Initialize Google Analytics Singleton
        _ = GATracker.shared
        
        setInitialScreen()
        if !UserDefaults.standard.hasRunBefore {
            UserDefaults.standard.hasRunBefore = true
            try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate: true])
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: OpenAppOnPhoneInterfaceController.className, context: [:] as AnyObject)])
        }
    }

    
    // MARK: - Helper
    
    private func setInitialScreen() {
        if KeychainUtility.shared[keychainKeys.authToken] != nil {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: OutageInterfaceController.className, context: [:] as AnyObject), (name: UsageInterfaceController.className, context: [:] as AnyObject), (name: BillInterfaceController.className, context: [:] as AnyObject)])
        } else {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: SignInInterfaceController.className, context: [:] as AnyObject)])
        }
    }
    
}
