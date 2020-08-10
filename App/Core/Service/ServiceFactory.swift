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

    static func createPeakRewardsService() -> PeakRewardsService {
        switch Environment.shared.environmentName {
        case .aut:
            return MockPeakRewardsService()
        default:
            return MCSPeakRewardsService()
        }
    }
}
