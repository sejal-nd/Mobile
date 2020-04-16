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
    case prodbeta = "PRODBETA"
    case prod = "PROD"
    case hotfix = "HOTFIX"
}

struct MCSConfig {
    let baseUrl: String
    let anonymousKey: String
    let oAuthEndpoint: String // The Layer 7 token endpoint
    let apiVersion: String
    let paymentusUrl: String
    
    init(mcsInstanceName: String, opco: OpCo) {
        let configPath = Bundle.main.path(forResource: "MCSConfig", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: configPath)
        let mobileBackends = dict?["mobileBackends"] as! [String: Any]
        let mobileBackend = mobileBackends[mcsInstanceName] as! [String: Any]
        
        baseUrl = mobileBackend["baseURL"] as! String
        anonymousKey = mobileBackend["anonymousKey"] as! String
        oAuthEndpoint = mobileBackend["oauthEndpoint"] as! String
        apiVersion = mobileBackend["apiVersion"] as! String
        
        let opcoStr: String
        let opcoNum: String
        switch opco {
        case .bge:
            opcoStr = "bge"
            opcoNum = "620"
        case .comEd:
            opcoStr = "comd"
            opcoNum = "623"
        case .peco:
            opcoStr = "peco"
            opcoNum = "622"
        }
        let paymentusUrlFormat = mobileBackend["paymentusUrl"] as! String
        paymentusUrl = paymentusUrlFormat.replacingOccurrences(of: "%@", with: opcoStr)
            .replacingOccurrences(of: "%d", with: opcoNum)
    }
}

struct Environment {
    
    static let shared = Environment()
    
    let environmentName: EnvironmentName
    let appName: String
    let opco: OpCo
    let mcsInstanceName: String
    let mcsConfig: MCSConfig
    let myAccountUrl: String
    let gaTrackingId: String
    let firebaseConfigFile: String
    let opcoUpdatesHost: String
    let associatedDomain: String
    let appCenterId: String?
    
    private init() {
        let path = Bundle.main.path(forResource: "environment", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: path)!
    
        environmentName = EnvironmentName(rawValue: dict["environment"] as! String)!
        appName = dict["appName"] as! String
        opco = OpCo(rawValue: dict["opco"] as! String)!
        mcsInstanceName = dict["mcsInstanceName"] as! String
        mcsConfig = MCSConfig(mcsInstanceName: mcsInstanceName, opco: opco)
        myAccountUrl = dict["myAccountUrl"] as! String
        gaTrackingId = dict["gaTrackingId"] as! String
        firebaseConfigFile = dict["firebaseConfigFile"] as! String
        opcoUpdatesHost = dict["opcoUpdatesHost"] as! String
        associatedDomain = dict["associatedDomain"] as! String
        appCenterId = dict["appCenterId"] as? String
    }
}

