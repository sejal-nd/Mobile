//
//  BillUtility.swift
//  PECO_WatchOS Extension
//
//  Created by Joseph Erlandson on 11/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

enum BillState {

    case billPaid(amount: Double)
    case billReady(amount: Double, date: Date)
    case autoPay
    case billNotReady

    case paymentScheduled(scheduledPayment: PaymentItem)
    
    case paymentPending(amount: Double)
    case remainingBalance(remainingBalanceAmount: Double)
    
    case pastDue(pastDueAmount: Double, netDueAmount: Double, remainingBalanceDue: Double)

    
    case restoreService(restoreAmount: Double, dpaReinstAmount: Double)
    case catchUp(amount: Double, date: Date)
    case avoidShutoff(amount: Double)
    case mostRecent(amount: Double, date: Date)
    
    var isPrecariousBillSituation: Bool {
        switch self {
        case .restoreService, .catchUp, .avoidShutoff, .pastDue:
            return true
        default:
            return false
        }
    }
    
    var shouldShowRecentBill: Bool {
        switch self {
        case .paymentPending, .catchUp, .restoreService, .avoidShutoff, .pastDue:
            return true
        default:
            return false
        }
    }
    
    var billPaidOrPending: Bool { // unused...
        switch self {
        case .billPaid, .paymentPending:
            return true
        default:
            return false
        }
    }
}

class BillUtility {

    public func generateBillStates(accountDetail: AccountDetail) -> [BillState] {
        var billStates = [BillState]()

        var isPrecarious = false
        var isPendingPayment = false

        // Scheduled Payment
        if let scheduledPayment = accountDetail.billingInfo.scheduledPayment, scheduledPayment.amount > 0, let scheduleDate = scheduledPayment.date, scheduleDate > Date() {
            billStates.append(.paymentScheduled(scheduledPayment: scheduledPayment))
        }
        
        // Auto Pay
        if let amount = accountDetail.billingInfo.netDueAmount, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate,  accountDetail.isAutoPay {
            billStates.append(.autoPay)
            billStates.append(.billReady(amount: amount, date: dueDate))
        } else if let amount = accountDetail.billingInfo.netDueAmount, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate, !accountDetail.isAutoPay {
            // Net Amount Due
            billStates.append(.billReady(amount: amount, date: dueDate))
        } else if let billDate = accountDetail.billingInfo.billDate, let lastPaymentDate = accountDetail.billingInfo.lastPaymentDate, accountDetail.billingInfo.lastPaymentAmount ?? 0 > 0, billDate < lastPaymentDate {
            // Bill Paid - Payment Applied
            billStates.append(.billPaid(amount: accountDetail.billingInfo.lastPaymentAmount ?? 0))
        } else if let amount = accountDetail.billingInfo.netDueAmount, amount == 0 {
            // Bill Not Ready
            billStates.append(.billNotReady)
        }
        
        // Pending Payment
        let pendingPayments = accountDetail.billingInfo.pendingPayments.filter( { $0.status == .pending || $0.status == .processing })
        if !pendingPayments.isEmpty {
            let pendingPaymentSum = pendingPayments.reduce(0) { $0 + $1.amount }
            if pendingPaymentSum > 0.0 {
                billStates.append(.paymentPending(amount: pendingPaymentSum))

                isPendingPayment = true
            }
        }
        
        // Remaining Balance
        if let amount = accountDetail.billingInfo.remainingBalanceDue, amount > 0, isPendingPayment {
            billStates.append(.remainingBalance(remainingBalanceAmount: amount))
        }
        
        // Restore Service
        if let amount = accountDetail.billingInfo.restorationAmount, amount > 0, accountDetail.isCutOutNonPay {
            billStates.append(.restoreService(restoreAmount: amount, dpaReinstAmount: accountDetail.billingInfo.amtDpaReinst ?? 0.0))
            
            isPrecarious = true
        } else {
            // Avoid Shutoff
            if let amount = accountDetail.billingInfo.disconnectNoticeArrears, amount > 0, accountDetail.billingInfo.isDisconnectNotice, !isPrecarious {
                billStates.append(.avoidShutoff(amount: amount))
                
                isPrecarious = true
            }

            // Catch up on Agreement - no mention of dueDate for catch up on agreement
            if let amount = accountDetail.billingInfo.amtDpaReinst, amount > 0, let date = accountDetail.billingInfo.dueByDate, !isPrecarious {
                billStates.append(.catchUp(amount: amount, date: date))
                
                isPrecarious = true
            }
            
            // Amount Past Due
            if let pastDueAmount = accountDetail.billingInfo.pastDueAmount, pastDueAmount > 0, !isPrecarious {
                billStates.append(.pastDue(pastDueAmount: pastDueAmount, netDueAmount: accountDetail.billingInfo.netDueAmount ?? 0.0, remainingBalanceDue: accountDetail.billingInfo.remainingBalanceDue ?? 0.0))
                
                isPrecarious = true
            }
        }

        // Most Recent Bill
        if let amount = accountDetail.billingInfo.currentDueAmount, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate, let netDueAmount = accountDetail.billingInfo.netDueAmount, amount != netDueAmount, netDueAmount > 0 {
            billStates.append(.mostRecent(amount: amount, date: dueDate))
        }

        return billStates
    }
    
}
