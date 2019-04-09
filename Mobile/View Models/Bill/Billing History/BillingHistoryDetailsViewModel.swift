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
    
    private let billingHistoryItem: BillingHistoryItem
    
    required init(billingHistoryItem: BillingHistoryItem) {
        self.billingHistoryItem = billingHistoryItem
    }

    var paymentMethodImage: UIImage? {
        guard let paymentMethodType = billingHistoryItem.paymentMethodType else { return nil }
        return paymentMethodType.imageMini
    }
    
    var paymentMethodString: String? {
        guard let maskedAcctNum = billingHistoryItem.maskedWalletItemAccountNumber,
            !maskedAcctNum.isEmpty else { return nil }
        return "**** \(maskedAcctNum)"
    }
    
    var paymentAmount: String? {
        return billingHistoryItem.amountPaid?.currencyString
    }
    
    var convenienceFee: String? {
        guard let convFee = billingHistoryItem.convenienceFee else { return nil }
        return convFee.isZero ? nil : convFee.currencyString
    }
    
    var totalPaymentAmount: String? {
        guard let totalAmount = billingHistoryItem.totalAmount else { return nil }
        return totalAmount.currencyString
    }
    
    var paymentDate: String? {
        return billingHistoryItem.date.mmDdYyyyString
    }

    var paymentStatus: String? {
        return billingHistoryItem.statusString?.capitalized
    }
    
    var confirmationNumber: String? {
        return billingHistoryItem.confirmationNumber
    }
    
}
