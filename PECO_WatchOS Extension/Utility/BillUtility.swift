//
//  BillUtility.swift
//  PECO_WatchOS Extension
//
//  Created by Joseph Erlandson on 11/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

class BillUtility {
    
    // we could edit enum so each enum case takes in the variables needed to populate the state
    enum BillState {
        case restoreService(restoreAmount: Double, dpaReinstAmount: Double)
        case catchUp(amount: Double, date: Date)
        case avoidShutoff(amount: Double)
        case pastDue(pastDueAmount: Double, netDueAmount: Double, remainingBalanceDue: Double)
        case billReady(amount: Double, date: Date)
        case billReadyAutoPay
        case billPaid(amount: Double)
        case remainingBalance(amount: Double, date: Date)
        case paymentPending(amount: Double)
        case billNotReady
        case paymentScheduled(scheduledPayment: PaymentItem)
        case mostRecent(amount: Double, date: Date)
        
        var isPrecariousBillSituation: Bool {
            switch self {
            case .restoreService, .catchUp, .avoidShutoff, .pastDue:
                return true
            default:
                return false
            }
        }
        
        var billPaidOrPending: Bool {
            switch self {
            case .billPaid, .paymentPending:
                return true
            default:
                return false
            }
        }
    }
    
    public func generateBillState(accountDetail: AccountDetail) -> [BillState] {
        var billStates = [BillState]()
        
        var isPrecarious = false
        var isPendingPayment = false
        
        // Bill Unavailable
        if let amount = accountDetail.billingInfo.netDueAmount, amount == 0, accountDetail.billingInfo.billDate == nil {
            billStates.append(.billNotReady)
        }
        
        // Auto Pay
        if accountDetail.billingInfo.netDueAmount ?? 0 > 0, accountDetail.isAutoPay {
            billStates.append(.billReadyAutoPay)
        }
        
        // Scheduled Payment
        if let scheduledPayment = accountDetail.billingInfo.scheduledPayment, scheduledPayment.amount > 0 {
            billStates.append(.paymentScheduled(scheduledPayment: scheduledPayment))
        }
        
        // Net Amount Due
        if let amount = accountDetail.billingInfo.netDueAmount, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate {
            billStates.append(.billReady(amount: amount, date: dueDate))
        } else if let billDate = accountDetail.billingInfo.billDate, let lastPaymentDate = accountDetail.billingInfo.lastPaymentDate, let lastPaymentAmount = accountDetail.billingInfo.lastPaymentAmount, lastPaymentAmount > 0, billDate < lastPaymentDate {
            // Bill Paid - Payment Applied
            billStates.append(.billPaid(amount: lastPaymentAmount))
        } else {
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
        
        // Restore Service
        if let amount = accountDetail.billingInfo.restorationAmount, amount > 0, accountDetail.isCutOutNonPay, let dpaAmount = accountDetail.billingInfo.amtDpaReinst {
            billStates.append(.restoreService(restoreAmount: amount, dpaReinstAmount: dpaAmount))
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
            if let pastDueAmount = accountDetail.billingInfo.pastDueAmount, pastDueAmount > 0, let netDueAmount = accountDetail.billingInfo.netDueAmount, let remainingBalanceDue = accountDetail.billingInfo.remainingBalanceDue , !isPrecarious {
                billStates.append(.pastDue(pastDueAmount: pastDueAmount, netDueAmount: netDueAmount, remainingBalanceDue: remainingBalanceDue))
                isPrecarious = true
            }
        }
        
        // Remaining Balance
        if let amount = accountDetail.billingInfo.remainingBalanceDue, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate, isPrecarious, isPendingPayment {
            
            if let lastBillDate = accountDetail.billingInfo.billDate, dueDate != lastBillDate {
                billStates.append(.remainingBalance(amount: amount, date: dueDate))
            }
            
        }

        // Most Recent Bill
        if let amount = accountDetail.billingInfo.currentDueAmount, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate { // (isPrecarious && isPendingPayment) - apparently should not be here
            billStates.append(.mostRecent(amount: amount, date: dueDate))
        }
        
        return billStates
    }
    
}
