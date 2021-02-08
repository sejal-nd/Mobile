//
//  AlertPreferenceRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AlertPreferencesRequest: Encodable {
    let alertPreferenceRequests: [AlertRequest]
    
    enum CodingKeys: String, CodingKey {
        case alertPreferenceRequests = "alertPreferences"
    }
    
    public struct AlertRequest: Encodable {
        var isActive: Bool = true
        var type: String = "push"
        let programName: String
        var daysPrior: Int? = nil
        var alertThreshold: Int? = nil
    }
    
    init(alertPreferenceRequests: [AlertRequest]) {
        self.alertPreferenceRequests = alertPreferenceRequests
    }
    
    init(alertPreferences: AlertPreferences) {
        var preferences = [AlertRequest]()
        
        if !Configuration.shared.opco.isPHI {
            preferences.append(AlertRequest(isActive: alertPreferences.highUsage, programName: "High Usage Residential Alert",
                                                      alertThreshold: alertPreferences.alertThreshold))
            
            if let smartEnergyRewardsActive = alertPreferences.smartEnergyRewards {
                preferences.append(AlertRequest(isActive: smartEnergyRewardsActive, programName: "Energy Savings Day Alert"))
            }
            
            if let energySavingsDayResultsActive = alertPreferences.energySavingsDayResults {
                preferences.append(AlertRequest(isActive: energySavingsDayResultsActive, programName: "Energy Savings Day Results"))
            }
            
            if let peakTimeSavingsActuve = alertPreferences.peakTimeSavings {
                preferences.append(AlertRequest(isActive: peakTimeSavingsActuve, programName: "Peak Time Savings"))
            }
            
            preferences.append(AlertRequest(isActive: alertPreferences.outage, programName: "Outage Notifications"))
            preferences.append(AlertRequest(isActive: alertPreferences.scheduledMaint, programName: "Planned Outage"))
            preferences.append(AlertRequest(isActive: alertPreferences.severeWeather, programName: "Severe Weather"))
            
            if Configuration.shared.opco == .bge {
                preferences.append(AlertRequest(isActive: alertPreferences.billReady, programName: "Bill is Ready"))
            } else {
                preferences.append(AlertRequest(isActive: alertPreferences.billReady, programName: "Paperless Billing"))
            }
            
            if Configuration.shared.opco == .bge {
                preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.paymentDue, programName: "Payment Reminder", daysPrior: alertPreferences.paymentDueDaysBefore))
            } else {
                preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.paymentDue, programName: "Payment Reminders", daysPrior: alertPreferences.paymentDueDaysBefore))
            }
            
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.paymentPosted, programName: "Payment Posted"))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.paymentPastDue, programName: "Payment Past Due"))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.budgetBilling, programName: "Budget Billing"))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.appointmentTracking, programName: "Customer Appointments"))
            
            if Configuration.shared.opco == .bge {
                preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.forYourInfo, programName: "Marketing"))
            } else {
                preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.forYourInfo, programName: "News"))
            }
        }
        else {
            
            let opcoIdentifier = AccountsStore.shared.currentAccount.utilityCode?.uppercased() ?? Configuration.shared.opco.rawValue
            
            let outageProgramName = "Outage" + " " + opcoIdentifier
            let severeWeatherProgramName = "Severe Weather" + " " + opcoIdentifier
            let paymentDueProgramName = "Payment Reminder" + " " + opcoIdentifier
            let paymentPostedProgramName = "Payment Posted" + " " + opcoIdentifier
            let paymentPastDueProgramName = "Payment Past Due" + " " + opcoIdentifier
            let billReadyProgramName = "Bill is Ready" + " " + opcoIdentifier
            let budgetBillingProgramName = "Budget Billing" + " " + opcoIdentifier
            let forYourInfoProgramName = "News" + " " + opcoIdentifier
            
            preferences.append(AlertRequest(isActive: alertPreferences.outage, programName: outageProgramName))
            preferences.append(AlertRequest(isActive: alertPreferences.severeWeather, programName: severeWeatherProgramName))
            preferences.append(AlertRequest(isActive: alertPreferences.billReady, programName: billReadyProgramName))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.paymentDue, programName: paymentDueProgramName, daysPrior: alertPreferences.paymentDueDaysBefore))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.paymentPosted, programName: paymentPostedProgramName))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.paymentPastDue, programName: paymentPastDueProgramName))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.budgetBilling, programName: budgetBillingProgramName))
            preferences.append(AlertPreferencesRequest.AlertRequest(isActive: alertPreferences.forYourInfo, programName: forYourInfoProgramName))
        }
        
        alertPreferenceRequests = preferences
    }
}
