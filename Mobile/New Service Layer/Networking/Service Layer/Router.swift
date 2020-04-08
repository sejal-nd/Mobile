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

    case billPDF(accountNumber: String, date: Date)
    
    case scheduledPayment(accountNumber: String, httpBody: HTTPBody)
    case scheduledPaymentUpdate(accountNumber: String, paymentId: String, httpBody: HTTPBody)
    case scheduledPaymentDelete(accountNumber: String, paymentId: String, httpBody: HTTPBody)
    
    case billingHistory(accountNumber: String, httpBody: HTTPBody)
    
    case payment(httpBody: HTTPBody)
    
    case deleteWalletItem(httpBody: HTTPBody)
    
    case compareBill(accountNumber: String, premiseNumber: String, httpBody: HTTPBody)

    case autoPayInfo(accountNumber: String) // todo - Mock + model
    case autoPayEnroll(accountNumber: String, httpBody: HTTPBody)
    case autoPayUnenroll(accountNumber: String, httpBody: HTTPBody) // todo - Mock + model
    
    case paperlessEnroll(accountNumber: String, httpBody: HTTPBody)
    case paperlessUnenroll(accountNumber: String)
    
    case budgetBillingInfo(accountNumber: String)
    case budgetBillingEnroll(accountNumber: String)
    case budgetBillingUnenroll(accountNumber: String, httpBody: HTTPBody)
    
//    case getSources
//    case getProductIds
//    case getProductInfo
    
    public var scheme: String {
        return "https"
    }
    
    public var host: String {
        switch self {
        case .fetchSAMLToken:
            return "dev-apigateway.exeloncorp.com"//"stage-apigateway.exeloncorp.com" // TEMP
        case .weather:
            return "api.weather.gov"
        case .alertBanner:
            return "azstg.bge.com"
        default:
            //return Environment.shared.mcsConfig.baseUrl
            return "exeloneumobileapptest-a453576.mobileenv.us2.oraclecloud.com"
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
        case .billPDF(let accountNumber, let date):
            let dateString = DateFormatter.yyyyMMddFormatter.string(from: date)
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/billing/\(dateString)/pdf" // todo how do we get date?
        case .scheduledPayment(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/payments/schedule"
        case .scheduledPaymentUpdate(let accountNumber, let paymentId, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .scheduledPaymentDelete(let accountNumber, let paymentId, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .billingHistory(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/billing/history"
        case .payment:
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/encryptionkey"
        case .deleteWalletItem:
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/wallet/delete"
        case .compareBill(let accountNumber, let premiseNumber, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/premises/\(premiseNumber)/usage/compare_bills"
        case .autoPayInfo(let accountNumber):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/payments/recurring"
        case .autoPayEnroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/payments/recurring"
        case .autoPayUnenroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/payments/recurring/delete"
        case .paperlessEnroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/billing/paperless"
        case .paperlessUnenroll(let accountNumber):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/billing/paperless"
        case .budgetBillingInfo(let accountNumber):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/billing/budget"
        case .budgetBillingEnroll(let accountNumber):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/billing/budget"
        case .budgetBillingUnenroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)_\(apiVersion)/accounts/\(accountNumber)/billing/budget/delete"
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
        case .anonOutageStatus, .fetchSAMLToken, .wallet, .scheduledPayment, .billingHistory, .payment, .deleteWalletItem, .compareBill, .autoPayEnroll, .scheduledPaymentDelete, .autoPayUnenroll, .budgetBillingUnenroll:
            return "POST"
        case .maintenanceMode, .accountDetails, .accounts, .exchangeSAMLToken, .minVersion, .weather, .payments, .alertBanner, .billPDF, .budgetBillingEnroll, .autoPayInfo, .budgetBillingInfo:
            return "GET"
        case .paperlessEnroll, .scheduledPaymentUpdate:
            return "PUT"
        case .paperlessUnenroll:
            return "DELETE"
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
        case .scheduledPayment, .billingHistory, .payment, .deleteWalletItem, .compareBill, .autoPayEnroll, .paperlessEnroll, .scheduledPaymentUpdate, .scheduledPaymentDelete, .autoPayUnenroll, .budgetBillingUnenroll:
            return ["Authorization": "Bearer \(token)",
                "oracle-mobile-backend-id": Environment.shared.mcsConfig.mobileBackendId,
                "Content-Type": "application/json"
            ]
        case .accounts, .accountDetails, .wallet, .payments, .billPDF, .budgetBillingEnroll, .autoPayInfo, .paperlessUnenroll, .budgetBillingInfo:
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
        case .fetchSAMLToken(let httpBody), .anonOutageStatus(let httpBody), .scheduledPayment(_, let httpBody), .billingHistory(_, let httpBody), .payment(let httpBody), .deleteWalletItem(let httpBody), .compareBill(_, _, let httpBody), .autoPayEnroll(_, let httpBody), .autoPayUnenroll(_, let httpBody), .scheduledPaymentUpdate(_, _, let httpBody), .budgetBillingUnenroll(_, let httpBody):
            return httpBody
        default:
            return nil
        }
    }
    
    public var mockFileName: String {
        switch self {
        case .minVersion:
            return "MinVersionMock"
        case .maintenanceMode:
            return "MaintenanceModeMock"
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
        case .billPDF:
            return "BillPDFMock"
        case .scheduledPayment, .scheduledPaymentUpdate, .scheduledPaymentDelete:
            return "ScheduledPaymentMock"
        case .billingHistory:
            return "BillingHistoryMock"
        case .payment:
            return "PaymentMock"
        case .deleteWalletItem:
            return "DeleteWalletItemMock"
        case .compareBill:
            return "CompareBillMock"
        case .autoPayInfo:
            return "AutoPayInfoMock" // TODO
        case .autoPayEnroll:
            return "AutoPayEnrollMock"
        case .autoPayUnenroll:
            return "AutoPayUnenrollMock" // TODO
        case .paperlessEnroll:
            return "PaperlessMock"
        case .budgetBillingInfo:
            return "BudgetBillingMock"
        case .budgetBillingEnroll, .budgetBillingUnenroll:
            return "BudgetBillingResultMock"
        default:
            return ""
        }
    }
    
}
