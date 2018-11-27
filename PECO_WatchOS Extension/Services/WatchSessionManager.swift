//
//  WatchSessionManager.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchConnectivity
import WatchKit

protocol AuthTokenChangeDelegate {
    func authTokenSuccess()
    
    func authTokenFailure()
}

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchSessionManager()
    
    private override init() {
        super.init()
    }
    
    public var authTokenChangeDelegate: AuthTokenChangeDelegate?
    
    private let session: WCSession = WCSession.default
    
    func startSession() {
        session.delegate = self
        session.activate()
        
        aLog("NOTICE: Watch Session Starting...")
    }
    
    func isReachable() -> Bool {
        return session.isReachable
    }
   
}

// MARK: - Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let clearAuthToken = applicationContext[keychainKeys.clearAuthToken] as? Bool, clearAuthToken {
                KeychainUtility.shared[keychainKeys.authToken] = nil
                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: SignInInterfaceController.className, context: [:] as AnyObject)])
            } else if let authToken = applicationContext[keychainKeys.authToken] as? String {
                
                // Save to KeyChain
                KeychainUtility.shared[keychainKeys.authToken] = authToken

                self?.authTokenChangeDelegate?.authTokenSuccess()
                
                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: OutageInterfaceController.className, context: [:] as AnyObject), (name: UsageInterfaceController.className, context: [:] as AnyObject), (name: BillInterfaceController.className, context: [:] as AnyObject)])
            } else {
                self?.authTokenChangeDelegate?.authTokenFailure()
            }
            if let outageReported = applicationContext[keychainKeys.outageReported] as? Bool, outageReported {
                NotificationCenter.default.post(name: Notification.Name.outageReported, object: nil)
            }
            
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

}
extension WatchSessionManager {
    
    // This is where the magic happens!
    // Yes, that's it!
    // Just updateApplicationContext on the session!
    func updateApplicationContext(applicationContext: [String : Any]) throws {
        do {
            try session.updateApplicationContext(applicationContext)
        } catch let error {
            throw error
        }
    }
    
}
