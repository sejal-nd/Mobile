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
    case pepco = "PEP"
    case ace = "ACE"
    case delmarva = "DPL"
    
    var isPHI: Bool {
        switch self {
        case .bge, .comEd, .peco:
            return false
        case .pepco, .ace, .delmarva:
            return true
        }
    }
    
    var displayString: String {
        switch self {
        case .ace:
            return "Atlantic City Electric"
        case .delmarva:
            return "Delmarva Power"
        case .pepco:
            return "Pepco"
        default:
            return rawValue
        }
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
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
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
        case .pepco:
            return URL(string: "todo")
        case .ace:
            return URL(string: "todo")
        case .delmarva:
            return URL(string: "todo")
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
    let oAuthEndpoint: String // The Layer 7 token endpoint
    let paymentusUrl: String
    let sharepointBaseURL: String
    var projectEnvironmentPath = ""
    
    var clientSecret: String {
        var id = ""
        switch Environment.shared.environmentName {
        case .aut, .test, .dev:
            id = "61MnQzuXNLdlsBOu"//"WbCpJpfgV64WTTDg" - commented out due to CIS takeover of stage
        case .stage, .hotfix:
            id = "61MnQzuXNLdlsBOu"
        case .prodbeta, .prod:
            id = ""
        }
        return id
    }
    
    var clientID: String {
        var secret = ""
        switch Environment.shared.environmentName {
        case .aut, .test, .dev:
            secret = "GG1B2b3oi9Lxv1GsGQi0AhdflCPgpf5R"//"zWkH8cTa1KphCB4iElbYSBGkL6Fl66KL" - commented out due to CIS takeover of stage
        case .stage, .hotfix:
            secret = "GG1B2b3oi9Lxv1GsGQi0AhdflCPgpf5R"
        case .prodbeta, .prod:
            secret = ""
        }
        return secret
    }
    
    
    init(mcsInstanceName: String, opco: OpCo) {
        let configPath = Bundle.main.path(forResource: "MCSConfig", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: configPath)
        let mobileBackends = dict?["mobileBackends"] as! [String: Any]
        let mobileBackend = mobileBackends[mcsInstanceName] as! [String: Any]
        
        baseUrl = mobileBackend["baseURL"] as! String
        oAuthEndpoint = mobileBackend["oauthEndpoint"] as! String
        sharepointBaseURL = mobileBackend["sharepointBaseURL"] as! String
        projectEnvironmentPath = mobileBackend["projectEnvironmentPath"] as? String ?? ""
        
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
        case .pepco:
            opcoStr = "todo"
            opcoNum = "todo"
        case .ace:
            opcoStr = "todo"
            opcoNum = "todo"
        case .delmarva:
            opcoStr = "todo"
            opcoNum = "todo"
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

