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
    var outageReportedFromPhone: (() -> Void)? = nil
    
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
            #if os(watchOS)
            // New Azure Auth Token
            if let authToken = applicationContext[UserSession.tokenKeychainKey] as? String {
                // Save to KeyChain
                KeychainController.shared[keychainKeys.authToken] = authToken
                KeychainController.shared[UserSession.tokenKeychainKey] = authToken
                KeychainController.shared[UserSession.refreshTokenKeychainKey] = (applicationContext[UserSession.refreshTokenKeychainKey] ?? "") as? String
                KeychainController.shared[UserSession.tokenExpirationDateKeychainKey] = (applicationContext[UserSession.tokenExpirationDateKeychainKey] ?? "") as? String
                KeychainController.shared[UserSession.refreshTokenExpirationDateKeychainKey] = (applicationContext[UserSession.refreshTokenExpirationDateKeychainKey] ?? "") as? String
                
                self?.authTokenDidUpdate?()
            }
            
            // User reported outage on phone
            if let outageReported = applicationContext[keychainKeys.outageReported] as? Bool, outageReported {
                self?.outageReportedFromPhone?()
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
                Log.error("Failed to parse user info dictionary with key: screenName")
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
