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
    }
    
    case minVersion
    case maintenanceMode
    
    case fetchJWTToken(postData: Data)//(encodable: Encodable)
    
    // Registration
    case registration(encodable: Encodable)
    case checkDuplicateRegistration(encodable: Encodable)
    case registrationQuestions
    case validateRegistration(encodable: Encodable)
    case sendConfirmationEmail(encodable: Encodable)
    case validateConfirmationEmail(encodable: Encodable)
    
    case accounts
    case accountDetails(accountNumber: String, queryString: String)
    
    // PECO only release of info preferences
    case updateReleaseOfInfo(accountNumber: String, encodable: Encodable)
    
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
    
    case energyTips(accountNumber: String, premiseNumber: String)
    
    case homeProfileLoad(accountNumber: String, premiseNumber: String)
    case homeProfileUpdate(accountNumber: String, premiseNumber: String, encodable: Encodable)
    
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
    case outageStatus(accountNumber: String, premiseNumber: String)
    case reportOutage(accountNumber: String, encodable: Encodable)
    case meterPing(accountNumber: String, premiseNumber: String)
    
    // Unauthenticated
    case anonOutageStatus(encodable: Encodable)

    case passwordChange(encodable: Encodable)
    case accountLookup(encodable: Encodable)
    case recoverPassword(encodable: Encodable)
    case recoverUsername(encodable: Encodable)
    case recoverMaskedUsername(encodable: Encodable)
    
    public var scheme: String {
        return "https"
    }
    
    // BGE Stage
    public var host: String {
        switch self {
        case .fetchJWTToken:
            return "stage-apigateway.exeloncorp.com"// todo: fix in mcs config
        case .weather:
            return "api.weather.gov"
        case .alertBanner, .newsAndUpdates:
            return "azstg.bge.com/_api/web/lists/GetByTitle('GlobalAlert')/items" // todo: fix in mcs config
        default:
            //return Environment.shared.mcsConfig.baseUrl
            return "mcsstg.mobileenv.bge.com" // todo fix in mcs config
        }
    }
    
    public var apiAccess: ApiAccess {
        switch self {
        // External
        case .weather:
            return .external
        // Anon
        case .minVersion:
            return .anon
        case .maintenanceMode:
            return .anon
        case .anonOutageStatus:
            return .anon
        case .passwordChange:
            return .anon
        case .fetchJWTToken:
            return .anon
        default:
            return .auth
        }
    }
    
    public var path: String {
        switch self {
        case .anonOutageStatus:
            return "/mobile/custom/\(apiAccess)/\(Environment.shared.opco.displayString)/outage/query"
        case .maintenanceMode:
            return "/mobile/custom/\(apiAccess)/\(Environment.shared.opco.displayString)/config/maintenance"
        case .accountDetails(let accountNumber, let queryString):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)\(queryString)"
        case .accounts:
            return "/mobile/custom/\(apiAccess)/accounts"
        case .updateReleaseOfInfo(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/preferences/release"
        case .minVersion:
            return "/mobile/custom/\(apiAccess)/\(Environment.shared.opco.displayString)/config/versions"
        case .fetchJWTToken:
            return "/eu/oauth2/token"
        case .registration:
            return "/mobile/custom/\(apiAccess)/registration"
        case .checkDuplicateRegistration:
            return "/mobile/custom/\(apiAccess)/registration/duplicate"
        case .registrationQuestions:
            return "/mobile/custom/\(apiAccess)/registration/questions"
        case .validateRegistration:
            return "/mobile/custom/\(apiAccess)/registration/validate"
        case .sendConfirmationEmail:
            return "/mobile/custom/\(apiAccess)/registration/confirmation"
        case .validateConfirmationEmail:
            return "/mobile/custom/\(apiAccess)/registration/confirmation"
        case .weather(let lat, let long):
            return "/points/\(lat),\(long)/forecast/hourly"
        case .wallet:
            return "/mobile/custom/\(apiAccess)/wallet/query"
        case .payments(let accountNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/payments"
        case .alertBanner, .newsAndUpdates:
            return "/_api/web/lists/GetByTitle('GlobalAlert')/items"
        case .billPDF(let accountNumber, let date):
            let dateString = DateFormatter.yyyyMMddFormatter.string(from: date)
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/billing/\(dateString)/pdf"
        case .scheduledPayment(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/payments/schedule"
        case .scheduledPaymentUpdate(let accountNumber, let paymentId, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .scheduledPaymentDelete(let accountNumber, let paymentId, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .billingHistory(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/billing/history"
        case .payment:
            return "/mobile/custom/\(apiAccess)/encryptionkey"
        case .deleteWalletItem:
            return "/mobile/custom/\(apiAccess)/wallet/delete"
        case .compareBill(let accountNumber, let premiseNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/premises/\(premiseNumber)/usage/compare_bills"
        case .autoPayInfo(let accountNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/payments/recurring"
        case .autoPayEnroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/payments/recurring"
        case .autoPayUnenroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/payments/recurring/delete"
        case .paperlessEnroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/billing/paperless"
        case .paperlessUnenroll(let accountNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/billing/paperless"
        case .budgetBillingInfo(let accountNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/billing/budget"
        case .budgetBillingEnroll(let accountNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/billing/budget"
        case .budgetBillingUnenroll(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/billing/budget/delete"
        case .forecastBill(let accountNumber, let premiseNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/premises/\(premiseNumber)/usage/forecast_bill"
        case .ssoData(let accountNumber, let premiseNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/premises/\(premiseNumber)/ssodata"
        case .energyTips(let accountNumber, let premiseNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/premises/\(premiseNumber)/tips"
        case .homeProfileLoad(let accountNumber, let premiseNumber), .homeProfileUpdate(let accountNumber, let premiseNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/premises/\(premiseNumber)/home_profile"
        case .energyRewardsLoad(let accountNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/programs"
        case .alertPreferencesLoad(let accountNumber), .alertPreferencesUpdate(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/alerts/preferences/push"
        case .appointments(let accountNumber, let premiseNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/premises/\(premiseNumber)/service/appointments/query"
            
        case .passwordChange:
            return "/mobile/custom/\(apiAccess)/profile/password"
        case .accountLookup:
            return "/mobile/custom/\(apiAccess)/account/lookup"
        case .recoverPassword:
            return "/mobile/custom/\(apiAccess)/recover/password"
        case .recoverUsername, .recoverMaskedUsername:
            return "/mobile/custom/\(apiAccess)/recover/username"
        case .outageStatus(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/outage?meterPing=false"
        case .reportOutage(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/outage"
        case .meterPing(let accountNumber, let premiseNumber):
            return "/mobile/custom/\(apiAccess)/accounts/\(accountNumber)/premises\(premiseNumber)/outage"
        case .fetchGameUser(let accountNumber):
            return "/mobile/custom/\(apiAccess)/game/\(accountNumber)"
        case .updateGameUser(let accountNumber, _):
            return "/mobile/custom/\(apiAccess)/game/\(accountNumber)"
        case .fetchDailyUsage(let accountNumber, let premiseNumber, _):
            return "accounts/\(accountNumber)/premises/\(premiseNumber)/usage/query"
        }
    }
    
    public var method: String {
        switch self {
        case .anonOutageStatus, .fetchJWTToken, .wallet, .scheduledPayment, .billingHistory, .payment, .deleteWalletItem, .compareBill, .autoPayEnroll, .scheduledPaymentDelete, .autoPayUnenroll, .budgetBillingUnenroll, .accountLookup, .recoverPassword, .recoverUsername, .recoverMaskedUsername, .reportOutage, .registration, .checkDuplicateRegistration, .validateRegistration, .sendConfirmationEmail, .fetchDailyUsage:
            return "POST"
        case .maintenanceMode, .accountDetails, .accounts, .minVersion, .weather, .payments, .alertBanner, .newsAndUpdates, .billPDF, .budgetBillingEnroll, .autoPayInfo, .budgetBillingInfo, .forecastBill, .ssoData, .energyTips, .homeProfileLoad, .energyRewardsLoad, .alertPreferencesLoad, .appointments, .outageStatus, .meterPing, .fetchGameUser, .registrationQuestions:
            return "GET"
        case .paperlessEnroll, .scheduledPaymentUpdate, .passwordChange, .homeProfileUpdate, .alertPreferencesUpdate, .updateGameUser,
             .updateReleaseOfInfo, .validateConfirmationEmail:
            return "PUT"
        case .paperlessUnenroll:
            return "DELETE"
        }
    }
    
    public var token: String {
        return UserSession.shared.token
    }
    
    public var parameters: [URLQueryItem] {
        switch self {
        case .alertBanner(let additionalQueryItem), .newsAndUpdates(let additionalQueryItem):
            return [URLQueryItem(name: "$select", value: "Title,Message,Enable,CustomerType,Created,Modified"),
                    URLQueryItem(name: "$orderby", value: "Modified desc"),
                    additionalQueryItem]
        default:
            return []
        }
    }
    
    // todo: this may change to switch off of api access... I believe all vlaues below are derived from auth, anon, admin.  Hold off on changing this for now tho... need to dig deeper.
    public var httpHeaders: HTTPHeaders? {
        switch self {
        case .fetchJWTToken:
            return ["content-type": "application/x-www-form-urlencoded"]
        case .alertBanner, .newsAndUpdates:
            return ["Accept": "application/json;odata=verbose"]
        case .anonOutageStatus:
            return ["Authorization": "Basic \(Environment.shared.mcsConfig.anonymousKey)",
                    "Content-Type": "application/json"]
        case .minVersion, .maintenanceMode:
            return ["Authorization": "Basic \(Environment.shared.mcsConfig.anonymousKey)"]
        case .accounts, .accountDetails, .wallet, .payments, .billPDF, .budgetBillingEnroll, .autoPayInfo, .paperlessUnenroll, .budgetBillingInfo, .forecastBill, .ssoData, .energyTips, .homeProfileLoad, .energyRewardsLoad, .alertPreferencesLoad, .appointments:
            return ["Authorization": "Bearer \(token)"]
        case .scheduledPayment, .billingHistory, .payment, .deleteWalletItem, .compareBill, .autoPayEnroll, .paperlessEnroll, .scheduledPaymentUpdate, .scheduledPaymentDelete, .autoPayUnenroll, .budgetBillingUnenroll, .homeProfileUpdate, .alertPreferencesUpdate:
            return ["Authorization": "Bearer \(token)",
                    "Content-Type": "application/json"]
        default:
            return nil
        }
    }
    
    public var httpBody: HTTPBody? {
        switch self {
        case .fetchJWTToken(let postData):
            // Custom encoding here.
            return postData
        case .passwordChange(let encodable), .accountLookup(let encodable), .recoverPassword(let encodable), .budgetBillingUnenroll(_, let encodable), .autoPayEnroll(_, let encodable), .anonOutageStatus(let encodable), .scheduledPayment(_, let encodable), .billingHistory(_, let encodable), .payment(let encodable), .deleteWalletItem(let encodable), .compareBill(_, _, let encodable), .autoPayUnenroll(_, let encodable), .scheduledPaymentUpdate(_, _, let encodable), .homeProfileUpdate(_, _, let encodable), .alertPreferencesUpdate(_, let encodable):
        case .passwordChange(let encodable), .accountLookup(let encodable), .recoverPassword(let encodable), .budgetBillingUnenroll(_, let encodable), .autoPayEnroll(_, let encodable), .anonOutageStatus(let encodable), .scheduledPayment(_, let encodable), .billingHistory(_, let encodable), .payment(let encodable), .deleteWalletItem(let encodable), .compareBill(_, _, let encodable), .autoPayUnenroll(_, let encodable), .scheduledPaymentUpdate(_, _, let encodable), .homeProfileUpdate(_, _, let encodable), .alertPreferencesUpdate(_, let encodable),
             .fetchDailyUsage(_, _, let encodable):
            return encode(encodable)
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
        case .reportOutage:
            return "ReportOutageMock"
        case .meterPing:
            return "MeterPingMock"
        case .ssoData:
            return "SSODataMock"
        case .energyTips:
            return "EnergyTipsMock"
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
    
    private func encode(_ encodable: Encodable) -> HTTPBody {
        let encodable = AnyEncodable(value: encodable)
        
        do {
            return try JSONEncoder().encode(encodable)
        } catch {
            fatalError("Error encoding object: \(error)")
        }
    }
}
