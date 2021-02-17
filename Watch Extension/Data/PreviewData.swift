//
//  PreviewData.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

enum PreviewData { }

// MARK: Account

extension PreviewData {
    static let accountDefault = WatchAccount(accountID: "XXXXXXXXX",
                                             address: "10 Anywhere Lane",
                                             isResidential: true)
    
    static let accounts = [
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere…",
                     isResidential: true),
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere 10 Anywhere 10 Anywhere",
                     isResidential: false),
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere 10 Anywhere 10 Anywhere",
                     isResidential: true)
    ]
}

// MARK: Outage

extension PreviewData {
    static let outageDefault = WatchOutage(isPowerOn: true)
    
    static let outageOn = WatchOutage(isPowerOn: true)
    
    static let outageOff = WatchOutage(isPowerOn: false,
                                       estimatedRestoration: "10:30AM 10/09/2018")
    
    static let outageReported = WatchOutage(isPowerOn: false,
                                            estimatedRestoration: Configuration.shared.opco.isPHI ? "Pending Assessment" : "Assessing Damage")
}

// MARK: Usage

extension PreviewData {
    static let usageDefault = WatchUsage(fuelTypes: [.electric, .gas],
                                         electricUsageCost: "$XX",
                                         electricProjetedUsageCost: "$XXX.XX",
                                         electricBillPeriod: "N/A",
                                         electricProgress: 0)
    
    // Electric
    static let usageElectricModeled = WatchUsage(fuelTypes: [.electric],
                                                 electricUsageCost: "$80",
                                                 electricProjetedUsageCost: "$120",
                                                 electricBillPeriod: "May 24 - Jun 19",
                                                 electricProgress: 65)
    
    static let usageElectricUnmodeled = WatchUsage(fuelTypes: [.electric],
                                                   electricUsageCost: "21 kWh",
                                                   electricProjetedUsageCost: "36 kWh",
                                                   electricBillPeriod: "May 24 - Jun 19",
                                                   electricProgress: 65)
    
    static let usageElectricUnforecasted = WatchUsage(fuelTypes: [.electric],
                                                      electricTimeToNextForecast: "5 Days")
    
    // Gas
    static let usageGasModeled = WatchUsage(fuelTypes: [.gas],
                                            gasUsageCost: "$80",
                                            gasProjetedUsageCost: "$120",
                                            gasBillPeriod: "May 24 - Jun 19",
                                            gasProgress: 65)
    
    static let usageGasUnmodeled = WatchUsage(fuelTypes: [.gas],
                                              gasUsageCost: "21 kWh",
                                              gasProjetedUsageCost: "36 kWh",
                                              gasBillPeriod: "May 24 - Jun 19",
                                              gasProgress: 65)
    
    static let usageGasUnforecasted = WatchUsage(fuelTypes: [.gas],
                                                 gasTimeToNextForecast: "5 Days")
    
    // Both
    static let usageGasAndElectricModeled = WatchUsage(fuelTypes: [.electric, .gas],
                                                       electricUsageCost: "$80",
                                                       electricProjetedUsageCost: "$120",
                                                       electricBillPeriod: "May 24 - Jun 19",
                                                       electricProgress: 65,
                                                       gasUsageCost: "$120",
                                                       gasProjetedUsageCost: "$160",
                                                       gasBillPeriod: "May 29 - Jun 25",
                                                       gasProgress: 40)
    
    static let usageGasAndElectricUnmodeled = WatchUsage(fuelTypes: [.electric, .gas],
                                                         electricUsageCost: "80 kWh",
                                                         electricProjetedUsageCost: "120 kWh",
                                                         electricBillPeriod: "May 24 - Jun 19",
                                                         electricProgress: 65,
                                                         gasUsageCost: "120 CCF",
                                                         gasProjetedUsageCost: "160 CCF",
                                                         gasBillPeriod: "May 29 - Jun 25",
                                                         gasProgress: 40)
    
    static let usageGasAndElectricUnforecasted = WatchUsage(fuelTypes: [.electric, .gas],
                                                            electricTimeToNextForecast: "3 Days",
                                                            gasTimeToNextForecast: "1 Day")
}

// MARK: Billing

extension PreviewData {
    static let billDefault = WatchBill(totalAmountDueText: "$0.00",
                                       totalAmountDueDateText: "Due by MM/DD/YYYY",
                                       isBillReady: true)
    
    static let billStandard = WatchBill(totalAmountDueText: "$1000.00",
                                        totalAmountDueDateText: "Amount due in 5 days",
                                        isBillReady: true)
    
    static let billAutoPay = WatchBill(totalAmountDueText: "$1000.00",
                                       totalAmountDueDateText: "Amount due in 5 days",
                                       isBillReady: true,
                                       isEnrolledInAutoPay: true)
    
    static let billReceived = WatchBill(totalAmountDueText: "$1000.00",
                                        totalAmountDueDateText: "Amount due in 5 days",
                                        isBillReady: true,
                                        paymentReceivedAmountText: "$272.35")
    
    static let billScheduled = WatchBill(totalAmountDueText: "$1000.00",
                                         totalAmountDueDateText: "Amount due in 5 days",
                                         isBillReady: true,
                                         scheduledPaymentAmountText: "$145.55")
    
    static let billPendingPayment = WatchBill(totalAmountDueText: "$1000.00",
                                              totalAmountDueDateText: "Amount due in 5 days",
                                              isBillReady: true,
                                              pendingPaymentAmountText: "-$145.55")
    
    //    static let billAutoPay = WatchBill(totalAmountDueText: "$1000.00",
    //                                       totalAmountDueDateText: "Amount due in 5 days",
    //                                       isBillReady: true,
    //                                       scheduledPaymentAmountText: <#T##String?#>,
    //                                       paymentReceivedAmountText: "$272.35",
    //                                       paymentReceivedDateText: "test test ",
    //                                       catchUpAmountText: <#T##String?#>,
    //                                       catchUpDateText: <#T##String?#>,
    //                                       pastDueAmountText: <#T##String?#>,
    //                                       currentBillAmountText: <#T##String?#>,
    //                                       currentBillDateText: <#T##String?#>,
    //                                       pendingPaymentAmountText: <#T##String?#>,
    //                                       remainingBalanceAmountText: <#T##String?#>)
    //
    static let billPrecarious = WatchBill(alertText: "Your bill is past due.",
                                          totalAmountDueText: "$200.00",
                                          totalAmountDueDateText: "Amount due immediately",
                                          isBillReady: true,
                                          pastDueAmountText: "$125.00",
                                          currentBillAmountText: "$75.00",
                                          currentBillDateText: "Due by 09/25/2021")
}
