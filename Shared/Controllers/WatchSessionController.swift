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
    private override init() { }
    
    static let shared = WatchSessionController()
    
    var authTokenDidUpdate: (() -> Void)? = nil
    var outageReportedFromPhone: (() -> Void)? = nil
    
    private let keychain = KeychainController.default
    
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
        
        Log.error("Invalid Watch Session.")
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

// MARK: Application Context
/// Use when your app needs only the latest info: If the data was not sent, it will be replaced.

extension WatchSessionController {
    enum Key {
        static let tokenKeychainKey = "jwtToken"
        static let tokenExpirationDateKeychainKey = "jwtTokenExpirationDate"
        static let refreshTokenKeychainKey = "jwtRefreshToken"
        static let refreshTokenExpirationDateKeychainKey = "jwtRefreshTokenExpirationDate"
        static let consoleUser = "console"
        static let screenName = "screenName"
        static let outageReported = "outageReported"
    }
    
    // Sender
    func updateApplicationContext(applicationContext: [String : Any]) throws {
        guard let session = validSession else {
            Log.warning("Failed to update application context, invalid session.")
            return
        }
        
        do {
            try session.updateApplicationContext(applicationContext)
        } catch let error {
            Log.error("Failed to update application context:\n\(error.localizedDescription)")
            throw error
        }
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            // Azure Auth Token
            if let authToken = applicationContext[WatchSessionController.Key.tokenKeychainKey] as? String,
               let tokenExpirationDate = applicationContext[WatchSessionController.Key.tokenExpirationDateKeychainKey] as? String,
               let refreshToken = applicationContext[WatchSessionController.Key.refreshTokenKeychainKey] as? String,
               let refreshTokenExpirationDate = applicationContext[WatchSessionController.Key.refreshTokenExpirationDateKeychainKey] as? String {
                
                // Save to KeyChain
                self?.keychain.set(authToken, forKey: .tokenKeychainKey)
                self?.keychain.set(tokenExpirationDate, forKey: .tokenExpirationDateKeychainKey)
                self?.keychain.set(refreshToken, forKey: .refreshTokenKeychainKey)
                self?.keychain.set(refreshTokenExpirationDate, forKey: .refreshTokenExpirationDateKeychainKey)
                
                self?.authTokenDidUpdate?()
            }
            
            #if os(watchOS)
            // User reported outage on phone
            if let outageReported = applicationContext[WatchSessionController.Key.outageReported] as? Bool, outageReported {
                self?.outageReportedFromPhone?()
            }
            #endif
        }
    }
}

// MARK: - User Info
/// Use when your app needs all the data: FIFO queue

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
            if let value = userInfo[WatchSessionController.Key.consoleUser] as? String {
                Log.info("WATCH CONSOLE: \(value)")
                return
            }
            
            guard let screenName = userInfo[WatchSessionController.Key.screenName] as? String else {
                Log.error("Failed to parse user info dictionary with key: screenName")
                return
            }

            // todo, this could be cleaned up
            let screen: Screen
            switch screenName {
            case "sign_in_screen_view":
                screen = .watchSignInView(className: screenName)
            case "account_list_screen_view":
                screen = .watchAccountListView(className: screenName)
            case "outage_screen_view":
                screen = .watchOutageView(className: screenName)
            case "report_outage_screen_view":
                screen = .watchReportOutageView(className: screenName)
            case "usage_screen_view":
                screen = .watchUsageView(className: screenName)
            case "bill_screen_view":
                screen = .watchBillView(className: screenName)
            default:
                return
            }

            FirebaseUtility.logWatchScreenView(screen)
            #endif
        }
    }
}


// MARK: - Unused Required Delegate Methods

extension WatchSessionController {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) { }
    #endif
}
