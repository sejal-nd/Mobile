//
//  WatchSessionManager.swift
//  Mobile
//
//  Created by Joseph Erlandson on 9/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchConnectivity

// Note that the WCSessionDelegate must be an NSObject
// So no, you cannot use the nice Swift struct here!
class WatchSessionManager: NSObject {
    
    // Instantiate the Singleton
    static let shared = WatchSessionManager()
    
    private override init() {
        super.init()
    }
    
    // Keep a reference for the session,
    // which will be used later for sending / receiving data
    // the session is now an optional, since it might not be supported
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    // Activate Session
    // This needs to be called to activate the session before first use!
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    private var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        guard let session = session, session.isPaired && session.isWatchAppInstalled else { return nil }
        return session
    }
    
    
    // MARK: - WCSessionDelegate
    
    /** Called when any of the Watch state properties change */
    func sessionWatchStateDidChange(_ session: WCSession) {
        // handle state change here
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let needsUpdate = applicationContext["askForUpdate"] as? Bool, needsUpdate {
                //check for valid jwt else clear and log out
                if MCSApi.shared.isAuthenticated(), let accessToken = MCSApi.shared.accessToken {
                    try? WatchSessionManager.shared.updateApplicationContext(applicationContext: ["authToken" : accessToken])
                } else {
                    try? WatchSessionManager.shared.updateApplicationContext(applicationContext: ["clearAuthToken" : true])
                }
            }
        }
    }
    
    private func sessionReachabilityDidChange(session: WCSession) {
        // handle session reachability change
        if session.isReachable {
            // great! continue on with Interactive Messaging
        } else {
            // 😥 prompt the user to unlock their iOS device
        }
    }
    
}

extension WatchSessionManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
}


// MARK: - Receiving User Info

extension WatchSessionManager {
    
    /// Handles receiving data for watch analytics
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("did receive user info:\(userInfo)")
        
        guard let screenName = userInfo["screenName"] as? String else {
            dLog("Failed to parse user info dictionary with key: screenName")
            return }
        
        FirebaseUtility.logWatchScreenView(screenName)
    }
}

// MARK: Interactive Messaging
extension WatchSessionManager {
    
    // Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        // check for validSession on iOS only (see above)
        // in your Watch App, you can just do an if session.reachable check
        guard let session = validSession, session.isReachable else { return nil }
        return session
    }
    
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    
    // This is where the magic happens!
    // Yes, that's it!
    // Just updateApplicationContext on the session!
    func updateApplicationContext(applicationContext: [String : Any]) throws {
        guard let session = validSession else { return }
        
        do {
            try session.updateApplicationContext(applicationContext)
        } catch let error {
            throw error
        }
    }
    
}
