//
//  AlertPreferencesNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AlertPreferences: Decodable {
    var highUsage = false // BGE/ComEd only
    var alertThreshold: Int? // BGE/ComEd only
    var previousAlertThreshold: Int? // BGE/ComEd only
    var peakTimeSavings: Bool? = false // ComEd only
    var peakTimeSavingsDayResults: Bool? = false // PHI only
    var peakTimeSavingsDayAlert: Bool? = false // PHI only
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
    var advancedNotification = false
    var forYourInfo = false
    var grantStatus = false
    
    enum CodingKeys: String, CodingKey {
        case preferences = "alertPreferences"
        
        case highUsage
        case alertThreshold
        case previousAlertThreshold
        case peakTimeSavings
        case smartEnergyRewards
        case energySavingsDayResults
        case outage
        case scheduledMaint
        case severeWeather
        case billReady
        case paymentDue
        case paymentDueDaysBefore
        case paymentPosted
        case paymentPastDue
        case budgetBilling
        case appointmentTracking
        case advancedNotification
        case forYourInfo
        case grantStatus
        case peakTimeSavingsDayResults
        case peakTimeSavingsDayAlert
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let preferences = try container.decode([AlertPreference].self,
                                           forKey: .preferences)

        let opcoIdentifier = AccountsStore.shared.currentAccount.utilityCode?.uppercased() ?? Configuration.shared.opco.rawValue

        for preference in preferences {
            switch preference.programName.trimmingCharacters(in: .whitespaces) {
            case "High Usage Residential Alert", "High Usage Alert \(opcoIdentifier)":
                highUsage = true
                alertThreshold = preference.alertThreshold
            case "Energy Savings Day Alert":
                smartEnergyRewards = true
            case "Energy Savings Day Results":
                energySavingsDayResults = true
            case "Peak Time Savings":
                peakTimeSavings = true
            case "Peak Savings Day Results \(opcoIdentifier)":
                peakTimeSavingsDayResults = true
            case "PESC \(opcoIdentifier)":
                peakTimeSavingsDayAlert = true
            case "Outage Notifications", "Outage \(opcoIdentifier)":
                outage = true
            case "Planned Outage":
                scheduledMaint = true
            case "Severe Weather", "Severe Weather \(opcoIdentifier)":
                severeWeather = true
            case "Paperless Billing", "Bill is Ready", "Bill is Ready \(opcoIdentifier)":
                billReady = true
            case "Payment Reminder", "Payment Reminders", "Payment Reminder \(opcoIdentifier)":
                paymentDue = true
                if let daysBefore = preference.daysPrior {
                    paymentDueDaysBefore = daysBefore
                }
            case "Payment Posted", "Payment Posted \(opcoIdentifier)":
                paymentPosted = true
            case "Payment Past Due", "Payment Past Due \(opcoIdentifier)":
                paymentPastDue = true
            case "Budget Billing", "Budget Billing \(opcoIdentifier)":
                budgetBilling = true
            case "Customer Appointments", "Customer Appointments \(opcoIdentifier)":
                appointmentTracking = true
            case "Advance Notification", "Advance Notification \(opcoIdentifier)":
                advancedNotification = true
            case "News", "Marketing", "News \(opcoIdentifier)":
                forYourInfo = true
            case "Payment Assistance Grant Status":
                grantStatus = true
            default:
                break
            }
        }
    }
    
    public init(highUsage: Bool = false, alertThreshold: Int? = nil, previousAlertThreshold: Int? = nil, peakTimeSavings: Bool? = false, smartEnergyRewards: Bool? = false, energySavingsDayResults: Bool? = false, outage: Bool = false, scheduledMaint: Bool = false, severeWeather: Bool = false, billReady: Bool = false, paymentDue: Bool = false, paymentDueDaysBefore: Int = 1, paymentPosted: Bool = false, paymentPastDue: Bool = false, budgetBilling: Bool = false, appointmentTracking: Bool = false, advancedNotification: Bool = false, forYourInfo: Bool = false, peakTimeSavingsDayAlert: Bool = false, peakTimeSavingsDayResults: Bool = false, grantStatus: Bool = false) {
        self.highUsage = highUsage
        self.alertThreshold = alertThreshold
        self.previousAlertThreshold = previousAlertThreshold
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
        self.advancedNotification = advancedNotification
        self.forYourInfo = forYourInfo
        self.grantStatus = grantStatus
        self.peakTimeSavingsDayAlert = peakTimeSavingsDayAlert
        self.peakTimeSavingsDayResults = peakTimeSavingsDayResults
    }
    
    public struct AlertPreference: Decodable {
        public var programName: String
        public var type: String
        public var daysPrior: Int?
        public var alertThreshold: Int?
    }
}


// MARK: Legacy Logic

extension AlertPreferences {
    func isDifferent(fromOriginal originalPrefs: AlertPreferences) -> Bool {
        // Note: not checking paymentDueDaysBefore or alertThreshold here because those are compared for changes independently
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
        advancedNotification != originalPrefs.advancedNotification ||
        forYourInfo != originalPrefs.forYourInfo ||
        grantStatus != originalPrefs.grantStatus
    }
}
