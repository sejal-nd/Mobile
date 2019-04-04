//
//  BillingHistoryDetailsViewModel.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxSwiftExt
import RxCocoa

class BillingHistoryDetailsViewModel {
    
    private let accountDetail: AccountDetail
    private let billingHistory: BillingHistoryItem

    
    var paymentAccount: String? {
        let paymentAccount = accountDetail.accountNumber
        return "**** " + String(paymentAccount.suffix(4))
    }
    
    var paymentAccountImage: UIImage? {
        guard let paymentMethodType = billingHistory.paymentMethodType else { return nil }
        return paymentMethodType.imageMini
    }
    
    var paymentType: String? {
        return billingHistory.description
    }
    
    var paymentDate: String? {
        return billingHistory.date.mmDdYyyyString
    }
    
    //amountPaid and paymentAmount
    var paymentAmount: String? {
        return billingHistory.amountPaid?.currencyString
    }
    
    var chargeAmount: String? {
        return billingHistory.chargeAmount?.currencyString
    }
    
    var convenienceFee: String? {
        let convFee = accountDetail.billingInfo.convenienceFee
        return convFee.isZero ? nil : convFee.currencyString
    }

    // TODO: Fix Unit Tests
    var totalPaymentAmount: String? {
        let convFee = accountDetail.billingInfo.convenienceFee
        guard let paymentAmount = accountDetail.billingInfo.lastPaymentAmount else { return nil } // is last payment amount the same as paymentDetail paymentAmount?
        let returnValue = convFee + paymentAmount
        return returnValue.currencyString
    }
    
    var paymentStatus: String? {
        return billingHistory.statusString?.capitalized
    }
    
    var confirmationNumber: String? {
        return billingHistory.confirmationNumber
    }
    
    var paymentTypeLabel: String {
        return paymentType == "CSS" ?
            NSLocalizedString("PaymentAccountNickname", comment: "") :
            NSLocalizedString("Payment Type", comment: "")
    }

    required init(accountDetail: AccountDetail, billingHistoryItem: BillingHistoryItem) {
        self.accountDetail = accountDetail
        self.billingHistory = billingHistoryItem
    }
}
