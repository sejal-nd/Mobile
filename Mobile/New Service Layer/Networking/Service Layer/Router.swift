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
    
    case fetchAnonOutageStatus(httpBody: HTTPBody)
    
    case fetchToken(httpBody: HTTPBody)
    case exchangeToken(token: String)
    
    case fetchAccounts(token: String)
    case fetchAccountDetails(accountNumber: String, queryString: String, token: String)

    case fetchMaintenanceMode
    
    case getSources
    case getProductIds
    case getProductInfo

    public var scheme: String {
        return "https"
    }

    public var host: String {
        switch self {
        case .fetchAnonOutageStatus, .fetchMaintenanceMode, .fetchAccountDetails, .fetchAccounts, .exchangeToken, .minVersion, .getSources, .getProductIds, .getProductInfo:
        return "exeloneumobileapptest-a453576.mobileenv.us2.oraclecloud.com"
        //return Environment.shared.mcsConfig.baseUrl
        case .fetchToken:
            return "stage-apigateway.exeloncorp.com" // TEMP
        }
    }
    
    public var path: String {
        switch self {
        case .fetchAnonOutageStatus:
            return "/mobile/custom/anon_v6/\(Environment.shared.opco.displayString)/outage/query" // todo dynamic v number + opco
        case .fetchMaintenanceMode:
            return "/mobile/custom/anon_v6/\(Environment.shared.opco.displayString)/config/maintenance"
        case .fetchAccountDetails(let accountNumber, let queryString, _):
            return "/mobile/custom/auth_v6/accounts/\(accountNumber)\(queryString)"
        case .fetchAccounts:
            return "/mobile/custom/auth_v6/accounts" // todo dynamic v number + opco
        case .minVersion:
            return "/mobile/custom/anon_v6/\(Environment.shared.opco.displayString)/config/versions" // todo dynamic v number + opco
        case .fetchToken:
            return "/mcs/oauth2/tokens"
        case .exchangeToken:
            return "/mobile/platform/sso/exchange-token"
        case .getSources:
            return "/admin/custom_collections.json"
        case .getProductIds:
            return "/admin/collects.json"
        case .getProductInfo:
            return "/admin/products.json"
        }
    }
    
    public var method: String {
        switch self {
        case .fetchAnonOutageStatus, .fetchToken:
            return "POST"
        case .fetchMaintenanceMode, .fetchAccountDetails, .fetchAccounts, .exchangeToken, .minVersion, .getSources, .getProductIds, .getProductInfo:
            return "GET"
        }
    }

    // PLACE HOLDER, currently NOT BEING USED
    public var parameters: [URLQueryItem] {
        let accessToken = "c32313df0d0ef512ca64d5b336a0d7c6"
        switch self {
        case .getSources:
            return [URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "access_token", value: accessToken)]
        case .getProductIds:
            return [URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "collection_id", value: "68424466488"),
                URLQueryItem(name: "access_token", value: accessToken)]
        case .getProductInfo:
            return [URLQueryItem(name: "ids", value: "2759162243,2759143811"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "access_token", value: accessToken)]
        default:
            return []
        }
    }
    
    public var httpHeaders: HTTPHeaders? {
        switch self {
        case .fetchAnonOutageStatus(_):
            return ["Authorization": "Basic \(Environment.shared.mcsConfig.anonymousKey)",
                "oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                "Content-Type": "application/json"
        ] // dynamic unauth key ..... replace unauth key with Environment.shared.mcsConfig.anonymousKey
        case .fetchAccountDetails(_ , _, let token):
            return ["oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                    "Authorization": "Bearer \(token)"]
        case .fetchAccounts(let token):
            return ["oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                    "Authorization": "Bearer \(token)"]
        case .minVersion, .fetchMaintenanceMode:
            return ["Authorization": "Basic \(Environment.shared.mcsConfig.anonymousKey)",
                "oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId
        ] // dynamic unauth key
        case .fetchToken:
            return ["content-type": "application/x-www-form-urlencoded"]
        case .exchangeToken(let token):
            return ["encode": "xml",
                    "oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                    "Authorization": "Bearer \(token)"]
        default:
            return nil
        }
    }
    
    public var httpBody: HTTPBody? {
        switch self {
        case .fetchToken(let httpBody), .fetchAnonOutageStatus(let httpBody):
            return httpBody
        default:
            return nil
        }
    }
    
    public var mockFileName: String {
        switch self {
        case .minVersion:
            return "minVersionMock"
        default:
            return ""
        }
    }
    
}
