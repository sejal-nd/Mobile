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
        
        if !Environment.shared.opco.isPHI {
            if alertPreferences.highUsage {
                preferences.append(AlertRequest(programName: "High Usage Residential Alert",
                                                          alertThreshold: alertPreferences.alertThreshold))
            }
            
            if alertPreferences.smartEnergyRewards ?? false {
                preferences.append(AlertRequest(programName: "Energy Savings Day Alert"))
            }
            
            if alertPreferences.energySavingsDayResults ?? false {
                preferences.append(AlertRequest(programName: "Energy Savings Day Results"))
            }
            
            if alertPreferences.peakTimeSavings ?? false {
                preferences.append(AlertRequest(programName: "Peak Time Savings"))
            }
            
            if alertPreferences.outage {
                preferences.append(AlertRequest(programName: "Outage Notifications"))
            }
            
            if alertPreferences.scheduledMaint {
                preferences.append(AlertRequest(programName: "Planned Outage"))
            }
            
            if alertPreferences.severeWeather {
                preferences.append(AlertRequest(programName: "Severe Weather"))
            }
            
            if alertPreferences.billReady {
                if Environment.shared.opco == .bge {
                    preferences.append(AlertRequest(programName: "Paperless Billing"))
                } else {
                    preferences.append(AlertRequest(programName: "Bill is Ready"))
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
        }
        else {
            
            let opcoIdentifier = AccountsStore.shared.currentAccount.utilityCode?.uppercased() ?? Environment.shared.opco.rawValue
            
            let outageProgramName = "Outage" + " " + opcoIdentifier
            let severeWeatherProgramName = "Severe Weather" + " " + opcoIdentifier
            let paymentDueProgramName = "Payment Reminder" + " " + opcoIdentifier
            let paymentPostedProgramName = "Payment Posted" + " " + opcoIdentifier
            let paymentPastDueProgramName = "Payment Past Due" + " " + opcoIdentifier
            let billReadyProgramName = "Bill Ready" + " " + opcoIdentifier
            let budgetBillingProgramName = "Budget Billing" + " " + opcoIdentifier
            let forYourInfoProgramName = "News" + " " + opcoIdentifier
            
            if alertPreferences.outage {
                preferences.append(AlertRequest(programName: outageProgramName))
            }
            
            if alertPreferences.severeWeather {
                preferences.append(AlertRequest(programName: severeWeatherProgramName))
            }
            if alertPreferences.billReady {
                preferences.append(AlertRequest(programName: billReadyProgramName))
            }
            
            if alertPreferences.paymentDue {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: paymentDueProgramName, daysPrior: alertPreferences.paymentDueDaysBefore))
            }
            
            if alertPreferences.paymentPosted {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: paymentPostedProgramName))
            }
            
            if alertPreferences.paymentPastDue {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: paymentPastDueProgramName))
            }
            
            if alertPreferences.budgetBilling {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: budgetBillingProgramName))
            }
            
            if alertPreferences.forYourInfo {
                preferences.append(AlertPreferencesRequest.AlertRequest(programName: forYourInfoProgramName))
            }
        }
        
        alertPreferenceRequests = preferences
    }
}
