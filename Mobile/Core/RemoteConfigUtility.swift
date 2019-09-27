//
//  FirebaseRemoteConfigUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 9/27/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import Firebase

final class RemoteConfigUtility {
    enum RemoteConfigKey: String {
        case outageMapURL
        case streetlightOutageMapURL
    }
    
    static let shared = RemoteConfigUtility()
    
    private init() {
        loadDefaultValues()
        fetchCloudValues()
    }
    
    var loadingDoneCallback: (() -> ())?
    var fetchComplete = false
    
    private func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            RemoteConfigKey.outageMapURL.rawValue : "",
            RemoteConfigKey.streetlightOutageMapURL.rawValue : ""
        ]
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
    }
    
    private func activateDebugMode() {
        let debugSettings = RemoteConfigSettings(developerModeEnabled: true)
        RemoteConfig.remoteConfig().configSettings = debugSettings
    }
    
    
    // MARK: - Public API
    
    public func fetchCloudValues() {
        let fetchDuration: TimeInterval = 3600 // in seconds

        RemoteConfig.remoteConfig().fetch(withExpirationDuration: fetchDuration) { [weak self] status, error in
            
            if let error = error {
                dLog("Error fetching remote config values from firebase\(error)")
                return
            }
            
            RemoteConfig.remoteConfig().activateFetched()
            self?.fetchComplete = true
            self?.loadingDoneCallback?()
            dLog("Retrieved remote config values from firebase")
        }
    }
    
    
    // MARK: - Retrieve Values
    
    public func string(forKey key: RemoteConfigKey) -> String {
      return RemoteConfig.remoteConfig()[key.rawValue].stringValue ?? ""
    }
    
    public func bool(forKey key: RemoteConfigKey) -> Bool {
      return RemoteConfig.remoteConfig()[key.rawValue].boolValue
    }
}
