//
//  AlertPreferences.swift
//  Mobile
//
//  Created by Marc Shilling on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct AlertPreferences {
    var usage = false
    var alertThreshold: Int?
    var outage = false
    var scheduledMaint = false // BGE only
    var severeWeather = false
    var billReady = false
    var paymentDue = false
    var paymentDueDaysBefore = 1
    var paymentPosted = false
    var paymentPastDue = false
    var budgetBilling = false // ComEd/PECO only
    var appointmentTracking = false
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
            case "Payment Posted":
                paymentPosted = true
            case "Payment Past Due":
                paymentPastDue = true
            case "Budget Billing":
                budgetBilling = true
            case "Customer Appointments":
                appointmentTracking = true
            case "News", "Marketing":
                forYourInfo = true
            default:
                break
            }
        }
    }
    
    // To create programatically, not from JSON
    init(outage: Bool,
         scheduledMaint: Bool,
         severeWeather: Bool,
         billReady: Bool,
         paymentDue: Bool,
         paymentDueDaysBefore: Int,
         paymentPosted: Bool,
         paymentPastDue: Bool,
         budgetBilling: Bool,
         appointmentTracking: Bool,
         forYourInfo: Bool,
         usage: Bool,
         alertThreshold: Int? = nil) {
        self.outage = outage
        self.scheduledMaint = scheduledMaint
        self.severeWeather = severeWeather
        self.billReady = billReady
        self.paymentDue = paymentDue
        self.paymentDueDaysBefore = paymentDueDaysBefore
        self.paymentPosted = paymentPosted
        self.paymentPastDue = paymentPastDue
        self.budgetBilling = budgetBilling
        self.appointmentTracking = appointmentTracking
        self.forYourInfo = forYourInfo
        self.usage = usage
        self.alertThreshold = alertThreshold
    }
    
    // Used by the setAlertPreferences web service call
    func createAlertPreferencesJSONArray() -> [[String: Any]] {
        let billReadyProgramName = Environment.shared.opco == .bge ? "Bill is Ready" : "Paperless Billing"
        let paymentDueProgramName = Environment.shared.opco == .bge ? "Payment Reminder" : "Payment Reminders"
        let forYourInfoProgramName = Environment.shared.opco == .bge ? "Marketing" : "News"
        let highUsageProgramName = Environment.shared.opco == .comEd ? "High Usage Electric" : "High Usage Electric Alerts"
        
        var highUsageProgram = ["programName": highUsageProgramName, "type": "push", "isActive": usage] as [String : Any]
        if let billThreshold = alertThreshold {
            highUsageProgram["alertThreshold"] = billThreshold
        }
        
        let array = [
            ["programName": "Outage Notifications", "type": "push", "isActive": outage],
            ["programName": "Planned Outage", "type": "push", "isActive": scheduledMaint],
            ["programName": "Severe Weather", "type": "push", "isActive": severeWeather],
            ["programName": billReadyProgramName, "type": "push", "isActive": billReady],
            ["programName": paymentDueProgramName, "type": "push", "isActive": paymentDue, "daysPrior": paymentDueDaysBefore],
            ["programName": "Payment Posted", "type": "push", "isActive": paymentPosted],
            ["programName": "Payment Past Due", "type": "push", "isActive": paymentPastDue],
            ["programName": "Budget Billing", "type": "push", "isActive": budgetBilling],
            ["programName": "Customer Appointments", "type": "push", "isActive": appointmentTracking],
            ["programName": forYourInfoProgramName, "type": "push", "isActive": forYourInfo],
            highUsageProgram
        ]
        return array
    }
    
    func isDifferent(fromOriginal originalPrefs: AlertPreferences) -> Bool {
        // Note: not checking paymentDueDaysBefore here because that is compared for changes independently
        // in AlertPreferencesViewModel
        return outage != originalPrefs.outage ||
            scheduledMaint != originalPrefs.scheduledMaint ||
            severeWeather != originalPrefs.severeWeather ||
            billReady != originalPrefs.billReady ||
            paymentDue != originalPrefs.paymentDue ||
            paymentPosted != originalPrefs.paymentPosted ||
            paymentPastDue != originalPrefs.paymentPastDue ||
            budgetBilling != originalPrefs.budgetBilling ||
            appointmentTracking != originalPrefs.appointmentTracking ||
            forYourInfo != originalPrefs.forYourInfo ||
            usage != originalPrefs.usage
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
