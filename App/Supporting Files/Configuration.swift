//
//  Configuration.swift
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

    var urlDisplayString: String {
        switch self {
        case .ace:
            return "atlanticcityelectric"
        case .bge:
            return "bge"
        case .comEd:
            return "comed"
        case .delmarva:
            return "delmarva"
        case .peco:
            return "peco"
        case .pepco:
            return "pepco"
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
            return URL(string: "https://apps.apple.com/us/app/pepco-self-service/id447665998")
        case .ace:
            return URL(string: "https://apps.apple.com/us/app/atlantic-city-electric-self/id489963640")
        case .delmarva:
            return URL(string: "https://apps.apple.com/us/app/delmarva-power-self-service/id489964338")
        }
    }
}

enum ConfigurationName: String {
    case aut = "AUT"
    case beta = "BETA"
    case rc = "RC"
    case release = "RELEASE"
}

struct InfoPlist: Codable {
    
    let displayName: String
    let baseURL: String
    let oauthURL: String
    let b2cTenant: String
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
        case b2cTenant = "B2CAuth Tenant"
        case accountURL = "Account URL"
        case paymentURL = "Payment URL"
        case associatedDomain = "Associated Domain"
        case googleAnalyticID = "Google Analytics ID"
        case appCenterID = "App Center ID"
        case buildFlavor = "Build Flavor"
        case environmentTier = "Environment Tier"
    }
}

struct Configuration {
    static let shared = Configuration()
    
    let environmentName: ConfigurationName
    let opco: OpCo
    let myAccountUrl: String
    let gaTrackingId: String
    let associatedDomain: String
    let appCenterId: String?
    let baseUrl: String
    let oAuthEndpoint: String
    let b2cAuthEndpoint: String
    let b2cTenant: String
    let paymentusUrl: String
    
    var client_id: String {
        var client_id = ""
        switch Configuration.shared.environmentName {
        case .rc, .release:
            client_id = "80720fb5-623b-4754-9c2c-6ba2646acaa6"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev:
                client_id = "80720fb5-623b-4754-9c2c-6ba2646acaa6"
            case .test:
                client_id = "80720fb5-623b-4754-9c2c-6ba2646acaa6"
            case .stage:
                client_id = "80720fb5-623b-4754-9c2c-6ba2646acaa6"
            }
        }
        return client_id
    }
    
    var scope: String {
        var scope = ""
        switch Configuration.shared.environmentName {
        case .rc, .release:
            scope = "openid offline_access 80720fb5-623b-4754-9c2c-6ba2646acaa6"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev:
                scope = "openid offline_access 80720fb5-623b-4754-9c2c-6ba2646acaa6"
            case .test:
                scope = "openid offline_access 80720fb5-623b-4754-9c2c-6ba2646acaa6"
            case .stage:
                scope = "openid offline_access 80720fb5-623b-4754-9c2c-6ba2646acaa6"
            }
        }
        return scope
    }
    
    var clientSecret: String {
        var secret = ""
        switch Configuration.shared.environmentName {
        case .rc, .release:
            secret = "wQrbiqG3Ddefftp3"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev:
                // N/A
                secret = "WbCpJpfgV64WTTDg"
            case .test:
                secret = "WbCpJpfgV64WTTDg"
            case .stage:
                secret = "61MnQzuXNLdlsBOu"
            }
        }
        return secret
    }
    
    var clientID: String {
        var id = ""
        switch Configuration.shared.environmentName {
        case .rc, .release:
            id = "jk8UMnMb2kSISwAgX0OFGhMEAfMEoGTd"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev:
                // N/A
                id = "zWkH8cTa1KphCB4iElbYSBGkL6Fl66KL"
            case .test:
                id = "zWkH8cTa1KphCB4iElbYSBGkL6Fl66KL"
            case .stage:
                id = "GG1B2b3oi9Lxv1GsGQi0AhdflCPgpf5R"
            }
        }
        return id
    }
    
    private init() {
        let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist")
        let plistURL = URL(fileURLWithPath: plistPath!)
        let decoder = PropertyListDecoder()
        
        do {
            let data = try Data(contentsOf: plistURL)
            let infoPlist = try decoder.decode(InfoPlist.self, from: data)
            
            let envName = ConfigurationName(rawValue: infoPlist.environmentTier)!
            environmentName = envName
            
            let operatingCompany = OpCo(rawValue: infoPlist.buildFlavor)!
            opco = operatingCompany
            paymentusUrl = infoPlist.paymentURL
            myAccountUrl = infoPlist.accountURL
            gaTrackingId = infoPlist.googleAnalyticID
            associatedDomain = infoPlist.associatedDomain
            appCenterId = infoPlist.appCenterID
            
            if envName == .beta {
                let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
                let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
                switch projectTier {
                case .dev:
                    baseUrl = "xzc-e-n-eudapi-\(operatingCompany.rawValue.lowercased())-d-ams-01.azure-api.net"
                    // Unsure what oAuth would be here...
                    oAuthEndpoint = "api-development.exeloncorp.com"
                    b2cAuthEndpoint = "\(infoPlist.b2cTenant).b2clogin.com"
                    b2cTenant = infoPlist.b2cTenant
                case .test:
                    baseUrl = "xze-e-n-eudapi-\(operatingCompany.rawValue.lowercased())-t-ams-01.azure-api.net"
                    oAuthEndpoint = "api-development.exeloncorp.com"
                    b2cAuthEndpoint = "\(infoPlist.b2cTenant).b2clogin.com"
                    b2cTenant = infoPlist.b2cTenant
                case .stage:
                    baseUrl = "mcsstg.mobileenv.\(operatingCompany.urlDisplayString).com"
                    oAuthEndpoint = "api-stage.exeloncorp.com"
                    b2cAuthEndpoint = "\(infoPlist.b2cTenant).b2clogin.com"
                    b2cTenant = infoPlist.b2cTenant
                }
            } else {
                baseUrl = infoPlist.baseURL
                oAuthEndpoint = infoPlist.oauthURL
                b2cAuthEndpoint = "\(infoPlist.b2cTenant).b2clogin.com"
                b2cTenant = infoPlist.b2cTenant
            }
        } catch {
            fatalError("Could not get data from plist: \(error)")
        }
    }
}
