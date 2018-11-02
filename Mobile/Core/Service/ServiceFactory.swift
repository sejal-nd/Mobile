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

    static let sharedOutageService = MCSOutageService()
    static let sharedMockOutageService = MockOutageService()

    class func createAuthenticationService() -> AuthenticationService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSAuthenticationService()
        case .aut:
            return MockAuthenticationService()
        }
    }

    class func createBiometricsService() -> BiometricsService {
        return BiometricsService()
    }

    class func createAccountService() -> AccountService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSAccountService()
        case .aut:
            return MockAccountService()
        }
    }

    class func createOutageService() -> OutageService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return sharedOutageService
        case .aut:
            return sharedMockOutageService
        }
    }

    class func createBillService() -> BillService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSBillService()
        case .aut:
            return MockBillService()
        }
    }

    class func createWalletService() -> WalletService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSWalletService()
        case .aut:
            return MockWalletService()
        }
    }

    class func createRegistrationService() -> RegistrationService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSRegistrationService()
        case .aut:
            return MockRegistrationService()
        }
    }

    class func createPaymentService() -> PaymentService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSPaymentService()
        case .aut:
            return MockPaymentService()
        }
    }

    class func createWeatherService() -> WeatherService {
        return WeatherAPI()
    }

    class func createUsageService() -> UsageService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSUsageService()
        case .aut:
            return MockUsageService()
        }
    }

    class func createAlertsService() -> AlertsService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSAlertsService()
        case .aut:
            return MockAlertsService()
        }
    }
    
    class func createPeakRewardsService() -> PeakRewardsService {
        return MCSPeakRewardsService()
    }
    
    class func createAppointmentService() -> AppointmentService {
        switch Environment.shared.environmentName {
        case .dev, .stage, .prod:
            return MCSAppointmentService()
        case .aut:
            return MockAppointmentService()
        }
    }
}
