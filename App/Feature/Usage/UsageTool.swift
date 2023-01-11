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
            return NSLocalizedString("Adjust Thermostat", comment: "")
        case .peakEnergySavings:
            return NSLocalizedString("Peak Energy Savings", comment: "")
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .usageData:
            return UIImage(named: "ic_usagedata")
        case .energyTips:
            return UIImage(named: "ic_top5tips")
        case .homeProfile:
            return UIImage(named: "ic_homeprofile")
        case .peakRewards:
            return UIImage(named: "ic_thermostat")
        case .smartEnergyRewards:
            return UIImage(named: "ic_smartenergy")
        case .hourlyPricing:
            return UIImage(named: "ic_hourlypricing")
        case .peakTimeSavings:
            return UIImage(named: "ic_smartenergy")
        case .energyWiseRewards:
            return UIImage(named: "ic_thermostat")
        case .peakEnergySavings:
            return UIImage(named: "ic_peaktimesavings")
        }
    }
}
