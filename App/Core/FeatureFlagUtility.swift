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
        case ebillCommercialURL
        case hasDefaultAccount
        case hasForgotPasswordLink
        case paymentProgramAds
        case hasAssistanceEnrollment
        case agentisWidgets
        case isAzureAuthentication // B2C login with ROPC
        case isPkceAuthentication // B2C login with PKCE
        case hasAuthenticatedISUM
        case hasUnauthenticatedISUM
        case isLowPaymentAllowed // Paymentus <$5
        case isB2CAuthentication // calculated value = isAzureAuthentication || isPkceAuthentication
        case isGamificationEnabled
        case hasAssistanceFinder
        // Commercial Agentis Widgets
        case isAgentisElectricUsageWidget
        case isAgentisGasUsageWidget
        case isAgentisElectricCompareBillsWidget
        case isAgentisGasCompareBillsWidget
        case isAgentisElectricTipsWidget
        case isAgentisGasTipsWidget
        case isAgentisProjectedUsageWidget
        case isACEAMI
    }
    
    static let shared = FeatureFlagUtility()
    
    private init() {
        loadDefaultValues()
        fetchCloudValues()
    }
    
    var loadingDoneCallback: (() -> ())?
    
    private func loadDefaultValues() {
        let appDefaults: [String: Any] = [
            FeatureFlagKey.outageMapURL.rawValue : "",
            FeatureFlagKey.streetlightMapURL.rawValue : "",
            FeatureFlagKey.billingVideoURL.rawValue : "",
            FeatureFlagKey.ebillCommercialURL.rawValue : "",
            FeatureFlagKey.hasDefaultAccount.rawValue : false,
            FeatureFlagKey.hasForgotPasswordLink.rawValue : false,
            FeatureFlagKey.paymentProgramAds.rawValue : false,
            FeatureFlagKey.hasAssistanceEnrollment.rawValue : false,
            FeatureFlagKey.agentisWidgets.rawValue : false,
            FeatureFlagKey.isAzureAuthentication.rawValue : false,
            FeatureFlagKey.isPkceAuthentication.rawValue : false,
            FeatureFlagKey.hasAuthenticatedISUM.rawValue : false,
            FeatureFlagKey.hasUnauthenticatedISUM.rawValue : false,
            FeatureFlagKey.isB2CAuthentication.rawValue : false,
            FeatureFlagKey.isGamificationEnabled.rawValue: false,
            FeatureFlagKey.isLowPaymentAllowed.rawValue : false,
            FeatureFlagKey.hasAssistanceFinder.rawValue : false,
            FeatureFlagKey.isAgentisElectricUsageWidget.rawValue: false,
            FeatureFlagKey.isAgentisGasUsageWidget.rawValue: false,
            FeatureFlagKey.isAgentisElectricCompareBillsWidget.rawValue: false,
            FeatureFlagKey.isAgentisGasCompareBillsWidget.rawValue: false,
            FeatureFlagKey.isAgentisElectricTipsWidget.rawValue: false,
            FeatureFlagKey.isAgentisGasTipsWidget.rawValue: false,
            FeatureFlagKey.isAgentisProjectedUsageWidget.rawValue: false,
            FeatureFlagKey.isACEAMI.rawValue: false
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
                    FeatureFlagKey.ebillCommercialURL.rawValue : featureFlags.ebillCommercialURL,
                    FeatureFlagKey.hasDefaultAccount.rawValue : featureFlags.hasDefaultAccount,
                    FeatureFlagKey.hasForgotPasswordLink.rawValue : featureFlags.hasForgotPasswordLink,
                    FeatureFlagKey.paymentProgramAds.rawValue : featureFlags.paymentProgramAds,
                    FeatureFlagKey.hasAssistanceEnrollment.rawValue : featureFlags.hasAssistanceEnrollment,
                    FeatureFlagKey.agentisWidgets.rawValue : featureFlags.agentisWidgets,
                    FeatureFlagKey.isAzureAuthentication.rawValue : featureFlags.isAzureAuthentication,
                    FeatureFlagKey.isPkceAuthentication.rawValue : featureFlags.isPkceAuthentication,
                    FeatureFlagKey.hasAuthenticatedISUM.rawValue : featureFlags.hasAuthenticatedISUM,
                    FeatureFlagKey.hasUnauthenticatedISUM.rawValue : featureFlags.hasUnauthenticatedISUM,
                    FeatureFlagKey.isB2CAuthentication.rawValue : featureFlags.isAzureAuthentication || featureFlags.isPkceAuthentication,
                    FeatureFlagKey.isGamificationEnabled.rawValue : featureFlags.isGamificationEnabled,
                    FeatureFlagKey.isLowPaymentAllowed.rawValue : featureFlags.isLowPaymentAllowed,
                    FeatureFlagKey.hasAssistanceFinder.rawValue : featureFlags.hasAssistanceFinder,
                    FeatureFlagKey.isAgentisElectricUsageWidget.rawValue : featureFlags.isAgentisElectricUsageWidget,
                    FeatureFlagKey.isAgentisGasUsageWidget.rawValue : featureFlags.isAgentisGasUsageWidget,
                    FeatureFlagKey.isAgentisElectricCompareBillsWidget.rawValue : featureFlags.isAgentisElectricCompareBillsWidget,
                    FeatureFlagKey.isAgentisGasCompareBillsWidget.rawValue : featureFlags.isAgentisGasCompareBillsWidget,
                    FeatureFlagKey.isAgentisElectricTipsWidget.rawValue : featureFlags.isAgentisElectricTipsWidget,
                    FeatureFlagKey.isAgentisGasTipsWidget.rawValue : featureFlags.isAgentisGasTipsWidget,
                    FeatureFlagKey.isAgentisProjectedUsageWidget.rawValue : featureFlags.isAgentisProjectedWidget,
                    FeatureFlagKey.isACEAMI.rawValue: featureFlags.isACEAMI
                ]
                
                UserDefaults.standard.setValuesForKeys(keyedValues)
                
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

