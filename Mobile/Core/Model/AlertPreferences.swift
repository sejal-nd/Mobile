//
//  AlertPreferences.swift
//  Mobile
//
//  Created by Marc Shilling on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct AlertPreferences {
    var outage = false
    var scheduledMaint = false // BGE only
    var severeWeather = false
    var billReady = false
    var paymentDue = false
    var paymentDueDaysBefore = 1
    var budgetBilling = false // ComEd/PECO only
    var forYourInfo = false
    
    init(alertPreferences: [AlertPreference]) {
        for pref in alertPreferences {
            switch pref.programName {
            case "Outage Notifications":
                outage = true
            case "Planned Outage":
                scheduledMaint = true
            case "Severe Weather":
                severeWeather = true
            case "Paperless Billing", "Bill is Ready":
                billReady = true
            case "Payment Reminder", "Payment Reminders":
                paymentDue = true
                if let daysBefore = pref.daysPrior {
                    paymentDueDaysBefore = daysBefore
                }
            case "Budget Billing":
                budgetBilling = true
            case "News", "Marketing":
                forYourInfo = true
            default:
                break
            }
        }
    }
    
}

struct AlertPreference: Mappable {
    let programName: String
    let daysPrior: Int? // Only sent along with programName = "Payment Reminders"
    
    init(map: Mapper) throws {
        try programName = map.from("programName")
        daysPrior = map.optionalFrom("daysPrior")
    }
}
