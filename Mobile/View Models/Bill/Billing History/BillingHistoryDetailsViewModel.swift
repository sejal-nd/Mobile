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
    
    let disposeBag = DisposeBag()
    
    private let paymentService: PaymentService
    private let accountDetail: AccountDetail
    private let billingHistoryItem: BillingHistoryItem
    
    required init(paymentService: PaymentService,
                  accountDetail: AccountDetail,
                  billingHistoryItem: BillingHistoryItem) {
        self.paymentService = paymentService
        self.accountDetail = accountDetail
        self.billingHistoryItem = billingHistoryItem
    }
    
    func cancelPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.cancelPayment(accountNumber: accountDetail.accountNumber,
                                     paymentId: billingHistoryItem.paymentId!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    var paymentMethodAccessibilityLabel: String? {
        guard let paymentMethodType = billingHistoryItem.paymentMethodType,
            let maskedAcctNum = billingHistoryItem.maskedWalletItemAccountNumber,
            !maskedAcctNum.isEmpty else { return nil }
        
        return paymentMethodType.accessibilityString +
            String.localizedStringWithFormat(", Account number ending in, %@", maskedAcctNum)
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
    
    var paymentType: String? {
        if billingHistoryItem.isAutoPayPayment {
            return "AutoPay"
        } else if billingHistoryItem.isFuelFundDonation {
            return "FuelFund"
        }
        return nil
    }
    
    var paymentAmount: String? {
        return billingHistoryItem.amountPaid?.currencyString
    }
    
    var convenienceFee: String? {
        guard let convFee = billingHistoryItem.convenienceFee else { return nil }
        return convFee.isZero ? nil : convFee.currencyString
    }
    
    var totalPaymentAmount: String? {
        guard let totalAmount = billingHistoryItem.totalAmount, let _ = convenienceFee else {
            // No need to show Total Payment Amount field unless a convenience fee was added
            return nil
        }
        return totalAmount.currencyString
    }
    
    var paymentDate: String? {
        return billingHistoryItem.date.mmDdYyyyString
    }

    var paymentStatus: String? {
        if let statusString = billingHistoryItem.statusString {
            return statusString.capitalized
        } else {
            // Data issue (should not happen in prod), but web treats null status as "Posted"
            return NSLocalizedString("Posted", comment: "")
        }
    }
    
    var confirmationNumber: String? {
        return billingHistoryItem.confirmationNumber
    }
    
    var shouldShowCancelPayment: Bool {
        return billingHistoryItem.status == .scheduled && billingHistoryItem.isAutoPayPayment
    }
    
}
