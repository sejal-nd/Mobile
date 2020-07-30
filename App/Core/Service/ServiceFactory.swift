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

    static func createGameService() -> GameService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockGameService()
        default:
            return MCSGameService()
        }
    }
}
