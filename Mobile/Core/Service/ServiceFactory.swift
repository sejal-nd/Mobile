//
//  ServiceFactory.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

/// Utility class for intantiating Service Instances
struct ServiceFactory {

    static let sharedOutageService = MCSOutageService()
    static let sharedMockOutageService = MockOutageService()

    static func createAuthenticationService() -> AuthenticationService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAuthenticationService()
        default:
            return MCSAuthenticationService()
        }
    }

    static func createBiometricsService() -> BiometricsService {
        return BiometricsService()
    }

    static func createAccountService() -> AccountService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAccountService()
        default:
            return MCSAccountService()
        }
    }

    static func createOutageService() -> OutageService {
        switch Environment.shared.environmentName {
        case .aut:
            return sharedMockOutageService
        default:
            return sharedOutageService
        }
    }

    static func createBillService() -> BillService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockBillService()
        default:
            return MCSBillService()
        }
    }

    static func createWalletService() -> WalletService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockWalletService()
        default:
            return MCSWalletService()
        }
    }

    static func createRegistrationService() -> RegistrationService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockRegistrationService()
        default:
            return MCSRegistrationService()
        }
    }

    static func createPaymentService() -> PaymentService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockPaymentService()
        default:
            return MCSPaymentService()
        }
    }

    class func createWeatherService() -> WeatherService {
        return WeatherApi()
    }

    static func createUsageService(useCache: Bool) -> UsageService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockUsageService(useCache: useCache)
        default:
            return MCSUsageService(useCache: useCache)
        }
    }

    static func createAlertsService() -> AlertsService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAlertsService()
        default:
            return MCSAlertsService()
        }
    }

    static func createPeakRewardsService() -> PeakRewardsService {
        return MCSPeakRewardsService()
    }

    static func createAppointmentService() -> AppointmentService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAppointmentService()
        default:
            return MCSAppointmentService()
        }
    }
}
