//
//  WatchSessionMananger.swift
//  Mobile
//
//  Created by Joseph Erlandson on 10/30/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import WatchConnectivity
#if os(watchOS)
import WatchKit
#else
import Foundation
#endif

class WatchSessionController: NSObject, WCSessionDelegate {
    static let shared = WatchSessionController()
    
    var authTokenDidUpdate: (() -> Void)? = nil
    
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    /// isPaired - The user has to have their device paired to the watch'
    /// isWatchAppInstalled - The user must have your watch app installed
    public var validSession: WCSession? {
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        #if os(iOS)
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        
        Log.info("Invalid Watch Session.")
        return nil
        #else
        return session
        #endif
    }
    
    public func start() {
        session?.delegate = self
        session?.activate()
    }
    
}


// MARK: - Application Context
// Use when your app needs only the latest info: If the data was not sent, it will be replaced.

extension WatchSessionController {
    
    // Sender
    func updateApplicationContext(applicationContext: [String : Any]) throws {
        guard let session = validSession else {
            Log.info("Failed to update application context, invalid session.")
            return
        }
        
        do {
            try session.updateApplicationContext(applicationContext)
        } catch let error {
            Log.info("Failed to update application context:\n\(error.localizedDescription)")
            throw error
        }
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            #if os(iOS)
            #warning("todo, what does ths do?")
            if let needsUpdate = applicationContext[keychainKeys.askForUpdate] as? Bool, needsUpdate {
                //check for valid jwt else clear and log out
                if AuthenticationService.isLoggedIn() {
                    let authToken = UserSession.token
                    try? WatchSessionController.shared.updateApplicationContext(applicationContext: [keychainKeys.authToken : authToken])
                }
            }
            #elseif os(watchOS)
            
            // New MCS Auth Token
            if let authToken = applicationContext[UserSession.tokenKeychainKey] as? String {
                // Save to KeyChain
                KeychainManager.shared[keychainKeys.authToken] = authToken
                KeychainManager.shared[UserSession.tokenKeychainKey] = authToken

                self?.authTokenDidUpdate?()
            }
            
            
            #warning("todo, cleanup")
            KeychainManager.shared[UserSession.refreshTokenKeychainKey] = (applicationContext[UserSession.refreshTokenKeychainKey] ?? "") as? String
            KeychainManager.shared[UserSession.tokenExpirationDateKeychainKey] = (applicationContext[UserSession.tokenExpirationDateKeychainKey] ?? "") as? String
            KeychainManager.shared[UserSession.refreshTokenExpirationDateKeychainKey] = (applicationContext[UserSession.refreshTokenExpirationDateKeychainKey] ?? "") as? String
            
            // User reported outage on mobile app
            #warning("todo, consider")
            if let outageReported = applicationContext[keychainKeys.outageReported] as? Bool, outageReported {
                NotificationCenter.default.post(name: Notification.Name.outageReported, object: nil)
            }
            #endif
        }
    }
}


// MARK: - User Info
// Use when your app needs all the data: FIFO queue

extension WatchSessionController {
    
    // Sender
    func transferUserInfo(userInfo: [String : Any]) {
        validSession?.transferUserInfo(userInfo)
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            #if os(iOS)

            // Logging
            if let value = userInfo["console"] as? String {
                Log.info("WATCH CONSOLE: \(value)")
                return
            }
            
            guard let screenName = userInfo["screenName"] as? String else {
                Log.info("Failed to parse user info dictionary with key: screenName")
                return
            }
            
            FirebaseUtility.logWatchScreenView(screenName)
            #endif
        }
    }
    
}


// MARK: - Unused Required Delegate Methods

extension WatchSessionController {
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) { }
    #endif
    
}
