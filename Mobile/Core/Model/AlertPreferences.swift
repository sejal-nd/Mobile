//
//  AlertPreferences.swift
//  Mobile
//
//  Created by Marc Shilling on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct AlertPreferences {
    var highUsage = false // BGE/ComEd only
    var alertThreshold: Int? // BGE/ComEd only
    var peakTimeSavings: Bool? = false // ComEd only
    var smartEnergyRewards: Bool? = false // BGE only
    var energySavingsDayResults: Bool? = false // BGE only
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
            case "High Usage Alert":
                highUsage = true
                alertThreshold = pref.alertThreshold
            case "Energy Savings Day Alert":
                smartEnergyRewards = true
            case "Energy Savings Day Results":
                energySavingsDayResults = true
            case "Peak Time Savings":
                peakTimeSavings = true
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
    init(highUsage: Bool,
         alertThreshold: Int? = nil,
         peakTimeSavings: Bool? = nil,
         smartEnergyRewards: Bool? = nil,
         energySavingsDayResults: Bool? = nil,
         outage: Bool,
         scheduledMaint: Bool,
         severeWeather: Bool,
         billReady: Bool,
         paymentDue: Bool,
         paymentDueDaysBefore: Int,
         paymentPosted: Bool,
         paymentPastDue: Bool,
         budgetBilling: Bool,
         appointmentTracking: Bool,
         forYourInfo: Bool) {
        self.highUsage = highUsage
        self.alertThreshold = alertThreshold
        self.peakTimeSavings = peakTimeSavings
        self.smartEnergyRewards = smartEnergyRewards
        self.energySavingsDayResults = energySavingsDayResults
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
    }
    
    // Used by the setAlertPreferences web service call
    func createAlertPreferencesJSONArray() -> [[String: Any]] {
        let billReadyProgramName = Environment.shared.opco == .bge ? "Bill is Ready" : "Paperless Billing"
        let paymentDueProgramName = Environment.shared.opco == .bge ? "Payment Reminder" : "Payment Reminders"
        let forYourInfoProgramName = Environment.shared.opco == .bge ? "Marketing" : "News"
        let highUsageProgramName = "High Usage Alert"
        
        var highUsageProgram = ["programName": highUsageProgramName, "type": "push", "isActive": highUsage] as [String : Any]
        if let billThreshold = alertThreshold {
            highUsageProgram["alertThreshold"] = billThreshold
        }
        
        var array = [
            highUsageProgram,
            ["programName": "Outage Notifications", "type": "push", "isActive": outage],
            ["programName": "Planned Outage", "type": "push", "isActive": scheduledMaint],
            ["programName": "Severe Weather", "type": "push", "isActive": severeWeather],
            ["programName": billReadyProgramName, "type": "push", "isActive": billReady],
            ["programName": paymentDueProgramName, "type": "push", "isActive": paymentDue, "daysPrior": paymentDueDaysBefore],
            ["programName": "Payment Posted", "type": "push", "isActive": paymentPosted],
            ["programName": "Payment Past Due", "type": "push", "isActive": paymentPastDue],
            ["programName": "Budget Billing", "type": "push", "isActive": budgetBilling],
            ["programName": "Customer Appointments", "type": "push", "isActive": appointmentTracking],
            ["programName": forYourInfoProgramName, "type": "push", "isActive": forYourInfo]
        ]
        
        if let peakTimeSavings = peakTimeSavings {
            array.append(["programName": "Peak Time Savings", "type": "push", "isActive": peakTimeSavings])
        }
        
        if let smartEnergyRewards = smartEnergyRewards {
            array.append(["programName": "Energy Savings Day Alert", "type": "push", "isActive": smartEnergyRewards])
        }
        
        if let energySavingsDayResults = energySavingsDayResults {
            array.append(["programName": "Energy Savings Day Results", "type": "push", "isActive": energySavingsDayResults])
        }
        
        return array
    }
    
    func isDifferent(fromOriginal originalPrefs: AlertPreferences) -> Bool {
        // Note: not checking paymentDueDaysBefore here because that is compared for changes independently
        // in AlertPreferencesViewModel
        return highUsage != originalPrefs.highUsage ||
            peakTimeSavings != originalPrefs.peakTimeSavings ||
            smartEnergyRewards != originalPrefs.smartEnergyRewards ||
            energySavingsDayResults != originalPrefs.energySavingsDayResults ||
            outage != originalPrefs.outage ||
            scheduledMaint != originalPrefs.scheduledMaint ||
            severeWeather != originalPrefs.severeWeather ||
            billReady != originalPrefs.billReady ||
            paymentDue != originalPrefs.paymentDue ||
            paymentPosted != originalPrefs.paymentPosted ||
            paymentPastDue != originalPrefs.paymentPastDue ||
            budgetBilling != originalPrefs.budgetBilling ||
            appointmentTracking != originalPrefs.appointmentTracking ||
            forYourInfo != originalPrefs.forYourInfo
    }
}

struct AlertPreference: Mappable {
    let programName: String
    var daysPrior: Int? // Only sent along with programName = "Payment Reminders"
    var alertThreshold: Int? // Only sent along with programName = "High Usage Alert"
    
    init(map: Mapper) throws {
        try programName = map.from("programName")
        
        daysPrior = map.optionalFrom("daysPrior") // ComEd/PECO send daysPrior as an Int
        
        // But BGE sends as a String, so handle both cases
        let daysString: String? = map.optionalFrom("daysPrior")
        if let string = daysString {
            daysPrior = Int(string)
        }
        
        alertThreshold = map.optionalFrom("alertThreshold")
    }
}
