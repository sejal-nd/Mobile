//
//  WatchBill.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct WatchBill: Identifiable {
    init(alertText: String? = nil,
         totalAmountDueText: String? = nil,
         totalAmountDueDateText: String? = nil,
         isBillReady: Bool = false,
         isEnrolledInAutoPay: Bool = false,
         scheduledPaymentAmountText: String? = nil,
         paymentReceivedAmountText: String? = nil,
         catchUpAmountText: String? = nil,
         catchUpDateText: String? = nil,
         pastDueAmountText: String? = nil,
         currentBillAmountText: String? = nil,
         currentBillDateText: String? = nil,
         pendingPaymentAmountText: String? = nil,
         remainingBalanceAmountText: String? = nil) {
        self.alertText = alertText
        self.totalAmountDueText = totalAmountDueText
        self.totalAmountDueDateText = totalAmountDueDateText
        self.isBillReady = isBillReady
        self.isEnrolledInAutoPay = isEnrolledInAutoPay
        self.scheduledPaymentAmountText = scheduledPaymentAmountText
        self.paymentReceivedAmountText = paymentReceivedAmountText
        self.catchUpAmountText = catchUpAmountText
        self.catchUpDateText = catchUpDateText
        self.pastDueAmountText = pastDueAmountText
        self.currentBillAmountText = currentBillAmountText
        self.currentBillDateText = currentBillDateText
        self.pendingPaymentAmountText = pendingPaymentAmountText
        self.remainingBalanceAmountText = remainingBalanceAmountText
    }
    
    init(accountDetails: AccountDetail) {
        let billingInfo = accountDetails.billingInfo
        let opco = Configuration.shared.opco
        
        self.alertText = createAlertBannerText(accountDetails: accountDetails,
                                               billingInfo: billingInfo)
        self.totalAmountDueText = createTotalAmountDueText(billingInfo: billingInfo,
                                                           opco: opco)
        self.totalAmountDueDateText = createTotalAmountDueDateText(billingInfo: billingInfo,
                                                                   opco: opco)
        self.isBillReady = determineIfBillIsNotReady(accountDetails: accountDetails,
                                                     billingInfo: billingInfo,
                                                     opco: opco)
        self.isEnrolledInAutoPay = determineIfAutoPay(accountDetails: accountDetails,
                                                      billingInfo: billingInfo)
        self.scheduledPaymentAmountText = createScheduledPaymentAmountText(billingInfo: billingInfo,
                                                                           opco: opco)
        self.paymentReceivedAmountText = createPaymentReceivedAmountText(billingInfo: billingInfo)
        
        self.catchUpAmountText = createCatchUpAmountText(billingInfo: billingInfo,
                                                         opco: opco)
        self.catchUpDateText = createCatchUpDueDateText(billingInfo: billingInfo,
                                                        opco: opco)
        self.pastDueAmountText = createPastDueText(billingInfo: billingInfo)
        self.currentBillAmountText = createCurrentBillText(billingInfo: billingInfo)
        self.currentBillDateText = createCurrentBillDateText(billingInfo: billingInfo)
        self.pendingPaymentAmountText = createPendingPaymentAmountText(billingInfo: billingInfo)
        self.remainingBalanceAmountText = createRemainingBalanceDueText(billingInfo: billingInfo)
        
        self.accountDetails = accountDetails
    }
    
    var id: UUID = UUID()
    
    var alertText: String?
    
    var totalAmountDueText: String?
    var totalAmountDueDateText: String?
    
    var isBillReady = false
    var isEnrolledInAutoPay = false
    
    var scheduledPaymentAmountText: String?
    
    var paymentReceivedAmountText: String?
    
    var catchUpAmountText: String?
    var catchUpDateText: String?
    
    var pastDueAmountText: String?
    
    var currentBillAmountText: String?
    var currentBillDateText: String?
    
    var pendingPaymentAmountText: String?
    
    var remainingBalanceAmountText: String?
    
    var accountDetails: AccountDetail? = nil
}

extension WatchBill: Equatable {
    static func == (lhs: WatchBill, rhs: WatchBill) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Billing Helpers

extension WatchBill {
    // MARK: Alert
    private func createAlertBannerText(accountDetails: AccountDetail,
                                       billingInfo: BillingInfo) -> String? {
        // Finaled
        if billingInfo.pastDueAmount > 0 && accountDetails.isFinaled {
            return "\(billingInfo.pastDueAmount?.currencyString ?? "--") is due immediately."
        }
        
        // Restore Service
        if let restorationAmount = accountDetails.billingInfo.restorationAmount,
           restorationAmount > 0 &&
            accountDetails.isCutOutNonPay &&
            Configuration.shared.opco != .bge {
            return "\(restorationAmount.currencyString) is due immediately to restore service."
        }
        
        // Avoid Shutoff
        if let arrears = billingInfo.disconnectNoticeArrears, arrears > 0 {
            let amountString = arrears.currencyString
            let date = billingInfo.turnOffNoticeExtendedDueDate ?? billingInfo.turnOffNoticeDueDate
            let days = date?.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now)) ?? 0
            let dateString = date?.mmDdYyyyString ?? "--"
            
            if days > 0 {
                return "\(amountString) is due by \(dateString) to avoid shutoff."
            } else {
                return "\(amountString) is due immediately to avoid shutoff."
            }
        }
        
        // Catch Up
        if let dueByDate = billingInfo.dueByDate,
           let amtDpaReinst = billingInfo.amtDpaReinst,
           Configuration.shared.opco != .bge && amtDpaReinst > 0 {
            let days = dueByDate.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now))
            let amountString = amtDpaReinst.currencyString
            
            if days > 0 {
                return "\(amountString) is due by \(dueByDate.mmDdYyyyString) to catch up on your DPA."
            } else {
                return "\(amountString) is due immediately to catch up on your DPA."
            }
        }
        
        // Past Due
        if let pastDueAmount = billingInfo.pastDueAmount, pastDueAmount > 0 {
            if pastDueAmount == billingInfo.netDueAmount {
                return "Your bill is past due."
            } else {
                return "\(pastDueAmount.currencyString) is due immediately."
            }
        }
        
        return nil
    }
    
    // MARK: Determine if bill is NOT ready
    private func determineIfBillIsNotReady(accountDetails: AccountDetail,
                                           billingInfo: BillingInfo,
                                           opco: OpCo) -> Bool {
        let opco = Configuration.shared.opco
        
        if accountDetails.isFinaled && billingInfo.pastDueAmount > 0 {
            return false
        }
        
        if opco != .bge && billingInfo.restorationAmount > 0 && accountDetails.isCutOutNonPay {
            return false
        }
        
        if billingInfo.disconnectNoticeArrears > 0 {
            return false
        }
        
        if opco != .bge && billingInfo.amtDpaReinst > 0 {
            return false
        }
        
        if billingInfo.pastDueAmount > 0 {
            return false
        }
        
        if billingInfo.pendingPaymentsTotal > 0 {
            return false
        }
        
        if billingInfo.netDueAmount > 0 && (accountDetails.isAutoPay || accountDetails.isBGEasy) {
            return false
        }
        
        if billingInfo.scheduledPayment?.amount > 0 {
            return false
        }
        
        if opco == .bge && billingInfo.netDueAmount < 0 {
            return false
        }
        
        if billingInfo.netDueAmount > 0 {
            return false
        }
        
        if let billDate = billingInfo.billDate,
           let lastPaymentDate = billingInfo.lastPaymentDate,
           billingInfo.lastPaymentAmount > 0,
           billDate < lastPaymentDate {
            return false
        }
        
        return true
    }
    
    // MARK: Total Amount Due
    private func determineIfCreditBalance(billingInfo: BillingInfo,
                                          opco: OpCo) -> Bool {
        guard let netDueAmount = billingInfo.netDueAmount else { return false }
        switch opco {
        case .ace, .bge, .delmarva, .pepco: // For credit scenario we want to show the positive number
            return netDueAmount < 0
        case .comEd, .peco:
            return false
        }
    }
    
    private func createTotalAmountDueText(billingInfo: BillingInfo,
                                          opco: OpCo) -> String {
        guard let netDueAmount = billingInfo.netDueAmount else { return "--" }
        
        switch opco {
        case .ace, .bge, .delmarva, .pepco: // For credit scenario we want to show the positive number
            return abs(netDueAmount).currencyString
        case .comEd, .peco:
            return max(netDueAmount, 0).currencyString
        }
    }
    
    private func createTotalAmountDueDateText(billingInfo: BillingInfo,
                                              opco: OpCo) -> String {
        if billingInfo.pastDueAmount > 0 {
            if billingInfo.pastDueAmount == billingInfo.netDueAmount {
                return "Total Amount Due Immediately"
            } else {
                return "Total Amount Due"
            }
        } else if (billingInfo.amtDpaReinst > 0) || (billingInfo.lastPaymentAmount > 0 && billingInfo.netDueAmount ?? 0 == 0) {
            return "Total Amount Due"
        } else if determineIfCreditBalance(billingInfo: billingInfo,
                                           opco: opco) {
            return opco.isPHI ? "Credit Balance - You have no amount due" : "No Amount Due – Credit Balance"
        } else {
            return billingInfo.dueByDate?.dueByText ?? "Total Amount Due"
        }
    }
    
    // MARK: AutoPay
    private func determineIfAutoPay(accountDetails: AccountDetail,
                                    billingInfo: BillingInfo) -> Bool {
        return billingInfo.netDueAmount > 0 && (accountDetails.isAutoPay || accountDetails.isBGEasy)
    }
    
    // MARK: Scheduled Payment
    private func createScheduledPaymentAmountText(billingInfo: BillingInfo,
                                                  opco: OpCo) -> String? {
        guard let scheduledPaymentAmount = billingInfo.scheduledPayment?.amount,
              let scheduledPaymentDate = billingInfo.scheduledPayment?.date,
              scheduledPaymentAmount > 0 else { return nil }
        return "Thank you for scheduling your \(scheduledPaymentAmount.currencyString) payment for \(scheduledPaymentDate.mmDdYyyyString)"
    }
    
    // MARK: Catch Up on Agreement
    private func createCatchUpAmountText(billingInfo: BillingInfo,
                                         opco: OpCo) -> String? {
        if opco != .bge && billingInfo.amtDpaReinst > 0 &&
            billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
            return billingInfo.amtDpaReinst?.currencyString
        }
        return nil
    }
    
    private func createCatchUpDueDateText(billingInfo: BillingInfo,
                                          opco: OpCo) -> String? {
        if let date = billingInfo.dueByDate,
           opco != .bge &&
            billingInfo.amtDpaReinst > 0 &&
            billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
            return "Due by \(date.mmDdYyyyString)"
        } else {
            return "Due Immediately"
        }
    }
    
    // MARK: Past Due
    private func createPastDueText(billingInfo: BillingInfo) -> String? {
        guard let pastDueAmount = billingInfo.pastDueAmount,
              pastDueAmount > 0 && pastDueAmount != billingInfo.netDueAmount else { return nil }
        return pastDueAmount.currencyString
    }
    
    // MARK: Current Bill
    private func createCurrentBillText(billingInfo: BillingInfo) -> String? {
        guard let currentDueAmount = billingInfo.currentDueAmount,
              currentDueAmount > 0 && currentDueAmount != billingInfo.netDueAmount else { return nil }
        return currentDueAmount.currencyString
    }
    
    private func createCurrentBillDateText(billingInfo: BillingInfo) -> String? {
        guard let dateText = billingInfo.dueByDate?.mmDdYyyyString else { return nil }
        return "Due by \(dateText)"
    }
    
    // MARK: Pending Payment
    private func createPendingPaymentAmountText(billingInfo: BillingInfo) -> String? {
        guard billingInfo.pendingPaymentsTotal > 0 else { return nil }
        return (-billingInfo.pendingPaymentsTotal).currencyString
    }
    
    // MARK: Remaining Balance
    private func createRemainingBalanceDueText(billingInfo: BillingInfo) -> String? {
        guard billingInfo.pendingPaymentsTotal > 0 && billingInfo.remainingBalanceDue > 0 else { return nil }
        if let netDueAmount = billingInfo.netDueAmount,
           billingInfo.pendingPaymentsTotal == netDueAmount {
            return nil
        } else {
            return billingInfo.remainingBalanceDue?.currencyString
        }
    }
    
    // MARK: Payment Received
    private func createPaymentReceivedAmountText(billingInfo: BillingInfo) -> String? {
        guard let lastPaymentAmount = billingInfo.lastPaymentAmount,
              lastPaymentAmount > 0 && billingInfo.netDueAmount ?? 0 == 0 else { return nil }
        return lastPaymentAmount.currencyString
    }
}
