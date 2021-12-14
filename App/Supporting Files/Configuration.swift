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
        var tenant: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            switch opco {
            case .ace:
                tenant = "euazurephi"
            case .delmarva:
                tenant = "euazurephi"
            case .pepco:
                tenant = "euazurephi"
            case .bge:
                tenant = "euazurebge"
            case .comEd:
                tenant = "euazurecomed"
            case .peco:
                tenant = "euazurepeco"
            }
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev, .test:
                switch opco {
                case .ace:
                    tenant = "euazurephitest"
                case .delmarva:
                    tenant = "euazurephitest"
                case .pepco:
                    tenant = "euazurephitest"
                case .bge:
                    tenant = "euazurebgetest"
                case .comEd:
                    tenant = "euazurecomedtest"
                case .peco:
                    tenant = "euazurepecotest"
                }
            case .stage:
                switch opco {
                case .ace:
                    tenant = "euazurephistage"
                case .delmarva:
                    tenant = "euazurephistage"
                case .pepco:
                    tenant = "euazurephistage"
                case .bge:
                    tenant = "euazurebgestage"
                case .comEd:
                    tenant = "euazurecomedstage"
                case .peco:
                    tenant = "euazurepecostage"
                }
            }
        }
        return tenant
    }
    
    var b2cPolicy: String {
        if FeatureFlagUtility.shared.bool(forKey: .isAzureAuthentication){
            return "B2C_1A_SIGNIN_MOBILE"
        }else{
            return "B2C_1A_Signin_ROPC"
        }
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
        //"\(b2cHost).exeloncorp.com"
        "\(b2cTenant).b2clogin.com"
    }
    
    var b2cOpowerAuthEndpoint: String {
        var endpoint: String
        
        switch opco {
        case .ace:
            endpoint = "\(b2cHost).ace.com"
        case .delmarva:
            endpoint = "\(b2cHost).delmarva.com"
        case .pepco:
            endpoint = "\(b2cHost).pep.com"
        case .bge:
            endpoint = "\(b2cHost).bge.com"
        case .comEd:
            endpoint = "\(b2cHost).comed.com"
        case .peco:
            endpoint = "\(b2cHost).peco.com"
        }
        
        return endpoint
    }
    
    var b2cClientID: String {
        var clientId: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            switch opco {
            case .ace:
                clientId = "4facf595-5fc3-44c1-a908-391e98ddc687"
            case .delmarva:
                clientId = "f900262f-eeb9-4ada-82a2-ade9e10e2c1b"
            case .pepco:
                clientId = "733a9d3b-9769-4ef3-8444-34128c5d0d63"
            case .bge:
                clientId = "202e1b60-9ba3-4e49-ab43-a1ebd438aa97"
            case .comEd:
                clientId = "b587ed2d-28a5-462c-8c1f-835f9d73f7c3"
            case .peco:
                clientId = "e555f5eb-b9ec-48b8-9452-fa0ed2ddeeda"
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
                case .bge:
                    clientId = "831eeb00-a9c5-4752-be90-13a0d506ef92"
                case .comEd:
                    clientId = "83028f96-b357-4920-a1d9-dd749627b6f4"
                case .peco:
                    clientId = "8d6822d5-a419-41d9-8b8f-4edada5e6901"
                }
            case .stage:
                switch opco {
                case .ace:
                    clientId = "4facf595-5fc3-44c1-a908-391e98ddc687"
                case .delmarva:
                    clientId = "f900262f-eeb9-4ada-82a2-ade9e10e2c1b"
                case .pepco:
                    clientId = "733a9d3b-9769-4ef3-8444-34128c5d0d63"
                case .bge:
                    clientId = "483c8402-2721-43f0-bbe6-ce7d223c4207"
                case .comEd:
                    clientId = "749d55e6-8b0f-4e15-9f26-f4401a96ec24"
                case .peco:
                    clientId = "908a6388-59f5-4074-84fa-5d61308f85df"
                }
            }
        }
        return clientId
    }
    
    var b2cRedirectURI: String {
        var redirecturi: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            switch opco {
            case .ace:
                redirecturi = "msauth.com.ifactorconsulting.ace"
            case .delmarva:
                redirecturi = "msauth.com.ifactorconsulting.delmarva"
            case .pepco:
                redirecturi = "msauth.com.exelon.mobile.pepco"
            case .bge:
                redirecturi = "msauth.com.exelon.mobile.bge"
            case .comEd:
                redirecturi = "msauth.com.iphoneproduction.exelon"
            case .peco:
                redirecturi = "msauth.com.exelon.mobile.pepco"
            }
        default:
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            switch projectTier {
            case .dev, .test:
                switch opco {
                case .ace:
                    redirecturi = "msauth.com.exelon.mobile.ace.testing"
                case .delmarva:
                    redirecturi = "msauth.com.exelon.mobile.delmarva.testing"
                case .pepco:
                    redirecturi = "msauth.com.exelon.mobile.pepco.testing"
                case .bge:
                    redirecturi = "msauth.com.exelon.mobile.bge.testing"
                case .comEd:
                    redirecturi = "msauth.com.exelon.mobile.comed.testing"
                case .peco:
                    redirecturi = "msauth.com.exelon.mobile.peco.testing"
                }
            case .stage:
                switch opco {
                case .ace:
                    redirecturi = "msauth.com.exelon.mobile.ace.staging"
                case .delmarva:
                    redirecturi = "msauth.com.exelon.mobile.delmarva.staging"
                case .pepco:
                    redirecturi = "msauth.com.exelon.mobile.pepco.staging"
                case .bge:
                    redirecturi = "msauth.com.exelon.mobile.bge.staging"
                case .comEd:
                    redirecturi = "msauth.com.exelon.mobile.comed.staging"
                case .peco:
                    redirecturi = "msauth.com.exelon.mobile.peco.staging"
                }
            }
        }
        return redirecturi
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
                oPowerURLString = "https://aztst1-secure.\(accountOpCo.urlDisplayString).com/pages/mobileopower.aspx"
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
