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
        switch self {
        case .bge:
            return "That's smart energy"
        case .comEd:
            return "Powering lives"
        case .peco:
            return "The future is on"
        }
    }
    
    var appStoreLink: URL? {
        switch self {
        case .bge:
            return URL(string: "https://itunes.apple.com/us/app/bge-an-exelon-company/id1274170174?ls=1&mt=8")
        case .comEd:
            return URL(string: "https://itunes.apple.com/us/app/comed-an-exelon-company/id519716176?mt=8")
        case .peco:
            return URL(string: "https://itunes.apple.com/us/app/peco-an-exelon-company/id1274171957?ls=1&mt=8")
        }
    }
}

enum EnvironmentName: String {
    case aut = "AUT"
    case dev = "DEV"
    case test = "TEST"
    case stage = "STAGE"
    case prod = "PROD"
}

struct MCSConfig {
    let baseUrl: String
    let mobileBackendId: String
    let anonymousKey: String
    let oAuthEndpoint: String // The Layer 7 token endpoint
    
    init(mcsInstanceName: String) {
        let configPath = Bundle.main.path(forResource: "MCSConfig", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: configPath)
        let mobileBackends = dict?["mobileBackends"] as! [String: Any]
        let mobileBackend = mobileBackends[mcsInstanceName] as! [String: Any]
        
        baseUrl = mobileBackend["baseURL"] as! String
        mobileBackendId = mobileBackend["mobileBackendID"] as! String
        anonymousKey = mobileBackend["anonymousKey"] as! String
        oAuthEndpoint = mobileBackend["oauthEndpoint"] as! String
    }
}

struct Environment {
    
    static let shared = Environment()
    
    let environmentName: EnvironmentName
    let appName: String
    let opco: OpCo
    let mcsInstanceName: String
    let mcsConfig: MCSConfig
    let outageMapUrl: String
    let paymentusUrl: String
    let gaTrackingId: String
    let watchGaTrackingId: String
    let firebaseConfigFile: String
    let opcoUpdatesHost: String
    let associatedDomain: String
    let appCenterId: String?
    
    private init() {
        let path = Bundle.main.path(forResource: "environment", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: path)
    
        environmentName = EnvironmentName(rawValue: dict?["environment"] as! String)!
        appName = dict?["appName"] as! String
        opco = OpCo(rawValue: dict?["opco"] as! String)!
        mcsInstanceName = dict?["mcsInstanceName"] as! String
        mcsConfig = MCSConfig(mcsInstanceName: mcsInstanceName)
        outageMapUrl = dict?["outageMapUrl"] as! String
        paymentusUrl = dict?["paymentusUrl"] as! String
        gaTrackingId = dict?["gaTrackingId"] as! String
        watchGaTrackingId = dict?["watchGaTrackingId"] as! String
        firebaseConfigFile = dict?["firebaseConfigFile"] as! String
        opcoUpdatesHost = dict?["opcoUpdatesHost"] as! String
        associatedDomain = dict?["associatedDomain"] as! String
        appCenterId = dict?["appCenterId"] as? String
    }
}

