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
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iOS = try container.decodeIfPresent(FeatureFlags.self, forKey: .iOS) ?? FeatureFlags()
    }
}

public struct FeatureFlags: Decodable {
    public var outageMapUrl: String = ""
    public var streetlightMapUrl: String = ""
    public var billingVideoUrl: String = ""
    public var hasDefaultAccount: Bool = false
    public var hasForgotPasswordLink: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case outageMapUrl = "outageMapURL"
        case streetlightMapUrl = "streetlightMapURL"
        case billingVideoUrl = "billingVideoURL"
        case hasDefaultAccount
        case hasForgotPasswordLink
    }
    
    public init() {
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        outageMapUrl = try container.decodeIfPresent(String.self, forKey: .outageMapUrl) ?? ""
        streetlightMapUrl = try container.decodeIfPresent(String.self, forKey: .streetlightMapUrl) ?? ""
        billingVideoUrl = try container.decodeIfPresent(String.self, forKey: .billingVideoUrl) ?? ""
        hasDefaultAccount = try container.decodeIfPresent(Bool.self, forKey: .hasDefaultAccount) ?? false
        hasForgotPasswordLink = try container.decodeIfPresent(Bool.self, forKey: .hasForgotPasswordLink) ?? false
    }
}
