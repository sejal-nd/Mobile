//
//  Environment.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

enum OpCo: String {
    case bge = "BGE"
    case comEd = "ComEd"
    case peco = "PECO"
    
    var displayString: String {
        return rawValue
    }
    
    // Used for reading the splash screen animation to VoiceOver users
    var taglineString: String {
        var tagline: String
        switch self {
        case .bge:
            tagline = "That's smart energy"
        case .comEd:
            tagline = "Powering lives"
        case .peco:
            tagline = "The future is on"
        }
        return tagline
    }
}

enum EnvironmentName: String {
    case aut = "AUT"
    case dev = "DEV"
    case stage = "STAGE"
    case prod = "PROD"
}

/// Convenience singleton that wraps environment variables.
struct Environment  {
    
    static let shared = Environment()
    
    let environmentName: EnvironmentName
    let appName: String
    let opco: OpCo
    let oAuthEndpoint: String
    let mcsInstanceName: String
    let fiservUrl: String
    let speedpayUrl: String
    let outageMapUrl: String
    let gaTrackingId: String
    let firebaseConfigFile: String
    let opcoUpdatesHost: String
    let appCenterId: String?
    
    private init() {
        let path = Bundle.main.path(forResource: "environment", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
    
        environmentName = EnvironmentName(rawValue: dict?["environment"] as! String)!
        appName = dict?["appName"] as! String
        opco = OpCo(rawValue: dict?["opco"] as! String)!
        oAuthEndpoint = dict?["oauthEndpoint"] as! String
        mcsInstanceName = dict?["mcsInstanceName"] as! String
        fiservUrl = dict?["fiservUrl"] as! String
        speedpayUrl = dict?["speedpayUrl"] as! String
        outageMapUrl = dict?["outageMapUrl"] as! String
        gaTrackingId = dict?["gaTrackingId"] as! String
        firebaseConfigFile = dict?["firebaseConfigFile"] as! String
        opcoUpdatesHost = dict?["opcoUpdatesHost"] as! String
        appCenterId = dict?["appCenterId"] as? String
    }
}
