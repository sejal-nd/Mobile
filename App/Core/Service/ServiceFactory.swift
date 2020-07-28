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

    static func createPaymentService() -> PaymentService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockPaymentService()
        default:
            return MCSPaymentService()
        }
    }

    static func createWeatherService() -> WeatherService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockWeatherService()
        default:
            return GovWeatherService()
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
        switch Environment.shared.environmentName {
        case .aut:
            return MockPeakRewardsService()
        default:
            return MCSPeakRewardsService()
        }
    }

    static func createAppointmentService() -> AppointmentService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockAppointmentService()
        default:
            return MCSAppointmentService()
        }
    }
    
    static func createGameService() -> GameService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockGameService()
        default:
            return MCSGameService()
        }
    }
}
