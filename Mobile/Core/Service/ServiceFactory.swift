//
//  ServiceFactory.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

/// Utility class for intantiating Service Instances
class ServiceFactory {

    static let sharedOutageService = OMCOutageService()
    static let sharedMockOutageService = MockOutageService()

    class func createAuthenticationService() -> AuthenticationService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCAuthenticationService()
        case .aut:
            return MockAuthenticationService()
        }
    }

    class func createBiometricsService() -> BiometricsService {
        return BiometricsService()
    }

    class func createAccountService() -> AccountService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCAccountService()
        case .aut:
            return MockAccountService()
        }
    }

    class func createOutageService() -> OutageService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return sharedOutageService
        case .aut:
            return sharedMockOutageService
        }
    }

    class func createBillService() -> BillService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCBillService()
        case .aut:
            return MockBillService()
        }
    }

    class func createWalletService() -> WalletService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCWalletService()
        case .aut:
            return MockWalletService()
        }
    }

    class func createRegistrationService() -> RegistrationService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCRegistrationService()
        case .aut:
            return MockRegistrationService()
        }
    }

    class func createPaymentService() -> PaymentService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCPaymentService()
        case .aut:
            return MockPaymentService()
        }
    }

    class func createWeatherService() -> WeatherService {
        return WeatherAPI()
    }

    class func createUsageService() -> UsageService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCUsageService()
        case .aut:
            return MockUsageService()
        }
    }

    class func createAlertsService() -> AlertsService {
        switch(Environment.shared.environmentName) {
        case .dev, .stage, .prod:
            return OMCAlertsService()
        case .aut:
            return MockAlertsService()
        }
    }
    
    class func createPeakRewardsService() -> PeakRewardsService {
        return OMCPeakRewardsService()
    }
}
