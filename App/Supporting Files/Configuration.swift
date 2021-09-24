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
    let paymentusUrl: String
    
    var clientSecret: String {
        var secret = ""
        switch Configuration.shared.environmentName {
        case .rc, .release:
            secret = "wQrbiqG3Ddefftp3"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev, .test:
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
            case .dev, .test:
                id = "zWkH8cTa1KphCB4iElbYSBGkL6Fl66KL"
            case .stage:
                id = "GG1B2b3oi9Lxv1GsGQi0AhdflCPgpf5R"
            }
        }
        return id
    }
    
    var b2cTenant: String {
        let tenant: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            tenant = "euazurephi"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev, .test:
                tenant = "euazurephitest"
            case .stage:
                tenant = "euazurephistage"
            }
        }
        return tenant
    }
    
    var b2cHost: String {
        let host: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            host = "secure"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev, .test:
                host = "test-secure"
            case .stage:
                host = "stage-secure"
            }
        }
        return host
    }
    
    var b2cAuthEndpoint: String {
        "\(b2cHost).exeloncorp.com"
    }
    
    var b2cClientID: String {
        var clientId: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            switch opco {
            case .ace:
                clientId = "64930d53-e888-45f9-9b02-aeed39ba48ca"
            case .delmarva:
                clientId = "571ee0e4-c2cc-4d39-b784-6395571cb077"
            case .pepco:
                clientId = "bb13a5b0-c61c-4194-960b-c44cebe992c2"
            case .bge, .comEd, .peco:
                clientId = "" //TODO("Waiting for other environments to be set up")
            }
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev, .test:
                switch opco {
                case .ace:
                    clientId = "4facf595-5fc3-44c1-a908-391e98ddc687"
                case .delmarva:
                    clientId = "f900262f-eeb9-4ada-82a2-ade9e10e2c1b"
                case .pepco:
                    clientId = "733a9d3b-9769-4ef3-8444-34128c5d0d63"
                case .bge, .comEd, .peco:
                    clientId = "" //TODO("Waiting for other environments to be set up")
                }
            case .stage:
                switch opco {
                case .ace:
                    clientId = "67368fd4-d3d0-4f38-b443-94742e6af8c3"
                case .delmarva:
                    clientId = "548fe95f-b6c8-4791-b02b-b95ca3b3e31c"
                case .pepco:
                    clientId = "37abcf6f-b74d-4756-8ff7-05a6817575c5"
                case .bge, .comEd, .peco:
                    clientId = "" //TODO("Waiting for other environments to be set up")
                }
            }
        }
        return clientId
    }
    
    var b2cScope: String {
        "openid offline_access \(b2cClientID)"
    }
    
    // accountOpCo: account opco (in the case that the account opco is different than the app opco)
    func getSecureOpCoOpowerURLString(_ accountOpCo: OpCo) -> String {
        var oPowerURLString: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            oPowerURLString = "https://secure.\(accountOpCo.urlDisplayString).com/pages/mobileopower.aspx"
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev:
                let projectURLRawValue = UserDefaults.standard.string(forKey: "selectedProjectURL") ?? ""
                let projectURLSuffix = ProjectURLSuffix(rawValue: projectURLRawValue) ?? .none
                switch accountOpCo {
                case .pepco:
                    oPowerURLString = "https://d-c-\(projectURLSuffix.projectURLString)-pepco-ui-01.azurewebsites.net/pages/mobileopower.aspx"
                default:
                    oPowerURLString = "https://d-c-\(projectURLSuffix.projectURLString)-\(accountOpCo.urlString)-ui-01.azurewebsites.net/pages/mobileopower.aspx"
                }
            case .test:
                oPowerURLString = "https://azst1-secure.\(accountOpCo.urlDisplayString).com/pages/mobileopower.aspx"
            case .stage:
                oPowerURLString = "https://azstg-secure.\(accountOpCo.urlDisplayString).com/pages/mobileopower.aspx"
            }
        }
        return oPowerURLString
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
                case .test:
                    baseUrl = "xze-e-n-eudapi-\(operatingCompany.rawValue.lowercased())-t-ams-01.azure-api.net"
                    oAuthEndpoint = "api-development.exeloncorp.com"
                case .stage:
                    baseUrl = "mcsstg.mobileenv.\(operatingCompany.urlDisplayString).com"
                    oAuthEndpoint = "api-stage.exeloncorp.com"
                }
            } else {
                baseUrl = infoPlist.baseURL
                oAuthEndpoint = infoPlist.oauthURL
            }
        } catch {
            fatalError("Could not get data from plist: \(error)")
        }
    }
}
