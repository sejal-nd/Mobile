//
//  FeatureFlags.swift
//  Mobile
//
//  Created by Cody Dillon on 2/26/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct FeatureFlagsContainer: Decodable {
    public var iOS: FeatureFlags
    
    enum CodingKeys: String, CodingKey {
        case iOS = "ios"
        case iOSrc = "ios_rc"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if Configuration.shared.environmentName == .rc {
            iOS = try container.decodeIfPresent(FeatureFlags.self, forKey: .iOSrc) ?? FeatureFlags()
        } else {
            iOS = try container.decodeIfPresent(FeatureFlags.self, forKey: .iOS) ?? FeatureFlags()
        }
    }
}

public struct FeatureFlags: Decodable {
    public var outageMapUrl: String = ""
    public var streetlightMapUrl: String = ""
    public var billingVideoUrl: String = ""
    public var ebillCommercialURL: String = ""
    public var hasDefaultAccount: Bool = false
    public var hasForgotPasswordLink: Bool = false
    public var paymentProgramAds: Bool = false
    public var hasAssistanceEnrollment: Bool = false
    public var agentisWidgets: Bool = false
    public var isAzureAuthentication: Bool = false
    public var isPkceAuthentication: Bool = false
    public var hasAuthenticatedISUM: Bool = false
    public var hasUnauthenticatedISUM: Bool = false
    public var isGamificationEnabled: Bool = false
    public var isAgentisElectricUsageWidget: Bool = false
    public var isAgentisGasUsageWidget: Bool = false
    public var isAgentisElectricCompareBillsWidget: Bool = false
    public var isAgentisGasCompareBillsWidget: Bool = false
    public var isAgentisElectricTipsWidget: Bool = false
    public var isAgentisGasTipsWidget: Bool = false
    public var isAgentisProjectedWidget: Bool = false
    public var isLowPaymentAllowed: Bool = false
    public var hasAssistanceFinder: Bool = false
    public var isACEAMI: Bool = false

    enum CodingKeys: String, CodingKey {
        case outageMapUrl = "outageMapURL"
        case streetlightMapUrl = "streetlightMapURL"
        case billingVideoUrl = "billingVideoURL"
        case ebillCommercialURL
        case hasDefaultAccount
        case hasForgotPasswordLink
        case paymentProgramAds
        case hasAssistanceEnrollment
        case agentisWidgets
        case isAzureAuthentication
        case isPkceAuthentication
        case hasAuthenticatedISUM
        case hasUnauthenticatedISUM
        case isGamificationEnabled
        case isAgentisElectricUsageWidget = "isAgentisUsageWidget"
        case isAgentisGasUsageWidget
        case isAgentisElectricCompareBillsWidget = "isAgentisCompareWidget"
        case isAgentisGasCompareBillsWidget
        case isAgentisElectricTipsWidget = "isAgentisTipsWidget"
        case isAgentisGasTipsWidget
        case isAgentisProjectedWidget
        case isLowPaymentAllowed
        case hasAssistanceFinder
        case isACEAMI
    }
    
    public init() {
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        outageMapUrl = try container.decodeIfPresent(String.self, forKey: .outageMapUrl) ?? ""
        streetlightMapUrl = try container.decodeIfPresent(String.self, forKey: .streetlightMapUrl) ?? ""
        billingVideoUrl = try container.decodeIfPresent(String.self, forKey: .billingVideoUrl) ?? ""
        ebillCommercialURL = try container.decodeIfPresent(String.self, forKey: .ebillCommercialURL) ?? ""
        hasDefaultAccount = try container.decodeIfPresent(Bool.self, forKey: .hasDefaultAccount) ?? false
        hasForgotPasswordLink = try container.decodeIfPresent(Bool.self, forKey: .hasForgotPasswordLink) ?? false
        paymentProgramAds = try container.decodeIfPresent(Bool.self, forKey: .paymentProgramAds) ?? false
        hasAssistanceEnrollment = try container.decodeIfPresent(Bool.self, forKey: .hasAssistanceEnrollment) ?? false
        agentisWidgets = try container.decodeIfPresent(Bool.self, forKey: .agentisWidgets) ?? false
        isAzureAuthentication = try container.decodeIfPresent(Bool.self, forKey: .isAzureAuthentication) ?? false
        isPkceAuthentication = try container.decodeIfPresent(Bool.self, forKey: .isPkceAuthentication) ?? false
        hasAuthenticatedISUM = try container.decodeIfPresent(Bool.self, forKey: .hasAuthenticatedISUM) ?? false
        hasUnauthenticatedISUM = try container.decodeIfPresent(Bool.self, forKey: .hasUnauthenticatedISUM) ?? false
        isGamificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .isGamificationEnabled) ?? false
        isAgentisElectricUsageWidget = try container.decodeIfPresent(Bool.self, forKey: .isAgentisElectricUsageWidget) ?? false
        isAgentisGasUsageWidget = try container.decodeIfPresent(Bool.self, forKey: .isAgentisGasUsageWidget) ?? false
        isAgentisElectricCompareBillsWidget = try container.decodeIfPresent(Bool.self, forKey: .isAgentisElectricCompareBillsWidget) ?? false
        isAgentisGasCompareBillsWidget = try container.decodeIfPresent(Bool.self, forKey: .isAgentisGasCompareBillsWidget) ?? false
        isAgentisElectricTipsWidget = try container.decodeIfPresent(Bool.self, forKey: .isAgentisElectricTipsWidget) ?? false
        isAgentisGasTipsWidget = try container.decodeIfPresent(Bool.self, forKey: .isAgentisGasTipsWidget) ?? false
        isAgentisProjectedWidget = try container.decodeIfPresent(Bool.self, forKey: .isAgentisProjectedWidget) ?? false
        isLowPaymentAllowed = try container.decodeIfPresent(Bool.self, forKey: .isLowPaymentAllowed) ?? false
        hasAssistanceFinder = try container.decodeIfPresent(Bool.self, forKey: .hasAssistanceFinder) ?? false
        isACEAMI = try container.decodeIfPresent(Bool.self, forKey: .isACEAMI) ?? false
    }
}
