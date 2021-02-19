//
//  Router.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public typealias HTTPHeaders = [String: String]
public typealias HTTPBody = Data

public enum Router {
    public enum ApiAccess: String {
        case anon
        case auth
        case none
        
        public var path: String {
            switch self {
            case .anon:
                return "\(rawValue)/\(Configuration.shared.opco.urlString)"
            case .none:
                return ""
            default:
                return rawValue
            }
        }
    }
    
    case minVersion
    case maintenanceMode
    
    // Apigee
    case fetchToken(request: TokenRequest)
    case refreshToken(request: RefreshTokenRequest)
    
    // Registration
    case validateRegistration(request: ValidateAccountRequest)
    case checkDuplicateRegistration(request: UsernameRequest)
    case registrationQuestions
    case registration(request: AccountRequest)
    case sendConfirmationEmail(request: UsernameRequest)
    case validateConfirmationEmail(request: GuidRequest)
    
    // Account
    case accounts
    case accountDetails(accountNumber: String, queryItems: [URLQueryItem])
    case setDefaultAccount(accountNumber: String)
    case setAccountNickname(request: AccountNicknameRequest)
    case passwordChange(request: ChangePasswordRequest)
    
    // PECO only release of info preferences
    case updateReleaseOfInfo(accountNumber: String, encodable: ReleaseOfInfoRequest)
    
    // Gov Weather
    case weather(lat: String, long: String)
    
    // Wallet
    case wallet(request: WalletRequest = WalletRequest())
    case addWalletItem(request: WalletItemRequest)
    case updateWalletItem(request: WalletItemRequest)
    case deleteWalletItem(request: WalletItemDeleteRequest)
    case bankName(routingNumber: String)
    case walletEncryptionKey(request: WalletEncryptionKeyRequest)
    
    // Billing
    case billPDF(accountNumber: String, date: Date, documentID: String)
    case payments(accountNumber: String)
    case scheduledPayment(accountNumber: String, request: ScheduledPaymentUpdateRequest)
    case scheduledPaymentUpdate(accountNumber: String, paymentId: String, request: ScheduledPaymentUpdateRequest)
    case scheduledPaymentDelete(accountNumber: String, paymentId: String, request: SchedulePaymentCancelRequest)
    case billingHistory(accountNumber: String, encodable: Encodable)
        
    // Auto Pay
    case autoPayInfo(accountNumber: String) // todo - Mock + model
    case autoPayEnrollBGE(accountNumber: String, request: AutoPayEnrollBGERequest)
    case updateAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest)
    case autoPayEnroll(accountNumber: String, request: AutoPayEnrollRequest)
    case updateAutoPay(accountNumber: String, request: AutoPayEnrollRequest)
    case autoPayUnenroll(accountNumber: String, request: AutoPayUnenrollRequest) // todo - Mock + model
    
    // Paperless
    case paperlessEnroll(accountNumber: String, request: EmailRequest)
    case paperlessUnenroll(accountNumber: String) // todo - Mock + model
    
    // Budget Bill
    case budgetBillingInfo(accountNumber: String)
    case budgetBillingEnroll(accountNumber: String)
    case budgetBillingUnenroll(accountNumber: String, encodable: Encodable)
    
    // Usage
    case ssoData(accountNumber: String, premiseNumber: String)
    case ffssoData(accountNumber: String, premiseNumber: String)
    case iTronssoData(accountNumber: String, premiseNumber: String)
    case peakEnergySavingsHistoryData(accountNumber: String, premiseNumber: String)

    case forecastBill(accountNumber: String, premiseNumber: String)
    case compareBill(accountNumber: String, premiseNumber: String, encodable: Encodable)
    case energyTips(accountNumber: String, premiseNumber: String)
    case energyTip(accountNumber: String, premiseNumber: String, tipName: String)
    
    // Home Profile
    case homeProfileLoad(accountNumber: String, premiseNumber: String)
    case homeProfileUpdate(accountNumber: String, premiseNumber: String, encodable: HomeProfileUpdateRequest)
    
    case energyRewardsLoad(accountNumber: String)
    
    // Gamification
    case fetchGameUser(accountNumber: String)
    case updateGameUser(accountNumber: String, request: GameUserRequest)
    case fetchDailyUsage(accountNumber: String, premiseNumber: String, request: DailyUsageRequest)
    
    // Alerts
    case registerForAlerts(request: AlertRegistrationRequest)
    case alertPreferencesLoad(accountNumber: String)
    case alertPreferencesUpdate(accountNumber: String, request: AlertPreferencesRequest)
    case fetchAlertLanguage(accountNumber: String)
    case setAlertLanguage(accountNumber: String, request: AlertLanguageRequest)
    case alertBanner(additionalQueryItem: URLQueryItem)
    
    // News & Updates
    case newsAndUpdates(additionalQueryItem: URLQueryItem)

    // Appointments
    case appointments(accountNumber: String, premiseNumber: String)
    
    // Outage
    case outageStatus(accountNumber: String, summaryQueryItem: URLQueryItem? = nil)
    case outageStatusAnon(request: AnonOutageRequest)
    case meterPing(accountNumber: String, premiseNumber: String? = nil)
    case meterPingAnon(request: AnonMeterPingRequest)
    case reportOutage(accountNumber: String, request: OutageRequest)
    case reportOutageAnon(request: OutageRequest)
    
    // Unauthenticated    
    case passwordChangeAnon(request: ChangePasswordRequest)
    case accountLookup(request: AccountLookupRequest)
    case recoverPassword(request: UsernameRequest)
    case recoverUsername(request: RecoverUsernameRequest)
    case recoverMaskedUsername(request: RecoverMaskedUsernameRequest)
    
    // Peak Rewards
    case peakRewardsSummary(accountNumber: String, premiseNumber: String)
    case peakRewardsOverrides(accountNumber: String, premiseNumber: String)
    case scheduleOverride(accountNumber: String, premiseNumber: String, deviceSerialNumber: String, request: DateRequest)
    case deleteOverride(accountNumber: String, premiseNumber: String, deviceSerialNumber: String)
    case deviceSettings(accountNumber: String, premiseNumber: String, deviceSerialNumber: String)
    case updateDeviceSettings(accountNumber: String, premiseNumber: String, deviceSerialNumber: String, request: SmartThermostatDeviceSettings)
    case thermostatSchedule(accountNumber: String, premiseNumber: String, deviceSerialNumber: String)
    case updateThermostatSchedule(accountNumber: String, premiseNumber: String, deviceSerialNumber: String, request: Encodable)
    
    public var scheme: String {
        return "https"
    }
    
    public var host: String {
        switch self {
        case .fetchToken, .refreshToken:
            return Configuration.shared.oAuthEndpoint
        case .weather:
            return "api.weather.gov"
        default:
            return Configuration.shared.baseUrl
        }
    }
    
    private var basePath: String {
        let projectURLRawValue = UserDefaults.standard.string(forKey: "selectedProjectURL") ?? ""
        let projectURLSuffix = ProjectURLSuffix(rawValue: projectURLRawValue) ?? .none
        return "\(projectURLSuffix.projectPath)/mobile/custom"
    }
    
    public var apiAccess: ApiAccess {
        switch self {
        case .weather:
            return .none
        case .minVersion, .maintenanceMode, .fetchToken, .refreshToken, .outageStatusAnon, .reportOutageAnon, .recoverUsername, .recoverMaskedUsername, .accountLookup, .validateRegistration, .checkDuplicateRegistration, .registrationQuestions, .registration, .sendConfirmationEmail, .recoverPassword, .bankName, .newsAndUpdates, .alertBanner, .meterPingAnon, .validateConfirmationEmail, .passwordChangeAnon:
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
        case .accountDetails(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)"
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
        case .fetchToken:
            return "/eu/digital/v1/oauth/token"
        case .refreshToken:
            return "/eu/digital/v1/oauth/refresh"
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
        case .addWalletItem:
            return "\(basePath)/\(apiAccess.path)/wallet"
        case .updateWalletItem:
            return "\(basePath)/\(apiAccess.path)/wallet"
        case .deleteWalletItem:
            return "\(basePath)/\(apiAccess.path)/wallet/delete"
        case .bankName(let routingNumber):
            return "\(basePath)/\(apiAccess.path)/bank/\(routingNumber)"
        case .payments(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments"
        case .alertBanner, .newsAndUpdates:
            return "\(basePath)/\(apiAccess.path)/config/alerts"
        case .billPDF(let accountNumber, let date, let documentID):
            let dateString = DateFormatter.yyyyMMddFormatter.string(from: date)
            return Configuration.shared.opco.isPHI ? "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/doc/\(documentID)/pdf" : "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/\(dateString)/pdf"
        case .scheduledPayment(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/schedule"
        case .scheduledPaymentUpdate(let accountNumber, let paymentId, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .scheduledPaymentDelete(let accountNumber, let paymentId, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/schedule/\(paymentId)"
        case .billingHistory(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/billing/history"
        case .walletEncryptionKey:
            return "\(basePath)/\(apiAccess.path)/encryptionkey"
        case .compareBill(let accountNumber, let premiseNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/usage/compare_bills"
        case .autoPayInfo(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/recurring"
        case .updateAutoPay(let accountNumber, _),
             .autoPayEnroll(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/payments/recurring"
        case .updateAutoPayBGE(let accountNumber, _),
             .autoPayEnrollBGE(let accountNumber, _):
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
        case .iTronssoData(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/sso/Intellisource"
        case .peakEnergySavingsHistoryData(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/sso/Intellisource"
        case .energyTips(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/tips"
        case .energyTip(let accountNumber, let premiseNumber, let tipName):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/tips/\(tipName)"
        case .homeProfileLoad(let accountNumber, let premiseNumber), .homeProfileUpdate(let accountNumber, let premiseNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/home_profile"
        case .energyRewardsLoad(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/programs"
        case .registerForAlerts:
            return "\(basePath)/noti/registration"
        case .alertPreferencesLoad(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/alerts/preferences/push"
        case .alertPreferencesUpdate(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/alerts/preferences"
        case .fetchAlertLanguage(let accountNumber), .setAlertLanguage(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/alerts/accounts"
        case .appointments(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/service/appointments/query"
        case .passwordChange, .passwordChangeAnon:
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
        case .meterPingAnon(_):
            return "\(basePath)/\(apiAccess.path)/outage/ping"
        case .fetchGameUser(let accountNumber):
            return "\(basePath)/\(apiAccess.path)/game/\(accountNumber)"
        case .updateGameUser(let accountNumber, _):
            return "\(basePath)/\(apiAccess.path)/game/\(accountNumber)"
        case .fetchDailyUsage(let accountNumber, let premiseNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/usage/query"
        case .reportOutageAnon:
            return "\(basePath)/\(apiAccess.path)/outage"
            
            
        case .peakRewardsSummary(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak"
        case .peakRewardsOverrides(let accountNumber, let premiseNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak/override"
        case .scheduleOverride(let accountNumber, let premiseNumber, let deviceSerialNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(deviceSerialNumber)/override"
        case .deleteOverride(let accountNumber, let premiseNumber, let deviceSerialNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(deviceSerialNumber)/override"
        case .deviceSettings(let accountNumber, let premiseNumber, let deviceSerialNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(deviceSerialNumber)/settings"
        case .updateDeviceSettings(let accountNumber, let premiseNumber, let deviceSerialNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(deviceSerialNumber)/settings"
        case .thermostatSchedule(let accountNumber, let premiseNumber, let deviceSerialNumber):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(deviceSerialNumber)/schedule"
        case .updateThermostatSchedule(let accountNumber, let premiseNumber, let deviceSerialNumber, _):
            return "\(basePath)/\(apiAccess.path)/accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(deviceSerialNumber)/schedule"
        }
    }
    
    public var method: String {
        switch self {
        case .outageStatusAnon, .fetchToken, .refreshToken, .wallet, .scheduledPayment, .billingHistory, .compareBill, .autoPayEnroll, .autoPayEnrollBGE, .scheduledPaymentDelete, .autoPayUnenroll, .budgetBillingUnenroll, .accountLookup, .recoverPassword, .recoverUsername, .recoverMaskedUsername, .reportOutage, .registration, .checkDuplicateRegistration, .validateRegistration, .sendConfirmationEmail, .fetchDailyUsage, .reportOutageAnon, .registerForAlerts, .addWalletItem, .deleteWalletItem, .walletEncryptionKey, .scheduleOverride, .updateDeviceSettings, .updateThermostatSchedule, .meterPingAnon, .setAccountNickname:
            return "POST"
        case .maintenanceMode, .accountDetails, .accounts, .minVersion, .weather, .payments, .alertBanner, .newsAndUpdates, .billPDF, .autoPayInfo, .budgetBillingInfo, .forecastBill, .ssoData, .ffssoData, .iTronssoData, .energyTips, .energyTip, .homeProfileLoad, .energyRewardsLoad, .alertPreferencesLoad, .appointments, .outageStatus, .meterPing, .fetchGameUser, .registrationQuestions, .fetchAlertLanguage, .bankName, .peakRewardsSummary, .peakRewardsOverrides, .deviceSettings, .thermostatSchedule, .peakEnergySavingsHistoryData:
            return "GET"
        case .paperlessEnroll, .scheduledPaymentUpdate, .passwordChangeAnon, .passwordChange, .homeProfileUpdate, .alertPreferencesUpdate, .updateGameUser,
             .updateReleaseOfInfo, .validateConfirmationEmail, .setDefaultAccount, .updateAutoPay, .updateAutoPayBGE, .setAlertLanguage, .updateWalletItem, .budgetBillingEnroll:
            return "PUT"
        case .paperlessUnenroll, .deleteOverride:
            return "DELETE"
        }
    }
    
    public var token: String {
        return UserSession.token
    }

    public var httpHeaders: HTTPHeaders {
        var headers: HTTPHeaders = [:]
        
        switch self {
        case .alertBanner, .newsAndUpdates:
            headers["Accept"] = "application/json;odata=verbose"
        default:
            headers["Content-Type"] = "application/json"
        }
        
        if apiAccess == .auth {
            headers["Authorization"] = "Bearer \(token)"
        }
                
        if ProcessInfo.processInfo.arguments.contains("-shoulLog.infoAPI") {
            Log.info("HTTP headers:\n\(headers)")
        }
        
        return headers
    }
    
    public var parameters: [URLQueryItem]? {
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
        case .accountDetails(_, let queryItems):
            return queryItems
        default:
            return nil
        }
    }
    
    public var httpBody: HTTPBody? {
        switch self {
        case .passwordChangeAnon(let request as Encodable), .passwordChange(let request as Encodable), .accountLookup(let request as Encodable), .recoverPassword(let request as Encodable), .budgetBillingUnenroll(_, let request as Encodable), .autoPayEnroll(_, let request as Encodable), .updateAutoPay(_, let request as Encodable), .autoPayEnrollBGE(_, let request as Encodable), .updateAutoPayBGE(accountNumber: _, let request as Encodable), .outageStatusAnon(let request as Encodable), .scheduledPayment(_, let request as Encodable), .billingHistory(_, let request as Encodable), .compareBill(_, _, let request as Encodable), .autoPayUnenroll(_, let request as Encodable), .scheduledPaymentUpdate(_, _, let request as Encodable), .homeProfileUpdate(_, _, let request as Encodable), .alertPreferencesUpdate(_, let request as Encodable), .updateGameUser(_, let request as Encodable), .setAccountNickname(let request as Encodable), .reportOutage(_, let request as Encodable), .reportOutageAnon(let request as Encodable), .recoverMaskedUsername(let request as Encodable), .recoverUsername(let request as Encodable), .validateRegistration(let request as Encodable), .checkDuplicateRegistration(let request as Encodable), .registration(let request as Encodable), .sendConfirmationEmail(let request as Encodable), .validateConfirmationEmail(let request as Encodable), .paperlessEnroll(_, let request as Encodable), .fetchDailyUsage(_, _, let request as Encodable), .registerForAlerts(let request as Encodable), .setAlertLanguage(_, let request as Encodable), .walletEncryptionKey(let request as Encodable), .wallet(let request as Encodable), .addWalletItem(let request as Encodable), .updateWalletItem(let request as Encodable), .deleteWalletItem(let request as Encodable), .scheduleOverride(_, _, _, let request as Encodable), .updateDeviceSettings(_, _, _, let request as Encodable), .updateThermostatSchedule(_, _, _, let request as Encodable), .fetchToken(let request as Encodable), .refreshToken(let request as Encodable), .meterPingAnon(let request as Encodable), .updateReleaseOfInfo(_, let request as Encodable), .scheduledPaymentDelete(_, _, let request as Encodable):
            return request.data()
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
        case .fetchToken, .refreshToken:
            return "TokenMock"
        case .accounts:
            return "AccountsMock"
        case .weather:
            return "WeatherMock"
        case .wallet:
            return "WalletMock"
        case .payments:
            return "PaymentsMock"
        case .alertBanner, .newsAndUpdates:
            return "AzureAlertsMock"
        case .billPDF:
            return "BillPDFMock"
        case .scheduledPayment, .scheduledPaymentUpdate, .scheduledPaymentDelete:
            return "ScheduledPaymentMock"
        case .billingHistory:
            return "BillingHistoryMock"
        case .walletEncryptionKey:
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
        case .iTronssoData:
            return "ItronSSODataMock"
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
        case .deleteWalletItem, .budgetBillingEnroll, .budgetBillingUnenroll, .paperlessEnroll, .paperlessUnenroll, .homeProfileUpdate, .alertPreferencesUpdate, .checkDuplicateRegistration, .sendConfirmationEmail, .validateConfirmationEmail, .registration, .recoverPassword, .passwordChangeAnon, .passwordChange, .fetchAlertLanguage, .setAlertLanguage:
            return "GenericResponseMock"
        case .validateRegistration:
            return "ValidateRegistrationMock"
        case .registrationQuestions:
            return "RegistrationQuestionsMock"
        case .fetchGameUser:
            return "FetchGameUserMock" // todo
        case .updateGameUser:
            return "UpdateGameUserMock" // todo
        case .fetchDailyUsage:
            return "DailyUsageMock"
        case .registerForAlerts: 
            return "RegisterForAlertsMock"
        case .peakRewardsSummary:
            return "PeakRewardsSummaryMock"
        case .peakRewardsOverrides:
            return "PeakRewardsOverridesMock"
        default:
            return ""
        }
    }
}
