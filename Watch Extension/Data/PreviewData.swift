//
//  PreviewData.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

enum PreviewData { }

// MARK: Account

extension PreviewData {
    static let accounts = [
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere…",
                     isResidential: true),
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere 10 Anywhere 10 Anywhere",
                     isResidential: false),
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere 10 Anywhere 10 Anywhere",
                     isResidential: true)
    ]
}

// MARK: Outage

extension PreviewData {
    static let outageOn = WatchOutage(isPowerOn: true)
    
    static let outageOff = WatchOutage(isPowerOn: false,
                                       estimatedRestoration: "10:30AM 10/09/2018")
}

// MARK: Usage

extension PreviewData {
    // Electric
    static let usageElectricModeled = WatchUsage(fuelTypes: [.electric],
                                                 electricUsageCost: "$80",
                                                 electricProjetedUsageCost: "$120",
                                                 electricBillPeriod: "May 24 - Jun 19",
                                                 electricProgress: 65.0)
    
    static let usageElectricUnmodeled = WatchUsage(fuelTypes: [.electric],
                                                   electricUsageCost: "21 kWh",
                                                   electricProjetedUsageCost: "36 kWh",
                                                   electricBillPeriod: "May 24 - Jun 19",
                                                   electricProgress: 65.0)
    
    static let usageElectricUnforecasted = WatchUsage(fuelTypes: [.electric],
                                                      electricTimeToNextForecast: "5 Days")
    
    // Gas
    static let usageGasModeled = WatchUsage(fuelTypes: [.gas],
                                            gasUsageCost: "$80",
                                            gasProjetedUsageCost: "$120",
                                            gasBillPeriod: "May 24 - Jun 19",
                                            gasProgress: 65.0)
    
    static let usageGasUnmodeled = WatchUsage(fuelTypes: [.gas],
                                              gasUsageCost: "21 kWh",
                                              gasProjetedUsageCost: "36 kWh",
                                              gasBillPeriod: "May 24 - Jun 19",
                                              gasProgress: 65.0)
    
    static let usageGasUnforecasted = WatchUsage(fuelTypes: [.gas],
                                                 gasTimeToNextForecast: "5 Days")
    
    // Both
    static let usageGasAndElectricModeled = WatchUsage(fuelTypes: [.electric, .gas],
                                                       electricUsageCost: "$80",
                                                       electricProjetedUsageCost: "$120",
                                                       electricBillPeriod: "May 24 - Jun 19",
                                                       electricProgress: 65.0,
                                                       gasUsageCost: "$120",
                                                       gasProjetedUsageCost: "$160",
                                                       gasBillPeriod: "May 29 - Jun 25",
                                                       gasProgress: 40)
    
    static let usageGasAndElectricUnmodeled = WatchUsage(fuelTypes: [.electric, .gas],
                                                         electricUsageCost: "80 kWh",
                                                         electricProjetedUsageCost: "120 kWh",
                                                         electricBillPeriod: "May 24 - Jun 19",
                                                         electricProgress: 65.0,
                                                         gasUsageCost: "120 CCF",
                                                         gasProjetedUsageCost: "160 CCF",
                                                         gasBillPeriod: "May 29 - Jun 25",
                                                         gasProgress: 40)
    
    static let usageGasAndElectricUnforecasted = WatchUsage(fuelTypes: [.electric, .gas],
                                                            electricTimeToNextForecast: "3 Days",
                                                            gasTimeToNextForecast: "1 Day")
}
