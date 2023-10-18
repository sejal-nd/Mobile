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
            case .ace, .delmarva, .pepco:
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
                case .ace, .delmarva, .pepco:
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
                case .ace, .delmarva, .pepco:
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
        let projectURLRawValue = UserDefaults.standard.string(forKey: "selectedProjectURL") ?? ""
        let projectURLSuffix = ProjectURLSuffix(rawValue: projectURLRawValue) ?? .none

        if FeatureFlagUtility.shared.bool(forKey: .isPkceAuthentication) {
            if Configuration.shared.environmentName == .release {
                return "B2C_1A_SignIn_Mobile"
            } else {
                switch projectURLSuffix {
                case .cis:
                    return "B2C_1A_SignIn_Mobile"
                default:
                    return "B2C_1A_Old_SignIn_Mobile"
                }
            }
        } else {
            if Configuration.shared.environmentName == .release {
                return "B2C_1A_SignIn_ROPC"
            } else {
                switch projectURLSuffix {
                case .cis:
                    return "B2C_1A_SignIn_ROPC"
                default:
                    return "B2C_1A_Old_SignIn_ROPC"
                }
            }
        }
    }
    
    var b2cHost: String {
        let host: String
        switch Configuration.shared.environmentName {
        case .rc, .release:
            switch (opco) {
            case .bge:
                host = "secure2"
            case .comEd, .peco:
                host = "secure1"
            default:
                host = "secure"
            }
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
        var endpoint: String
        
        if opco.isPHI {
            endpoint = "\(b2cHost).exeloncorp.com"
        } else {
            endpoint = "\(b2cHost).\(opco.urlDisplayString).com"
        }
        
        return endpoint
    }
    
    var b2cOpowerAuthEndpoint: String {
        return b2cAuthEndpoint
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
                    clientId = "67368fd4-d3d0-4f38-b443-94742e6af8c3"
                case .delmarva:
                    clientId = "548fe95f-b6c8-4791-b02b-b95ca3b3e31c"
                case .pepco:
                    clientId = "37abcf6f-b74d-4756-8ff7-05a6817575c5"
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
                redirecturi = "msauth.com.ifactorconsulting.pepco"
            case .bge:
                redirecturi = "msauth.com.exelon.mobile.bge"
            case .comEd:
                redirecturi = "msauth.com.iphoneproduction.exelon"
            case .peco:
                redirecturi = "msauth.com.exelon.mobile.peco"
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
                if let projectURLRawValue = UserDefaults.standard.string(forKey: "selectedProjectURL"), let projectURLSuffix = ProjectURLSuffix(rawValue: projectURLRawValue), projectURLSuffix == .agentis {
                    if accountOpCo == .pepco {
                        oPowerURLString = "https://s-c-\(projectURLSuffix.projectURLString)-\(accountOpCo.urlDisplayString)-ui-01.azurewebsites.net/pages/mobileopower.aspx"
                    } else {
                        oPowerURLString = "https://s-c-\(projectURLSuffix.projectURLString)-\(accountOpCo.urlString)-ui-01.azurewebsites.net/pages/mobileopower.aspx"
                    }
                } else {
                    oPowerURLString = "https://s-secure.\(accountOpCo.urlDisplayString).com/pages/mobileopower.aspx"
                }
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
                    baseUrl = "eudapi-dev.\(operatingCompany.urlDisplayString).com"
                    oAuthEndpoint = "api-development.exeloncorp.com"
                case .test:
                    baseUrl = "eudapi-test.\(operatingCompany.urlDisplayString).com"
                    oAuthEndpoint = "api-development.exeloncorp.com"
                case .stage:
                    baseUrl = "eudapi-stage.\(operatingCompany.urlDisplayString).com"
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
    
    var medalliaAPITocken: String {
        switch Configuration.shared.opco {
        case .ace:
            return NSLocalizedString("eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhcGlUb2tlblYyIiwiYXV0aFVybCI6Imh0dHBzOi8vZGlnaXRhbC1jbG91ZC1waHgxLmFwaXMubWVkYWxsaWEuY29tL21vYmlsZVNESy92MS9hY2Nlc3NUb2tlbiIsImVudmlyb25tZW50IjoiZGlnaXRhbC1jbG91ZC1waHgxIiwiY3JlYXRlVGltZSI6MTY2ODUzNjEyNDkzMSwiYXBpVG9rZW5WMlZlcnNpb24iOjIsInByb3BlcnR5SWQiOjE4NTI1fQ.Lgi64Tedn2QXrgtEHGerUz_99itpnXEjppvFE4tga9Yr0XdvIbdhcTTta-x45kXllQKawmsrXdWlZ0agZRovW9ZUkOUjOgya709IEmuHWjPqA2VaEIPQVPhWUKcE__gjMRCVIt8SNxuYR_bzRL9iXnVmAmEPOlsZydsz4DWnCY5T7GpWsS5H7YGQuLG0L6R5zKdbSq0M4OJK_eEA995XOLB_W5klYNB8HERPoo0Ofze2RJhzFTPd2ls_EKrsxefnHcwUrxxWx5HUxUhMpV47Lb8j6jiJ1VPvTPA9fjznhaOrIXr9icenyQhPy-cHHjRrQ7v72Laal1S7v331VLwu8A", comment: "")
        case .delmarva:
            return NSLocalizedString("eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhcGlUb2tlblYyIiwiYXV0aFVybCI6Imh0dHBzOi8vZGlnaXRhbC1jbG91ZC1waHgxLmFwaXMubWVkYWxsaWEuY29tL21vYmlsZVNESy92MS9hY2Nlc3NUb2tlbiIsImVudmlyb25tZW50IjoiZGlnaXRhbC1jbG91ZC1waHgxIiwiY3JlYXRlVGltZSI6MTY2ODUzNjEyODE4OCwiYXBpVG9rZW5WMlZlcnNpb24iOjIsInByb3BlcnR5SWQiOjE4NTUzfQ.VIW6V1SzHwqzigWonYqtH8yhx7ri8CyWDrvVVgEHyJd9_buIVXROpbGLAh6I3m2wffAqt--FRyAEYBueXmYB517uH2amKScAdsRB-8OdVIM5K-LtgZ-Tk7F5_2cYMRc4iJcJ_w3h4WZpRrxW7EEhZuaLMSn2pWI6Aaf_3fpn5ICdejG6cwEPpb7FYxXSC9lv_Rh8SKM3-VyuZ_2ZMUBdiOym4jUK6jhBCXDyPgR16f4Sz7ye-aHUzjzqUziLetWwmiyYZ3QvxJVVN9cti3gWtrEuYTpOuhQApsaQwgQneBzdaR2J9Tyk8tAV6Hi2EnPd_8wBSRndKysXeqbp_rTR_g", comment: "")
        case .pepco:
            return NSLocalizedString("eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhcGlUb2tlblYyIiwiYXV0aFVybCI6Imh0dHBzOi8vZGlnaXRhbC1jbG91ZC1waHgxLmFwaXMubWVkYWxsaWEuY29tL21vYmlsZVNESy92MS9hY2Nlc3NUb2tlbiIsImVudmlyb25tZW50IjoiZGlnaXRhbC1jbG91ZC1waHgxIiwiY3JlYXRlVGltZSI6MTY2ODUzNjEzMTM5NSwiYXBpVG9rZW5WMlZlcnNpb24iOjIsInByb3BlcnR5SWQiOjE4NTgxfQ.HAwInPv9tUtlTmkIhJaa2ix05BY1BGHpnVPU5t0Eo1WPt7hsTGftJR0e504ZltHzL0XiKmxoW0sl1bRE01xwobxvNC-E-NZmDRGDChGxJzfZ4G3pL7lecrZvtxR8Zx9CgoCbbb-fWLPZvxG8GlIIoS-rfFaMUa2UXk_hX1cWb6HydAjt_CER44kamQ-xqSOhsaVUYSqXJOgB-Pnf1CeXdGtQDT5SUQFJR4iykLbAcqDWLBVhpP-B5a-mQ5hSMhZdG5HA_8PjtgIpiT59plOsKVnUMx4PerRuzo3d9jqn9Wh-ByCJK8yl9MStBQGKOTSVhh4-eBofPKIHFpeHHDyYXg", comment: "")
        case .bge:
            return NSLocalizedString("eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhcGlUb2tlblYyIiwiYXV0aFVybCI6Imh0dHBzOi8vZGlnaXRhbC1jbG91ZC1waHgxLmFwaXMubWVkYWxsaWEuY29tL21vYmlsZVNESy92MS9hY2Nlc3NUb2tlbiIsImVudmlyb25tZW50IjoiZGlnaXRhbC1jbG91ZC1waHgxIiwiY3JlYXRlVGltZSI6MTY2ODUzNjEyNjU3OCwiYXBpVG9rZW5WMlZlcnNpb24iOjIsInByb3BlcnR5SWQiOjE4NTM5fQ.d6SAOk23ULf9BRMPHWtJ_CTpZgEvcFfnda48ZE7Pb8h6_KTHEIYXPqUg27m0QrfxiVXoeGFJYmzokLyHBJhZLgbXapzrvxJZ8XpD8lqGB9wILYx3tCuPlIqYjf86xKCQm5oNGOaK62i5Evmg2hq4Zsmp5ehvM-VNZ5qzese6NeuQEHkIOJoQQny7rwYqarGNqYvixLXzyxij7v68SvFajaOpB-0K6arJOwN_WToRPbdksUuTw7kdymFUQEYncpjrOoJE1Y3fffavCXSgaSircHrz0MBcGRgUHKC1vKOB_G529J37xJFel-Cleugp32MwJY1xIIeD7HN2U6_gCupvUg", comment: "")
        case .comEd:
            return NSLocalizedString("eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhcGlUb2tlblYyIiwiYXV0aFVybCI6Imh0dHBzOi8vZGlnaXRhbC1jbG91ZC1waHgxLmFwaXMubWVkYWxsaWEuY29tL21vYmlsZVNESy92MS9hY2Nlc3NUb2tlbiIsImVudmlyb25tZW50IjoiZGlnaXRhbC1jbG91ZC1waHgxIiwiY3JlYXRlVGltZSI6MTY2ODUzNjEyMjk5NCwiYXBpVG9rZW5WMlZlcnNpb24iOjIsInByb3BlcnR5SWQiOjE4NTExfQ.qZr6cPgFFsFv5naWaBlc6WEJ5kxxSU97uZfAJjVZTL0I3AhdQ0kov4x1BgsQDl0yzlM1hlpXI2BsWAuY6o3281q4mP98fWOkQtvpCCqrzpmqbpeCareN0NiXhNC7--pQ-GZqqEHvW7ail011XurzQRlnDQn0aioLj-ELQAZrSlWmwp1xNTESwCrB4Y5D1faSGroY9PUR668EWM07A3WwD2VCtPcL-_RWjZnhjkgFSe01lGHpJ2e9WqTBJ6mMph9X2MA5lcbnricILuQqdTmcpqszVXHe0Bo11Wb1zDISkt-T8RixsaNbIzf_hIQSAarlS3vYngWpMrEObKJ7Kv2I1w", comment: "")
        case .peco:
            return NSLocalizedString("eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhcGlUb2tlblYyIiwiYXV0aFVybCI6Imh0dHBzOi8vZGlnaXRhbC1jbG91ZC1waHgxLmFwaXMubWVkYWxsaWEuY29tL21vYmlsZVNESy92MS9hY2Nlc3NUb2tlbiIsImVudmlyb25tZW50IjoiZGlnaXRhbC1jbG91ZC1waHgxIiwiY3JlYXRlVGltZSI6MTY2ODUzNjEyOTY4MSwiYXBpVG9rZW5WMlZlcnNpb24iOjIsInByb3BlcnR5SWQiOjE4NTY3fQ.qwb1XvwjtvL6w8UYtuXF11fM6bzSx1awFYX3DsaXy6QbNr31yQnxGXROTRDaDzjtA2M8uN9m51Jk0aFd0eC2JbPoeTrbQzvtOQDknkePlboVq8Ovfqu_0O3Vsfcgnu_fZ2r09SsT3tNos9fFn2Tnl6uvClprdIzLUYz9xxbkv2bl668_g47A8bXKfdDrr1i_GQL6gLRGbVBgwX0ZEStehM34DpWubg1sCfyrjoGif0wYbdpi_hF8OZlJ0T9aXdIEg2w6BSDvXyhlwiV2Z-_IFbwgiRxrQCshDW7RYV2V-xZFhfGL26jrTpSDEgBh_X0-FwJU90wZ--Ilwa8KHw7T3A", comment: "")
        default:
            return ""
        }
    }
    
    var decibelTokens: [String: String] {
        switch Configuration.shared.opco {
        case .bge:
            return ["Account": "14081", "Property ID": "1238896"]
        case .comEd:
            return ["Account": "14081", "Property ID": "1249150"]
        case .peco:
            return ["Account": "14081", "Property ID": "1249170"]
        case .pepco:
            return ["Account": "14081", "Property ID": "1249180"]
        case .ace:
            return ["Account": "14081", "Property ID": "1244558"]
        case .delmarva:
            return ["Account": "14081", "Property ID": "1249160"]
        }
    }

}
