//
//  WatchUsage.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct WatchUsage: Identifiable {
    internal init(fuelTypes: [FuelType],
                  electricUsageCost: String? = nil,
                  electricProjetedUsageCost: String? = nil,
                  electricBillPeriod: String? = nil,
                  electricProgress: Double = 0.0,
                  electricTimeToNextForecast: String? = nil,
                  gasUsageCost: String? = nil,
                  gasProjetedUsageCost: String? = nil,
                  gasBillPeriod: String? = nil,
                  gasProgress: Double = 0.0,
                  gasTimeToNextForecast: String? = nil,
                  electricBillForecast: BillForecast? = nil,
                  gasBillForecast: BillForecast? = nil) {
        self.fuelTypes = fuelTypes
        self.electricUsageCost = electricUsageCost
        self.electricProjetedUsageCost = electricProjetedUsageCost
        self.electricBillPeriod = electricBillPeriod
        self.electricProgress = electricProgress
        self.electricTimeToNextForecast = electricTimeToNextForecast
        self.gasUsageCost = gasUsageCost
        self.gasProjetedUsageCost = gasProjetedUsageCost
        self.gasBillPeriod = gasBillPeriod
        self.gasProgress = gasProgress
        self.gasTimeToNextForecast = gasTimeToNextForecast
        self.electricBillForecast = electricBillForecast
        self.gasBillForecast = gasBillForecast
    }
    
    init(accountDetails: AccountDetail,
         daysToNextForecast: Int = 0,
         electricBillForecast: BillForecast?,
         gasBillForecast: BillForecast?) {
        
        var forecastTypes = [FuelType]()
        if let billForecast = electricBillForecast {
            forecastTypes.append(.electric)
            
            if accountDetails.isModeledForOpower,
               let toDateCost = billForecast.toDateCost {
                self.electricUsageCost = toDateCost.currencyString
            } else if let toDateUsage = billForecast.toDateUsage {
                self.electricUsageCost = "\(Int(toDateUsage)) \(billForecast.meterUnit)"
            }
            
            if accountDetails.isModeledForOpower,
               let projectedBillCost = billForecast.projectedCost {
                self.electricProjetedUsageCost = "\(projectedBillCost.currencyString)"
            } else if let projectedUsage = billForecast.projectedUsage {
                self.electricProjetedUsageCost = "\(Int(projectedUsage)) \(billForecast.meterUnit)"
            }
            
            if let billingStartDate = billForecast.billingStartDate,
               let billingEndDate = billForecast.billingEndDate {
                self.electricBillPeriod = "\(billingStartDate.shortMonthAndDayString) - \(billingEndDate.shortMonthAndDayString)"
            }
            
            if accountDetails.isModeledForOpower,
               let toDateCost = billForecast.toDateCost,
               let projectedCost = billForecast.projectedCost {
                
                // Set Image
                let progress = toDateCost / projectedCost
                self.electricProgress = progress.isNaN ? 0.0 : progress // handle division by 0
            } else if let toDateUsage = billForecast.toDateUsage,
                      let projectedUsage = billForecast.projectedUsage {
                
                // Set Image
                let progress = toDateUsage / projectedUsage
                self.electricProgress = progress.isNaN ? 0.0 : progress // handle division by 0
            }
            
            if daysToNextForecast == 1 {
                self.electricTimeToNextForecast = "\(daysToNextForecast) day"
            } else {
                self.electricTimeToNextForecast = "\(daysToNextForecast) days"
            }
        } else if let billForecast = gasBillForecast {
            forecastTypes.append(.gas)
            
            if accountDetails.isModeledForOpower,
               let toDateCost = billForecast.toDateCost {
                self.gasUsageCost = toDateCost.currencyString
            } else if let toDateUsage = billForecast.toDateUsage {
                self.gasUsageCost = "\(Int(toDateUsage)) \(billForecast.meterUnit)"
            }
            
            if accountDetails.isModeledForOpower,
               let projectedBillCost = billForecast.projectedCost {
                self.gasProjetedUsageCost = "\(projectedBillCost.currencyString)"
            } else if let projectedUsage = billForecast.projectedUsage {
                self.gasProjetedUsageCost = "\(Int(projectedUsage)) \(billForecast.meterUnit)"
            }
            
            if let billingStartDate = billForecast.billingStartDate,
               let billingEndDate = billForecast.billingEndDate {
                self.gasBillPeriod = "\(billingStartDate.shortMonthAndDayString) - \(billingEndDate.shortMonthAndDayString)"
            }
            
            if accountDetails.isModeledForOpower,
               let toDateCost = billForecast.toDateCost,
               let projectedCost = billForecast.projectedCost {
                
                // Set Image
                let progress = toDateCost / projectedCost
                self.gasProgress = progress.isNaN ? 0.0 : progress // handle division by 0
            } else if let toDateUsage = billForecast.toDateUsage,
                      let projectedUsage = billForecast.projectedUsage {
                
                // Set Image
                let progress = toDateUsage / projectedUsage
                self.gasProgress = progress.isNaN ? 0.0 : progress // handle division by 0
            }
            
            if daysToNextForecast == 1 {
                self.gasTimeToNextForecast = "\(daysToNextForecast) day"
            } else {
                self.gasTimeToNextForecast = "\(daysToNextForecast) days"
            }
        }
        
        self.fuelTypes = forecastTypes
        self.electricBillForecast = electricBillForecast
        self.gasBillForecast = gasBillForecast
    }
    
    var id: UUID = UUID()
    let fuelTypes: [FuelType]
    
    var electricUsageCost: String? = nil
    var electricProjetedUsageCost: String? = nil
    var electricBillPeriod: String? = nil
    var electricProgress: Double = 0.0
    var electricTimeToNextForecast: String? = nil
    
    var gasUsageCost: String? = nil
    var gasProjetedUsageCost: String? = nil
    var gasBillPeriod: String? = nil
    var gasProgress: Double = 0.0
    var gasTimeToNextForecast: String? = nil
    
    var electricBillForecast: BillForecast? = nil
    var gasBillForecast: BillForecast? = nil
}

extension WatchUsage: Equatable {
    static func == (lhs: WatchUsage, rhs: WatchUsage) -> Bool {
        lhs.id == rhs.id
    }
}
