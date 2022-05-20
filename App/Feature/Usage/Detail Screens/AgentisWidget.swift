//
//  AgentisWidget.swift
//  EUMobile
//
//  Created by Cody Dillon on 5/12/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation

enum AgentisWidget: String, CaseIterable {
    // residential
    case usage = "data-browser"
    case ser, pesc = "peak-time-rebate"
    
    // commercial
    case electricUsage = "electric-usage-chart-interval"
    case gasUsage = "gas-usage-chart-bill"
    case compareElectric = "electric-monthly-cost-chart-bill-type"
    case compareGas = "gas-monthly-cost-chart-bill-type"
    case electricTips = "electric-solutions"
    case gasTips = "gas-solutions"
    case projectedUsage = "projected_usage"
    
    var navigationTitle: String {
        switch self {
        case .usage:
            return "Usage Data"
        case .ser:
            return "Smart Energy Rewards"
        case .pesc:
            return "Peak Energy Savings History"
        case .electricUsage:
            return "My Electric Usage"
        case.gasUsage:
            return "My Gas Usage"
        case .compareElectric:
            return "Compare Electric Bills"
        case .compareGas:
            return "Compare Gas Bills"
        case .electricTips:
            return "View My Tips (Electric Only)"
        case .gasTips:
            return "View My Tips (Gas Only)"
        case.projectedUsage:
            return "Projected Usage"
        }
    }
    
    var identifier: String {
        switch self {
        case .usage:
            return "data-browser"
        case .ser, .pesc:
            return "peak-time-rebate"
        case .electricUsage:
            return Configuration.shared.opco == .ace ? "electric-usage-chart-bill" : "electric-usage-chart-interval"
        case .gasUsage:
            return "gas-usage-chart-bill"
        case .compareElectric:
            return "electric-monthly-cost-chart-bill-type"
        case .compareGas:
            return "gas-monthly-cost-chart-bill-type"
        case .electricTips:
            return "electric-solutions"
        case.gasTips:
            return "gas_solutions"
        case .projectedUsage:
            return "projected_usage"
        }
    }
}
