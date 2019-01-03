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
        case .aut:
            return MockAuthenticationService()
        default:
            return MCSAuthenticationService()
        }
    }

    class func createBiometricsService() -> BiometricsService {
        return BiometricsService()
    }

    class func createAccountService() -> AccountService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAccountService()
        default:
            return MCSAccountService()
        }
    }

    class func createOutageService() -> OutageService {
        switch Environment.shared.environmentName {
        case .aut:
            return sharedMockOutageService
        default:
            return sharedOutageService
        }
    }

    class func createBillService() -> BillService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockBillService()
        default:
            return MCSBillService()
        }
    }

    class func createWalletService() -> WalletService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockWalletService()
        default:
            return MCSWalletService()
        }
    }

    class func createRegistrationService() -> RegistrationService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockRegistrationService()
        default:
            return MCSRegistrationService()
        }
    }

    class func createPaymentService() -> PaymentService {
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

    class func createUsageService() -> UsageService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockUsageService()
        default:
            return MCSUsageService()
        }
    }

    class func createAlertsService() -> AlertsService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAlertsService()
        default:
            return MCSAlertsService()
        }
    }
    
    class func createPeakRewardsService() -> PeakRewardsService {
        return MCSPeakRewardsService()
    }
    
    class func createAppointmentService() -> AppointmentService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAppointmentService()
        default:
            return MCSAppointmentService()
        }
    }
}
