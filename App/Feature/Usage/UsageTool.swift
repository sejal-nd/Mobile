//
//  UsageTool.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

enum UsageTool {
    case usageData, energyTips, homeProfile, peakRewards, smartEnergyRewards, hourlyPricing, peakTimeSavings, energyWiseRewards, peakEnergySavings
    
    var title: String {
        switch self {
        case .usageData:
            return NSLocalizedString("View My Usage Data", comment: "")
        case .energyTips:
            return NSLocalizedString("Top 5 Energy Tips", comment: "")
        case .homeProfile:
            return NSLocalizedString("My Home Profile", comment: "")
        case .peakRewards:
            return NSLocalizedString("PeakRewards", comment: "")
        case .smartEnergyRewards:
            return NSLocalizedString("Smart Energy Rewards", comment: "")
        case .hourlyPricing:
            return NSLocalizedString("Hourly Pricing", comment: "")
        case .peakTimeSavings:
            return NSLocalizedString("Peak Time Savings", comment: "")
        case .energyWiseRewards:
            return NSLocalizedString("Energy Wise Rewards", comment: "")
        case .peakEnergySavings:
            return NSLocalizedString("Peak Energy Savings", comment: "")
        }
    }
    
    var icon: UIImage {
        switch self {
        case .usageData:
            return #imageLiteral(resourceName: "ic_usagedata")
        case .energyTips:
            return #imageLiteral(resourceName: "ic_Top5")
        case .homeProfile:
            return #imageLiteral(resourceName: "ic_house")
        case .peakRewards:
            return #imageLiteral(resourceName: "ic_thermostat")
        case .smartEnergyRewards:
            return #imageLiteral(resourceName: "ic_smartenergy")
        case .hourlyPricing:
            return #imageLiteral(resourceName: "ic_hourlypricing")
        case .peakTimeSavings:
            return #imageLiteral(resourceName: "ic_smartenergy")
        case .energyWiseRewards:
            return #imageLiteral(resourceName: "ic_phi_thermostat")
        case .peakEnergySavings:
            return #imageLiteral(resourceName: "ic_peaktimesavings")
        }
    }
}
