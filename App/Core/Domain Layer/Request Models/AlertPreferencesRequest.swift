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
        case alertPreferenceRequests = "alertPreferenceRequests"
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
        
        if alertPreferences.highUsage {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "High Usage Residential Alert",
                                                      alertThreshold: alertPreferences.alertThreshold))
        }
        
        if alertPreferences.smartEnergyRewards ?? false {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Energy Savings Day Alert"))
        }
        
        if alertPreferences.energySavingsDayResults ?? false {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Energy Savings Day Results"))
        }
        
        if alertPreferences.peakTimeSavings ?? false {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Peak Time Savings"))
        }
        
        if alertPreferences.outage {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Outage Notifications"))
        }
        
        if alertPreferences.scheduledMaint {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Planned Outage"))
        }
        
        if alertPreferences.severeWeather {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Severe Weather"))
        }
        
        if alertPreferences.billReady {
            if Environment.shared.opco == .bge {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Paperless Billing"))
            } else {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Bill is Ready"))
            }
        }
        
        if alertPreferences.paymentDue {
            if Environment.shared.opco == .bge {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Payment Reminder", daysPrior: alertPreferences.paymentDueDaysBefore))
            } else {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Payment Reminders", daysPrior: alertPreferences.paymentDueDaysBefore))
            }
        }
        
        if alertPreferences.paymentPosted {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Payment Posted"))
        }
        
        if alertPreferences.paymentPastDue {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Payment Past Due"))
        }
        
        if alertPreferences.budgetBilling {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Budget Billing"))
        }
        
        if alertPreferences.appointmentTracking {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Customer Appointments"))
        }
        
        if alertPreferences.forYourInfo {
            if Environment.shared.opco == .bge {
            preferences.append(AlertPreferencesRequest.AlertRequest(programName: "News"))
            } else {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: "Marketing"))

            }
        }
        
        alertPreferenceRequests = preferences
    }
}
