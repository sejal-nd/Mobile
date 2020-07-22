//
//  Router.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public typealias HTTPHeaders = [String: String]
public typealias HTTPBody = Data?

public enum Router {
    public enum ApiAccess: String {
        case admin
        case anon
        case auth
        case external
        
        public var path: String {
            switch self {
            case .anon:
                return "\(rawValue)/\(Environment.shared.opco.rawValue)"
            default:
                return rawValue
            }
        }
    }
    
    case minVersion
    case maintenanceMode
    
    case fetchJWTToken(request: JWTRequest)
    
    // Registration
    case registration(encodable: NewAccountRequest)
    case checkDuplicateRegistration(encodable: UsernameRequest)
    case registrationQuestions
    case validateRegistration(encodable: ValidateAccountRequest)
    case sendConfirmationEmail(encodable: UsernameRequest)
    case validateConfirmationEmail(encodable: GuidRequest)
    
    case accounts
    case accountDetails(accountNumber: String, queryString: String)
    case setDefaultAccount(accountNumber: String)
    case setAccountNickname(request: AccountNicknameRequest)
    
    // PECO only release of info preferences
    case updateReleaseOfInfo(accountNumber: String, encodable: ReleaseOfInfoRequest)
    
    case weather(lat: String, long: String)
    
    case wallet
    
    case payments(accountNumber: String)
    
    case alertBanner(additionalQueryItem: URLQueryItem)
        
    // Billing
    
    case billPDF(accountNumber: String, date: Date)
    
    case scheduledPayment(accountNumber: String, encodable: Encodable)
    case scheduledPaymentUpdate(accountNumber: String, paymentId: String, encodable: Encodable)
    case scheduledPaymentDelete(accountNumber: String, paymentId: String, encodable: Encodable)
    
    case billingHistory(accountNumber: String, encodable: Encodable)
    
    case payment(encodable: Encodable)
    
    case deleteWalletItem(encodable: Encodable)
    
    case compareBill(accountNumber: String, premiseNumber: String, encodable: Encodable)
    
    case autoPayInfo(accountNumber: String) // todo - Mock + model
    case autoPayEnroll(accountNumber: String, encodable: Encodable)
    case autoPayUnenroll(accountNumber: String, encodable: Encodable) // todo - Mock + model
    
    case paperlessEnroll(accountNumber: String, encodable: Encodable)
    case paperlessUnenroll(accountNumber: String) // todo - Mock + model
    
    case budgetBillingInfo(accountNumber: String)
    case budgetBillingEnroll(accountNumber: String)
    case budgetBillingUnenroll(accountNumber: String, encodable: Encodable)
    
    // Usage
    case forecastBill(accountNumber: String, premiseNumber: String)
    
    case ssoData(accountNumber: String, premiseNumber: String)
    case ffssoData(accountNumber: String, premiseNumber: String)
    
    case energyTips(accountNumber: String, premiseNumber: String)
    case energyTip(accountNumber: String, premiseNumber: String, tipName: String)
    
    case homeProfileLoad(accountNumber: String, premiseNumber: String)
    case homeProfileUpdate(accountNumber: String, premiseNumber: String, encodable: HomeProfileUpdateRequest)
    
    case energyRewardsLoad(accountNumber: String)
    // todo energyRewardsUpdate
    
    // Gamification
    case fetchGameUser(accountNumber: String)
    case updateGameUser(accountNumber: String, encodable: Encodable)
    case fetchDailyUsage(accountNumber: String, premiseNumber: String, encodable: Encodable)
    
    // More
    case alertPreferencesLoad(accountNumber: String)
    case alertPreferencesUpdate(accountNumber: String, encodable: Encodable)
    
    case newsAndUpdates(additionalQueryItem: URLQueryItem)
    
    case appointments(accountNumber: String, premiseNumber: String)
    
    // Outage
    case outageStatus(accountNumber: String, summaryQueryItem: URLQueryItem? = nil)
    case outageStatusAnon(request: AnonOutageRequest)
    case meterPing(accountNumber: String, premiseNumber: String? = nil)
    case reportOutage(accountNumber: String, request: OutageRequest)
    case reportOutageAnon(request: OutageRequest)

    // Unauthenticated    
    case passwordChange(request: ChangePasswordRequest)
    case accountLookup(request: AccountLookupRequest)
    case recoverPassword(encodable: Encodable)
    case recoverUsername(request: RecoverUsernameRequest)
    case recoverMaskedUsername(request: RecoverMaskedUsernameRequest)
    
    public var scheme: String {
        return "https"
    }
    
    public var host: String {
        switch self {
        case .fetchJWTToken:
            return Environment.shared.mcsConfig.oAuthEndpoint
        case .weather:
            return "api.weather.gov"
        case .alertBanner, .newsAndUpdates:
            return Environment.shared.mcsConfig.sharepointBaseURL
        default:
            return Environment.shared.mcsConfig.baseUrl
        }
    }
    
    private var basePath: String {
        if Environment.shared.environmentName != .test && Environment.shared.opco.isPHI {
            // Project specific environment
            return "/phimobile/mobile/custom"
        } else {
            return "/mobile/custom"
        }
    }
    
    public var apiAccess: ApiAccess {
        switch self {
        case .weather:
            return .external
        case .minVersion, .maintenanceMode, .fetchJWTToken, .passwordChange, .outageStatusAnon, .reportOutageAnon, .recoverUsername, .recoverMaskedUsername, .accountLookup:
            return .anon
        default:
            return .auth
        }
    }
    
    public var path: String {
        switch self {
        case .outageStatusAnon:
            return "\(basePath)/\(apiAccess.path)/outage/query"
        case .maintenanceMode:
            return "\(basePath)/\(apiAccess.path)/config/maintenance"
        case .accountDetails(let accountNumber, let queryString):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)\(queryString)"
        case .accounts:
            return "\(basePath)/\(apiAccess.path)/accounts"
        case .setDefaultAccount(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/default"
        case .setAccountNickname:
            return "\(basePath)/\(apiAccess.path)/profile/update/account/nickname"
        case .updateReleaseOfInfo(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/preferences/release"
        case .minVersion:
            return "\(basePath)/\(apiAccess.path)/config/versions"
        case .fetchJWTToken:
            return "/eu/oauth2/token"
        case .registration:
            return "\(basePath)/\(apiAccess.path)/registration"
        case .checkDuplicateRegistration:
            return "\(basePath)/\(apiAccess.path)/registration/duplicate"
        case .registrationQuestions:
            return "\(basePath)/\(apiAccess.path)/registration/questions"
        case .validateRegistration:
            return "\(basePath)/\(apiAccess.path)/registration/validate"
        case .sendConfirmationEmail:
            return "\(basePath)/\(apiAccess.path)/registration/confirmation"
        case .validateConfirmationEmail:
            return "\(basePath)/\(apiAccess.path)/registration/confirmation"
        case .weather(let lat, let long):
            return "/points/\(lat),\(long)/forecast/hourly"
        case .wallet:
            return "\(basePath)/\(apiAccess.path)/wallet/query"
        case .payments(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments"
        case .alertBanner, .newsAndUpdates:
            return "/_api/web/lists/GetByTitle('GlobalAlert')/items"
        case .billPDF(let accountNumber, let date):
            let dateString = DateFormatter.yyyyMMddFormatter.string(from: date)
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/\(dateString)/pdf"
        case .scheduledPayment(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/schedule"
        case .scheduledPaymentUpdate(let accountNumber, let paymentId, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .scheduledPaymentDelete(let accountNumber, let paymentId, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .billingHistory(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/history"
        case .payment:
            return "\(basePath)/\(apiAccess.path)/encryptionkey"
        case .deleteWalletItem:
            return "\(basePath)/\(apiAccess.path)/wallet/delete"
        case .compareBill(let accountNumber, let premiseNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/usage/compare_bills"
        case .autoPayInfo(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/recurring"
        case .autoPayEnroll(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/recurring"
        case .autoPayUnenroll(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/recurring/delete"
        case .paperlessEnroll(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/paperless"
        case .paperlessUnenroll(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/paperless"
        case .budgetBillingInfo(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/budget"
        case .budgetBillingEnroll(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/budget"
        case .budgetBillingUnenroll(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/budget/delete"
        case .forecastBill(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/usage/forecast_bill"
        case .ssoData(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/ssodata"
        case .ffssoData(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/ffssodata"
        case .energyTips(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/tips"
        case .energyTip(let accountNumber, let premiseNumber, let tipName):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/tips/\(tipName)"
        case .homeProfileLoad(let accountNumber, let premiseNumber), .homeProfileUpdate(let accountNumber, let premiseNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/home_profile"
        case .energyRewardsLoad(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/programs"
        case .alertPreferencesLoad(let accountNumber), .alertPreferencesUpdate(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/alerts/preferences/push"
        case .appointments(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/service/appointments/query"
        case .passwordChange:
            return "\(basePath)/\(apiAccess.path)/profile/password"
        case .accountLookup:
            return "\(basePath)/\(apiAccess.path)/account/lookup"
        case .recoverPassword:
            return "\(basePath)/\(apiAccess.path)/recover/password"
        case .recoverUsername, .recoverMaskedUsername:
            return "\(basePath)/\(apiAccess.path)/recover/username"
        case .outageStatus(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/outage"
        case .reportOutage(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/outage"
        case .meterPing(let accountNumber, let premiseNumber):
            if let premiseNumber = premiseNumber {
                return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/outage/ping"
            } else {
                return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/outage/ping"
            }
        case .fetchGameUser(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/game/\(accountNumber)"
        case .updateGameUser(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/game/\(accountNumber)"
        case .fetchDailyUsage(let accountNumber, let premiseNumber, _):
            return "accounts/\(accountNumber)/premises/\(premiseNumber)/usage/query"
        case .reportOutageAnon:
            return "\(basePath)/\(apiAccess.path)/outage"
        }
    }
    
    public var method: String {
        switch self {
        case .outageStatusAnon, .fetchJWTToken, .wallet, .scheduledPayment, .billingHistory, .payment, .deleteWalletItem, .compareBill, .autoPayEnroll, .scheduledPaymentDelete, .autoPayUnenroll, .budgetBillingUnenroll, .accountLookup, .recoverPassword, .recoverUsername, .recoverMaskedUsername, .reportOutage, .registration, .checkDuplicateRegistration, .validateRegistration, .sendConfirmationEmail, .fetchDailyUsage, .reportOutageAnon:
            return "POST"
        case .maintenanceMode, .accountDetails, .accounts, .minVersion, .weather, .payments, .alertBanner, .newsAndUpdates, .billPDF, .budgetBillingEnroll, .autoPayInfo, .budgetBillingInfo, .forecastBill, .ssoData, .ffssoData, .energyTips, .energyTip, .homeProfileLoad, .energyRewardsLoad, .alertPreferencesLoad, .appointments, .outageStatus, .meterPing, .fetchGameUser, .registrationQuestions, .setAccountNickname:
            return "GET"
        case .paperlessEnroll, .scheduledPaymentUpdate, .passwordChange, .homeProfileUpdate, .alertPreferencesUpdate, .updateGameUser,
             .updateReleaseOfInfo, .validateConfirmationEmail, .setDefaultAccount:
            return "PUT"
        case .paperlessUnenroll:
            return "DELETE"
        }
    }
    
    public var token: String {
        return UserSession.shared.token
    }
    
    // todo: this may change to switch off of api access... I believe all vlaues below are derived from auth, anon, admin.  Hold off on changing this for now tho... need to dig deeper.
    public var httpHeaders: HTTPHeaders? {
        var headers: HTTPHeaders? = nil

        switch self {
        case .alertBanner, .newsAndUpdates:
            headers?["Accept"] = "application/json;odata=verbose"
        case .fetchJWTToken:
            headers?["content-type"] = "application/x-www-form-urlencoded"
        case .outageStatusAnon, .reportOutageAnon, .recoverUsername, .recoverMaskedUsername, .accountLookup, .accounts, .accountDetails, .wallet, .payments, .billPDF, .budgetBillingEnroll, .autoPayInfo, .paperlessUnenroll, .budgetBillingInfo, .forecastBill, .ssoData, .ffssoData, .energyTips, .energyTip, .homeProfileLoad, .energyRewardsLoad, .alertPreferencesLoad, .appointments, .scheduledPayment, .billingHistory, .payment, .deleteWalletItem, .compareBill, .autoPayEnroll, .paperlessEnroll, .scheduledPaymentUpdate, .scheduledPaymentDelete, .autoPayUnenroll, .budgetBillingUnenroll, .homeProfileUpdate, .alertPreferencesUpdate, .outageStatus, .meterPing, .reportOutage:
            headers?["Content-Type"] = "application/json"
        default:
            break
        }
        
        if apiAccess == .auth {
            headers?["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    public var parameters: [URLQueryItem] {
        switch self {
        case .alertBanner(let additionalQueryItem), .newsAndUpdates(let additionalQueryItem):
            return [URLQueryItem(name: "$select", value: "Title,Message,Enable,CustomerType,Created,Modified"),
                    URLQueryItem(name: "$orderby", value: "Modified desc"),
                    additionalQueryItem]
        case .outageStatus(_, let summaryQueryItem):
             var queryItems = [URLQueryItem(name: "meterPing", value: "false")]
             if let summaryQueryItem = summaryQueryItem {
                queryItems.append(summaryQueryItem)
             }
            return queryItems
        default:
            return []
        }
    }
    
    public var httpBody: HTTPBody? {
        switch self {
        case .passwordChange(let request as Encodable), .accountLookup(let request as Encodable), .recoverPassword(let request as Encodable), .budgetBillingUnenroll(_, let request as Encodable), .autoPayEnroll(_, let request as Encodable), .outageStatusAnon(let request as Encodable), .scheduledPayment(_, let request as Encodable), .billingHistory(_, let request as Encodable), .payment(let request as Encodable), .deleteWalletItem(let request as Encodable), .compareBill(_, _, let request as Encodable), .autoPayUnenroll(_, let request as Encodable), .scheduledPaymentUpdate(_, _, let request as Encodable), .homeProfileUpdate(_, _, let request as Encodable), .alertPreferencesUpdate(_, let request as Encodable),
             .fetchDailyUsage(_, _, let request as Encodable), .updateGameUser(_, let request as Encodable), .setAccountNickname(let request as Encodable), .reportOutageAnon(let request as Encodable), .recoverMaskedUsername(let request as Encodable), .recoverUsername(let request as Encodable), .accountLookup(let request as Encodable):
            return request.data()
        case .fetchJWTToken(let request):
            let postDataString = "username=\(Environment.shared.opco.rawValue.uppercased())\\\(request.username)&password=\(request.password)"
            return postDataString.data(using: .utf8)
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
        case .fetchJWTToken:
            return "JWTTokenMock"
        case .accounts:
            return "AccountsMock"
        case .weather:
            return "WeatherMock"
        case .wallet:
            return "WalletMock"
        case .payments:
            return "PaymentsMock"
        case .alertBanner, .newsAndUpdates:
            return "SharePointAlertMock"
        case .billPDF:
            return "BillPDFMock"
        case .scheduledPayment, .scheduledPaymentUpdate, .scheduledPaymentDelete:
            return "ScheduledPaymentMock"
        case .billingHistory:
            return "BillingHistoryMock"
        case .payment:
            return "PaymentMock"
        case .compareBill:
            return "CompareBillMock"
        case .autoPayInfo:
            return "AutoPayInfoMock" // TODO
        case .autoPayEnroll:
            return "AutoPayEnrollMock"
        case .autoPayUnenroll:
            return "AutoPayUnenrollMock" // TODO
        case .budgetBillingInfo:
            return "BudgetBillingMock"
        case .forecastBill:
            return "ForecastBillMock"
        case .accountLookup:
            return "AccountLookupResultMock"
        case .recoverUsername:
            fallthrough
        case .recoverMaskedUsername:
            return "RecoverUsernameResultMock"
        case .outageStatus:
            return "OutageStatusMock"
        case .outageStatusAnon:
            return "AnonOutageStatusMock"
        case .reportOutage, .reportOutageAnon: // todo vlaidate anon is same response as auth
            return "ReportOutageMock"
        case .meterPing:
            return "MeterPingMock"
        case .ssoData:
            return "SSODataMock"
        case .ffssoData:
            return "SSODataMock"
        case .energyTips:
            return "EnergyTipsMock"
        case .energyTip:
            return "EnergyTipMock"
        case .homeProfileLoad:
            return "HomeProfileLoadMock"
        case .energyRewardsLoad:
            return "EnergyRewardsMock"
        case .alertPreferencesLoad:
            return "AlertPreferencesLoadMock"
        case .appointments:
            return "AppointmentsMock"
        case .deleteWalletItem, .budgetBillingEnroll, .budgetBillingUnenroll, .paperlessEnroll, .paperlessUnenroll, .homeProfileUpdate, .alertPreferencesUpdate:
            return "GenericResponseMock"
        case .fetchDailyUsage:
            return "DailyUsageMock"
        default:
            return ""
        }
    }
}
