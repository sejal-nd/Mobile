//
//  FeatureFlagUtility.swift
//  Mobile
//
//  Created by Cody Dillon on 2/26/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

final class FeatureFlagUtility {
    enum FeatureFlagKey: String {
        case outageMapURL
        case streetlightMapURL
        case billingVideoURL
        case hasDefaultAccount
        case hasForgotPasswordLink
        case hasNewRegistration
        case paymentProgramAds
    }
    
    static let shared = FeatureFlagUtility()
    
    private init() {
        loadDefaultValues()
        fetchCloudValues()
    }
    
    var loadingDoneCallback: (() -> ())?
    var fetchComplete = false
    
    private func loadDefaultValues() {
        let appDefaults: [String: Any] = [
            FeatureFlagKey.outageMapURL.rawValue : "",
            FeatureFlagKey.streetlightMapURL.rawValue : "",
            FeatureFlagKey.billingVideoURL.rawValue : "",
            FeatureFlagKey.hasDefaultAccount.rawValue : false,
            FeatureFlagKey.hasForgotPasswordLink.rawValue : false,
            FeatureFlagKey.hasNewRegistration.rawValue : true,
            FeatureFlagKey.paymentProgramAds.rawValue : false
        ]
        
        UserDefaults.standard.setValuesForKeys(appDefaults)
    }
    
    
    // MARK: - Public API
    
    public func fetchCloudValues() {
        FeatureFlagService.getFeatureFlags { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let featureFlags):
                Log.info("Retrieved feature flag values from Azure")
                
                let keyedValues: [String: Any] = [
                    FeatureFlagKey.outageMapURL.rawValue : featureFlags.outageMapUrl,
                    FeatureFlagKey.streetlightMapURL.rawValue : featureFlags.streetlightMapUrl,
                    FeatureFlagKey.billingVideoURL.rawValue : featureFlags.billingVideoUrl,
                    FeatureFlagKey.hasDefaultAccount.rawValue : featureFlags.hasDefaultAccount,
                    FeatureFlagKey.hasForgotPasswordLink.rawValue : featureFlags.hasForgotPasswordLink,
                    FeatureFlagKey.hasNewRegistration.rawValue : featureFlags.hasNewRegistration,
                    FeatureFlagKey.paymentProgramAds.rawValue : featureFlags.paymentProgramAds
                ]
                
                UserDefaults.standard.setValuesForKeys(keyedValues)
                
                self.fetchComplete = true
                self.loadingDoneCallback?()
            case .failure(let error):
                Log.info("Error fetching feature flag values from Azure\(error)")
            }
        }
    }
    
    
    // MARK: - Retrieve Values
    
    public func string(forKey key: FeatureFlagKey) -> String {
        return UserDefaults.standard.string(forKey: key.rawValue) ?? ""
    }
    
    public func bool(forKey key: FeatureFlagKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
}
