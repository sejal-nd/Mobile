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
    case comEd = "COMED"
    case peco = "PECO"
    case pepco = "PEPCO"
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
        case .comEd:
            return "ComEd"
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
    
    var urlString: String {
        switch self {
        case .delmarva:
            return "DPL"
        case .pepco:
            return "PEP"
        default:
            return rawValue.uppercased()
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
            return ""
        case .ace:
            return ""
        case .delmarva:
            return ""
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

struct InfoPlist: Codable {
    
    let displayName: String
    let baseURL: String
    let oauthURL: String
    let alertURL: String
    let accountURL: String
    let paymentURL: String
    let associatedDomain: String
    let googleAnalyticID: String
    let appCenterID: String
    let buildFlavor: String
    let environmentTier: String
    
    // Determined by git path in build phase run script "Set Project Prefix"
    var projectPrefix = ""
    
    enum CodingKeys: String, CodingKey {
        case displayName = "Build Display Name"
        case baseURL = "Base URL"
        case oauthURL = "OAuth URL"
        case alertURL = "Alert URL"
        case accountURL = "Account URL"
        case paymentURL = "Payment URL"
        case associatedDomain = "Associated Domain"
        case googleAnalyticID = "Google Analytics ID"
        case appCenterID = "App Center ID"
        case buildFlavor = "Build Flavor"
        case environmentTier = "Environment Tier"
        case projectPrefix = "Project Environment Prefix"
    }
}

struct Environment {
    static let shared = Environment()
    
    let environmentName: EnvironmentName
    let opco: OpCo
    let myAccountUrl: String
    let gaTrackingId: String
    let associatedDomain: String
    let appCenterId: String?
    let baseUrl: String
    let oAuthEndpoint: String
    let paymentusUrl: String
    let sharepointBaseURL: String
    let projectPrefix: String
    
    var clientSecret: String {
        var id = ""
        switch Environment.shared.environmentName {
        case .aut, .test, .dev:
            id = "WbCpJpfgV64WTTDg"
        case .stage, .hotfix:
            id = "61MnQzuXNLdlsBOu"
        case .prodbeta, .prod:
            id = "wQrbiqG3Ddefftp3"
        }
        return id
    }
    
    var clientID: String {
        var secret = ""
        switch Environment.shared.environmentName {
        case .aut, .test, .dev:
            secret = "zWkH8cTa1KphCB4iElbYSBGkL6Fl66KL"
        case .stage, .hotfix:
            secret = "GG1B2b3oi9Lxv1GsGQi0AhdflCPgpf5R"
        case .prodbeta, .prod:
            secret = "jk8UMnMb2kSISwAgX0OFGhMEAfMEoGTd"
        }
        return secret
    }
    
    private init() {
        let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist")
        let plistURL = URL(fileURLWithPath: plistPath!)
        let decoder = PropertyListDecoder()
        
        do {
            let data = try Data(contentsOf: plistURL)
            let infoPlist = try decoder.decode(InfoPlist.self, from: data)
            
            environmentName = EnvironmentName(rawValue: infoPlist.environmentTier)!
            opco = OpCo(rawValue: infoPlist.buildFlavor)!
            baseUrl = infoPlist.baseURL
            oAuthEndpoint = infoPlist.oauthURL
            paymentusUrl = infoPlist.paymentURL
            sharepointBaseURL = infoPlist.alertURL
            myAccountUrl = infoPlist.accountURL
            gaTrackingId = infoPlist.googleAnalyticID
            associatedDomain = infoPlist.associatedDomain
            appCenterId = infoPlist.appCenterID
            projectPrefix = infoPlist.projectPrefix
        } catch {
            fatalError("Could not get data from plist: \(error)")
        }
    }
}

