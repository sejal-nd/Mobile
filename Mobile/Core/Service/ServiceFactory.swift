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
        switch(Environment.sharedInstance.environmentName) {
        case "DEV", "TEST", "STAGE", "PROD":
            return OMCAuthenticationService()
        case "AUT":
            return MockAuthenticationService()
        default:
            return OMCAuthenticationService()
        }
    }

    class func createBiometricsService() -> BiometricsService {
        return BiometricsService()
    }

    class func createAccountService() -> AccountService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return MockAccountService()
        }
        return OMCAccountService()
    }

    class func createOutageService() -> OutageService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return sharedMockOutageService
        }
        return sharedOutageService
    }

    class func createBillService() -> BillService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return MockBillService()
        }
        return OMCBillService()
    }

    class func createWalletService() -> WalletService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return MockWalletService()
        }
        return OMCWalletService()
    }

    class func createRegistrationService() -> RegistrationService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return MockRegistrationService()
        }
        return OMCRegistrationService()
    }

    class func createPaymentService() -> PaymentService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return MockPaymentService()
        }
        return OMCPaymentService()
    }

    class func createWeatherService() -> WeatherService {
        return WeatherAPI()
    }

    class func createUsageService() -> UsageService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return MockUsageService()
        }
        return OMCUsageService()
    }

    class func createAlertsService() -> AlertsService {
        if Environment.sharedInstance.environmentName == "AUT" {
            return MockAlertsService()
        }
        return OMCAlertsService()
    }
    
    class func createPeakRewardsService() -> PeakRewardsService {
        return OMCPeakRewardsService()
    }
}
