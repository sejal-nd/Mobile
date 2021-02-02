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
    
    private let accountDetail: AccountDetail
    private let billingHistoryItem: BillingHistoryItem
    
    required init(accountDetail: AccountDetail,
                  billingHistoryItem: BillingHistoryItem) {
        self.accountDetail = accountDetail
        self.billingHistoryItem = billingHistoryItem
    }
    
    func cancelPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        
        let cancelRequest = SchedulePaymentCancelRequest(paymentAmount: billingHistoryItem.amountPaid ?? 0)
        
        PaymentService.cancelSchduledPayment(accountNumber: accountDetail.accountNumber, paymentId: billingHistoryItem.paymentID ?? "", request: cancelRequest) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    var paymentMethodAccessibilityLabel: String? {
        guard let paymentMethodType = billingHistoryItem.paymentMethodType,
            let maskedAcctNum = billingHistoryItem.maskedAccountNumber,
            !maskedAcctNum.isEmpty else { return nil }
        
        return paymentMethodType.accessibilityString +
            String.localizedStringWithFormat(", Account number ending in, %@", maskedAcctNum)
    }

    var paymentMethodImage: UIImage? {
        guard let paymentMethodType = billingHistoryItem.paymentMethodType else { return nil }
        return paymentMethodType.imageMini
    }
    
    var paymentMethodString: String? {
        guard let maskedAcctNum = billingHistoryItem.maskedAccountNumber,
            !maskedAcctNum.isEmpty else { return nil }
        return "**** \(maskedAcctNum.last4Digits())"
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
        return billingHistoryItem.paymentID
    }
    
    var shouldShowCancelPayment: Bool {
        return billingHistoryItem.status == .scheduled && billingHistoryItem.isAutoPayPayment
    }
    
}
