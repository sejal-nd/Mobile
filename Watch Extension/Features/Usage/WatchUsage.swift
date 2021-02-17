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
                  electricProgress: Int = 0,
                  electricTimeToNextForecast: String? = nil,
                  gasUsageCost: String? = nil,
                  gasProjetedUsageCost: String? = nil,
                  gasBillPeriod: String? = nil,
                  gasProgress: Int = 0,
                  gasTimeToNextForecast: String? = nil) {
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
    }
    
    init(accountDetails: AccountDetail,
         daysToNextForecast: Int = 0,
         billForecastResult: BillForecastResult?) {
        
        var forecastTypes = [FuelType]()
        if let billForecast = billForecastResult?.electric {
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
                let value = toDateCost / projectedCost
                let progress = value.isNaN ? 0 : Int(floor(value * 100))
                self.gasProgress = progress
            } else if let toDateUsage = billForecast.toDateUsage,
                      let projectedUsage = billForecast.projectedUsage {
                
                // Set Image
                let value = toDateUsage / projectedUsage
                let progress = value.isNaN ? 0 : Int(floor(value * 100))
                self.gasProgress = progress
            }
            
            if daysToNextForecast == 1 {
                self.electricTimeToNextForecast = "\(daysToNextForecast) day"
            } else {
                self.electricTimeToNextForecast = "\(daysToNextForecast) days"
            }
        } else if let billForecast = billForecastResult?.gas {
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
                let value = toDateCost / projectedCost
                let progress = value.isNaN ? 0 : Int(floor(value * 100))
                self.gasProgress = progress
            } else if let toDateUsage = billForecast.toDateUsage,
                      let projectedUsage = billForecast.projectedUsage {
                
                // Set Image
                let value = toDateUsage / projectedUsage
                let progress = value.isNaN ? 0 : Int(floor(value * 100))
                self.gasProgress = progress
            }
            
            if daysToNextForecast == 1 {
                self.gasTimeToNextForecast = "\(daysToNextForecast) day"
            } else {
                self.gasTimeToNextForecast = "\(daysToNextForecast) days"
            }
        }
        
        self.fuelTypes = forecastTypes
        self.billForecastResult = billForecastResult
    }
    
    var id: UUID = UUID()
    let fuelTypes: [FuelType]
    
    var electricUsageCost: String? = nil
    var electricProjetedUsageCost: String? = nil
    var electricBillPeriod: String? = nil
    var electricProgress: Int = 0
    var electricTimeToNextForecast: String? = nil
    
    var gasUsageCost: String? = nil
    var gasProjetedUsageCost: String? = nil
    var gasBillPeriod: String? = nil
    var gasProgress: Int = 0
    var gasTimeToNextForecast: String? = nil
    
    var billForecastResult: BillForecastResult? = nil
}

extension WatchUsage: Equatable {
    static func == (lhs: WatchUsage, rhs: WatchUsage) -> Bool {
        lhs.id == rhs.id
    }
}
