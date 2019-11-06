//
//  NewBillUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 10/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import WatchKit

class BillUtility {
    private let accountDetails: AccountDetail
    private let billingInfo: BillingInfo
    private let opco = Environment.shared.opco
    
    init(accountDetails: AccountDetail) {
        self.accountDetails = accountDetails
        self.billingInfo = accountDetails.billingInfo
    }
    
    
    // MARK: - Show/Hide
    
    // may not be correct
    private(set) lazy var showAlertBanner: Bool = {
        return self.alertBannerText != nil
    }()
    
    private(set) lazy var shouldHideAutoPay: Bool = {
        // scheduled payment
        return ((self.billingInfo.scheduledPayment?.amount > 0) ||
            
            // autopay
            (self.accountDetails.isAutoPay || self.accountDetails.isBGEasy || self.accountDetails.isAutoPayEligible) ||
            
            // bill not ready
            (billingInfo.billDate == nil && (billingInfo.netDueAmount == nil || billingInfo.netDueAmount == 0)))
    }()
    
    private(set) lazy var showTotalAmountAndLedger: Bool = {
        return !self.showBillNotReady && !self.showPaymentReceived
    }()
    
    private lazy var showBillNotReady: Bool = {
        return self.billingInfo.billDate == nil && (self.billingInfo.netDueAmount == nil || self.billingInfo.netDueAmount == 0)
    }()
    
    private(set) lazy var showPastDue: Bool = {
        let pastDueAmount = billingInfo.pastDueAmount
        return pastDueAmount > 0 && pastDueAmount != billingInfo.netDueAmount
    }()
    
    private(set) lazy var showCurrentBill: Bool = {
        let currentDueAmount = billingInfo.currentDueAmount
        return currentDueAmount > 0 && currentDueAmount != billingInfo.netDueAmount
    }()
    
    private(set) lazy var showPendingPayment: Bool = {
        return billingInfo.pendingPaymentsTotal > 0
    }()
    
    private(set) lazy var showRemainingBalanceDue: Bool = {
        return billingInfo.pendingPaymentsTotal > 0 && billingInfo.remainingBalanceDue > 0
    }()
    
    private(set) lazy var showPaymentReceived: Bool = {
        return billingInfo.lastPaymentAmount > 0 && billingInfo.netDueAmount ?? 0 == 0
    }()
    
    
    //MARK: - Banner Alert Text
    
    private(set) lazy var alertBannerText: String? = {
        // Finaled
        if billingInfo.pastDueAmount > 0 && accountDetails.isFinaled {
            return String.localizedStringWithFormat("%@ is due immediately.", billingInfo.pastDueAmount?.currencyString ?? "--")
        }
        
        // Restore Service
        if let restorationAmount = accountDetails.billingInfo.restorationAmount,
            restorationAmount > 0 &&
                accountDetails.isCutOutNonPay &&
                Environment.shared.opco != .bge {
            return String.localizedStringWithFormat("%@ is due immediately to restore service.", billingInfo.netDueAmount?.currencyString ?? "--")
        }
        
        // Avoid Shutoff
        if let arrears = billingInfo.disconnectNoticeArrears, arrears > 0 {
            let amountString = arrears.currencyString
            let date = billingInfo.turnOffNoticeExtendedDueDate ?? billingInfo.turnOffNoticeDueDate
            let days = date?.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now)) ?? 0
            let dateString = date?.mmDdYyyyString ?? "--"
            
            if days > 0 {
                let format = "%@ is due by %@ to avoid shutoff."
                return String.localizedStringWithFormat(format, amountString, dateString)
            } else {
                let format = "%@ is due immediately to avoid shutoff."
                return String.localizedStringWithFormat(format, amountString)
            }
        }
        
        // Catch Up
        if let dueByDate = billingInfo.dueByDate,
            let amtDpaReinst = billingInfo.amtDpaReinst,
            Environment.shared.opco != .bge && amtDpaReinst > 0 {
            let days = dueByDate.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now))
            let amountString = amtDpaReinst.currencyString
            
            if days > 0 {
                let format = "%@ is due by %@ to catch up on your DPA."
                return String.localizedStringWithFormat(format, amountString, dueByDate.mmDdYyyyString)
            } else {
                let format = "%@ is due immediately to catch up on your DPA."
                return String.localizedStringWithFormat(format, amountString)
            }
        }
        
        // Past Due
        if let pastDueAmount = billingInfo.pastDueAmount, pastDueAmount > 0 {
            if pastDueAmount == billingInfo.netDueAmount {
                return NSLocalizedString("Your bill is past due.", comment: "")
            } else {
                return String.localizedStringWithFormat("%@ is due immediately.", pastDueAmount.currencyString)
            }
        }
        
        return nil
    }()
    
    
    // MARK: - Image Detail Group
    
    private(set) lazy var autoPayImage: UIImage = {
        if (self.billingInfo.scheduledPayment?.amount > 0) {
            // Scheduled Payment
            return AppImage.scheduledPayment.image
        } else if self.accountDetails.isAutoPay || self.accountDetails.isBGEasy || self.accountDetails.isAutoPayEligible {
            // autopay
            return AppImage.autoPay.image
        } else {
            // Bill Not Ready
            return AppImage.billNotReady.image
        }
    }()
    
    private(set) lazy var autoPayText: String = {
        if let scheduledPaymentAmount = self.billingInfo.scheduledPayment?.amount,
            let scheduledPaymentDate = self.billingInfo.scheduledPayment?.date,
            scheduledPaymentAmount > 0 {
            // Scheduled Payment
            return String.localizedStringWithFormat("Thank you for scheduling your %@ payment for %@", scheduledPaymentAmount.currencyString, scheduledPaymentDate.mmDdYyyyString)
        } else if self.accountDetails.isAutoPay || self.accountDetails.isBGEasy || self.accountDetails.isAutoPayEligible {
            // autopay
            return NSLocalizedString("You are enrolled in a AutoPay", comment: "")
        } else {
            // Bill Not Ready
            return NSLocalizedString("Your bill will be available here once it is ready", comment: "")
        }
    }()
    
    
    // MARK: - Total Amount Due
    
    private(set) lazy var totalAmountText: String = {
        guard let netDueAmount = billingInfo.netDueAmount else { return "--" }
        
        switch Environment.shared.opco {
        case .bge: // For credit scenario we want to show the positive number
            return abs(netDueAmount).currencyString
        case .comEd, .peco:
            return max(netDueAmount, 0).currencyString
        }
    }()
    
    private lazy var isCreditBalance: Bool = {
       guard let netDueAmount = billingInfo.netDueAmount else { return false }
       return netDueAmount < 0 && Environment.shared.opco == .bge
    }()
    
    private(set) lazy var totalAmountDescriptionText: NSAttributedString = {
        var attributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .caption1),
                                                         .foregroundColor: UIColor.white]
        let string: String
        if billingInfo.pastDueAmount > 0 {
            if billingInfo.pastDueAmount == billingInfo.netDueAmount {
                string = NSLocalizedString("Total Amount Due Immediately", comment: "")
                attributes[.foregroundColor] = UIColor.errorRed
                attributes[.font] = UIFont.preferredFont(forTextStyle: .caption1)
            } else {
                string = NSLocalizedString("Total Amount Due", comment: "")
            }
        } else if billingInfo.amtDpaReinst > 0 {
            string = NSLocalizedString("Total Amount Due", comment: "")
        } else if billingInfo.lastPaymentAmount > 0 && billingInfo.netDueAmount ?? 0 == 0 {
            string = NSLocalizedString("Total Amount Due", comment: "")
        } else if self.isCreditBalance {
            string = NSLocalizedString("No Amount Due – Credit Balance", comment: "")
        } else {
            string = String.localizedStringWithFormat("Total Amount Due By %@", billingInfo.dueByDate?.mmDdYyyyString ?? "--")
        }
        
        return NSAttributedString(string: string, attributes: attributes)
    }()
    
    //MARK: - Past Due
    private(set) lazy var pastDueText: String = {
        if Environment.shared.opco != .bge && billingInfo.amtDpaReinst > 0 &&
            billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
            return NSLocalizedString("Catch Up on Agreement Amount", comment: "")
        } else {
            return NSLocalizedString("Past Due Amount", comment: "")
        }
    }()
    
    private(set) lazy var pastDueAmountText: String = {
        if Environment.shared.opco != .bge && billingInfo.amtDpaReinst > 0 &&
            billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
            return billingInfo.amtDpaReinst?.currencyString ?? "--"
        } else {
            return billingInfo.pastDueAmount?.currencyString ?? "--"
        }
    }()
    
    private(set) lazy var pastDueDateText: NSAttributedString = {
        if let date = billingInfo.dueByDate,
            Environment.shared.opco != .bge &&
                billingInfo.amtDpaReinst > 0 &&
                billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
            let string = String.localizedStringWithFormat("Due by %@", date.mmDdYyyyString)
            return NSAttributedString(string: string, attributes: [.foregroundColor: UIColor.white,
                                                                   .font: UIFont.preferredFont(forTextStyle: .caption1)])
        } else {
            let string = NSLocalizedString("Due Immediately", comment: "")
            return NSAttributedString(string: string, attributes: [.foregroundColor: UIColor.errorRed,
                                                                   .font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
    }()
    
    
    //MARK: - Current Bill
    
    private(set) lazy var currentBillAmountText: String = {
        return billingInfo.currentDueAmount?.currencyString ?? "--"
    }()
    
    private(set) lazy var currentBillDateText: String = {
        return String.localizedStringWithFormat("Due by %@", billingInfo.dueByDate?.mmDdYyyyString ?? "--")
    }()
    
    
    //MARK: - Payment Received
    
    private(set) lazy var paymentReceivedAmountText: String = {
        return billingInfo.lastPaymentAmount?.currencyString ?? "--"
    }()
    
    private(set) lazy var paymentReceivedDateText: String? = {
        guard let dateString = billingInfo.lastPaymentDate?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Payment Date %@", comment: "")
        return String(format: localizedText, dateString)
    }()
    
    
    //MARK: - Pending Payments
    
    let pendingPaymentsText: String = {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Payments Processing", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Pending Payments", comment: "")
        }
    }()
    
    private(set) lazy var pendingPaymentsTotalAmountText: String = {
        return (-billingInfo.pendingPaymentsTotal).currencyString
    }()
    
    
    //MARK: - Remaining Balance Due
    
    let remainingBalanceDueText = NSLocalizedString("Remaining Balance Due", comment: "")
    
    private(set) lazy var remainingBalanceDueAmountText: String = {
        if billingInfo.pendingPaymentsTotal == billingInfo.netDueAmount ?? 0 {
            return 0.currencyString
        } else {
            return billingInfo.remainingBalanceDue?.currencyString ?? "--"
        }
    }()
}