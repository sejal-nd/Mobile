//
//  Router.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

// extract this into an enum of auth, anon, other (manual)
public typealias HTTPHeaders = [String: String]
public typealias HTTPBody = Data?


public enum Router {
    
    case minVersion
    case maintenanceMode
        
    case fetchSAMLToken(httpBody: HTTPBody)
    case exchangeSAMLToken(token: String)
    
    case accounts
    case accountDetails(accountNumber: String, queryString: String)
    
    case wallet
    
    case payments(accountNumber: String)
    
    case weather(lat: String, long: String)
    
    case alertBanner(additionalQueryItem: URLQueryItem)
    
    case anonOutageStatus(httpBody: HTTPBody)

    
//    case getSources
//    case getProductIds
//    case getProductInfo
    
    public var scheme: String {
        return "https"
    }
    
    public var host: String {
        switch self {
        case .anonOutageStatus, .maintenanceMode, .accountDetails, .accounts, .exchangeSAMLToken, .minVersion, .wallet, .payments:
            return "exeloneumobileapptest-a453576.mobileenv.us2.oraclecloud.com"
        //return Environment.shared.mcsConfig.baseUrl
        case .fetchSAMLToken:
            return "dev-apigateway.exeloncorp.com"//"stage-apigateway.exeloncorp.com" // TEMP
        case .weather:
            return "api.weather.gov"
        case .alertBanner:
            return "azstg.bge.com"
        }
    }
    
    public enum ApiAccess: String {
        case admin
        case anon
        case auth
        case external
    }
    
    public var apiAccess: ApiAccess {
        switch self {
            
        // Admin
//        case .getSources:
//            return .admin
//        case .getProductIds:
//            return .admin
//        case .getProductInfo:
//            return .admin
            
        // Anon
        case .weather:
            return .external
        case .minVersion:
            return .anon
        case .maintenanceMode:
            return .anon
        case .anonOutageStatus:
            return .anon
        default:
            return .auth
        }
    }
    
    public var apiVersion: String {
        return Environment.shared.mcsConfig.apiVersion
    }
    
    public var path: String {
        switch self {
        case .anonOutageStatus:
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/\(Environment.shared.opco.displayString)/outage/query"
        case .maintenanceMode:
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/\(Environment.shared.opco.displayString)/config/maintenance"
        case .accountDetails(let accountNumber, let queryString):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)\(queryString)"
        case .accounts:
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts"
        case .minVersion:
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/\(Environment.shared.opco.displayString)/config/versions"
        case .fetchSAMLToken:
            return "/mcs/oauth2/tokens"
        case .exchangeSAMLToken:
            return "/mobile/platform/sso/exchange-token"
        case .weather(let lat, let long):
            return "/points/\(lat),\(long)/forecast/hourly"
        case .wallet:
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/wallet/query"
        case .payments(let accountNumber):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/payments"
        case .alertBanner:
            return "/_api/web/lists/GetByTitle('GlobalAlert')/items"
//        case .getSources:
//            return "/\(apiAccess)/custom_collections.json"
//        case .getProductIds:
//            return "/\(apiAccess)/collects.json"
//        case .getProductInfo:
//            return "/\(apiAccess)/products.json"
        }
    }
    
    public var method: String {
        switch self {
        case .anonOutageStatus, .fetchSAMLToken, .wallet:
            return "POST"
        case .maintenanceMode, .accountDetails, .accounts, .exchangeSAMLToken, .minVersion, .weather, .payments, .alertBanner:
            return "GET"
        }
    }
    
    public var token: String {
        return UserSession.shared.token
    }
    
    // PLACE HOLDER, currently NOT BEING USED
    public var parameters: [URLQueryItem] {
        switch self {
        case .alertBanner(let additionalQueryItem):
            return [URLQueryItem(name: "$select", value: "Title,Message,Enable,CustomerType,Created,Modified"),
                    URLQueryItem(name: "$orderby", value: "Modified desc"),
                    additionalQueryItem]
        default:
            return []
        }
        //        let accessToken = "c32313df0d0ef512ca64d5b336a0d7c6"
        //        switch self {
        //        case .getSources:
        //            return [URLQueryItem(name: "page", value: "1"),
        //                URLQueryItem(name: "access_token", value: accessToken)]
        //        case .getProductIds:
        //            return [URLQueryItem(name: "page", value: "1"),
        //                URLQueryItem(name: "collection_id", value: "68424466488"),
        //                URLQueryItem(name: "access_token", value: accessToken)]
        //        case .getProductInfo:
        //            return [URLQueryItem(name: "ids", value: "2759162243,2759143811"),
        //                URLQueryItem(name: "page", value: "1"),
        //                URLQueryItem(name: "access_token", value: accessToken)]
        //        default:
        //            return []
        //        }
    }
    
    // todo: this may change to switch off of api access... I believe all vlaues below are derived from auth, anon, admin.  Hold off on changing this for now tho... need to dig deeper.
    public var httpHeaders: HTTPHeaders? {
        switch self {
        case .anonOutageStatus(_):
            return ["Authorization": "Basic \(Environment.shared.mcsConfig.anonymousKey)",
                "oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                "Content-Type": "application/json"
            ]
        case .accounts, .accountDetails, .wallet, .payments:
            return ["oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                    "Authorization": "Bearer \(token)"]
        case .minVersion, .maintenanceMode:
            return ["Authorization": "Basic \(Environment.shared.mcsConfig.anonymousKey)",
                "oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId
            ]
        case .fetchSAMLToken:
            return ["content-type": "application/x-www-form-urlencoded"]
        case .exchangeSAMLToken(let samlToken):
            return ["encode": "xml",
                    "oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                    "Authorization": "Bearer \(samlToken)"]
        case .alertBanner:
            return ["Accept": "application/json;odata=verbose"]
        default:
            return nil
        }
    }
    
    public var httpBody: HTTPBody? {
        switch self {
        case .fetchSAMLToken(let httpBody), .anonOutageStatus(let httpBody):
            return httpBody
        default:
            return nil
        }
    }
    
    public var mockFileName: String {
        switch self {
        case .minVersion:
            return "minVersionMock"
        case .maintenanceMode:
            return "maintenanceModeMock"
        case .fetchSAMLToken:
            return "SAMLTokenMock"
        case .exchangeSAMLToken:
            return "JWTTokenMock"
        case .accounts:
            return "AccountsMock"
        case .weather:
            return "WeatherMock"
        case .wallet:
            return "WalletMock"
        case .payments:
            return "PaymentsMock"
        case .alertBanner:
            return "AlertBannerMock"
        default:
            return ""
        }
    }
    
}
