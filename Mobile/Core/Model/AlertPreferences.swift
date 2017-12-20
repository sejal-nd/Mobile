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
    
    // To create programatically, not from JSON
    init(outage: Bool, scheduledMaint: Bool, severeWeather: Bool, billReady: Bool, paymentDue: Bool, paymentDueDaysBefore: Int, budgetBilling: Bool, forYourInfo: Bool) {
        self.outage = outage
        self.scheduledMaint = scheduledMaint
        self.severeWeather = severeWeather
        self.billReady = billReady
        self.paymentDue = paymentDue
        self.paymentDueDaysBefore = paymentDueDaysBefore
        self.budgetBilling = budgetBilling
        self.forYourInfo = forYourInfo
    }
    
    // Used by the setAlertPreferences web service call
    func createAlertPreferencesJSONArray() -> [[String: Any]] {
        let billReadyProgramName = Environment.sharedInstance.opco == .bge ? "Bill is Ready" : "Paperless Billing"
        let paymentDueProgramName = Environment.sharedInstance.opco == .bge ? "Payment Reminder" : "Payment Reminders"
        let forYourInfoProgramName = Environment.sharedInstance.opco == .bge ? "Marketing" : "News"
        let array = [
            ["programName": "Outage Notifications", "type": "push", "isActive": outage],
            ["programName": "Planned Outage", "type": "push", "isActive": scheduledMaint],
            ["programName": "Severe Weather", "type": "push", "isActive": severeWeather],
            ["programName": billReadyProgramName, "type": "push", "isActive": billReady],
            ["programName": paymentDueProgramName, "type": "push", "isActive": paymentDue, "daysPrior": paymentDueDaysBefore],
            ["programName": "Budget Billing", "type": "push", "isActive": budgetBilling],
            ["programName": forYourInfoProgramName, "type": "push", "isActive": forYourInfo]
        ]
        return array
    }
    
}

struct AlertPreference: Mappable {
    let programName: String
    var daysPrior: Int? // Only sent along with programName = "Payment Reminders"
    
    init(map: Mapper) throws {
        try programName = map.from("programName")
        
        daysPrior = map.optionalFrom("daysPrior") // ComEd/PECO send daysPrior as an Int
        
        // But BGE sends as a String, so handle both cases
        let daysString: String? = map.optionalFrom("daysPrior")
        if let string = daysString {
            daysPrior = Int(string)
        }
    }
}
