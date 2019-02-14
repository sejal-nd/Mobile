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
    
    private let billingHistory: BillingHistoryItem

    let fetching = Variable(false)
    let isError = Variable(false)
    let paymentDetail = Variable<PaymentDetail?>(nil)
    
    private(set) lazy var paymentAccount: Driver<String?> = self.paymentDetail.asDriver().map {
        guard let paymentAccount = $0?.accountNumber else { return "" }
        return "**** " + String(paymentAccount.suffix(4))
    }
    
    var paymentType: String {
        guard let paymentType = billingHistory.description else { return "" }
        return isSpeedpay ? "" : paymentType
    }
    
    var paymentDate: String {
        return billingHistory.date.mmDdYyyyString
    }
    
    //amountPaid and paymentAmount
    var amountPaid: String {
        return billingHistory.amountPaid?.currencyString ?? ""
    }
    
    var chargeAmount: String {
        return billingHistory.chargeAmount?.currencyString ?? ""
    }
    
    private(set) lazy var convenienceFee: Driver<String?> = self.paymentDetail.asDriver().map {
        guard let convFee = $0?.convenienceFee else { return "" }
        return convFee.currencyString
    }
    
    private(set) lazy var totalAmountPaid: Driver<String?> = self.paymentDetail.asDriver().map {
        guard let paymentDetail = $0 else { return "" }
        guard let convFee = paymentDetail.convenienceFee else { return "" }
        let returnValue = convFee + paymentDetail.paymentAmount
        return returnValue.currencyString
    }
    
    var paymentStatus: String {
        return billingHistory.statusString?.capitalized ?? ""
    }
    
    var confirmationNumber: String {
        return billingHistory.confirmationNumber ?? ""
    }
    
    var isSpeedpay: Bool {
        return billingHistory.paymentType == "SPEEDPAY"
    }
    
    var paymentTypeLabel: String {
        return paymentType == "CSS" ?
            NSLocalizedString("PaymentAccountNickname", comment: "") :
            NSLocalizedString("Payment Type", comment: "")
    }
    
    var paymentAmountLabel: String {
        return isSpeedpay ?
            NSLocalizedString("Payment Amount", comment: "") :
            NSLocalizedString("Amount Paid", comment: "")
    }
    
    private(set) lazy var shouldShowContent: Driver<Bool> = Driver.combineLatest(fetching.asDriver(),
                                                                                 isError.asDriver(),
                                                                                 resultSelector: { !$0 && !$1 })
    
    required init(paymentService: PaymentService, billingHistoryItem: BillingHistoryItem) {
        self.paymentService = paymentService
        self.billingHistory = billingHistoryItem
    }
    
    func fetchPaymentDetails(billingHistoryItem: BillingHistoryItem, onCompletion: @escaping () -> Void) {
        if let paymentId = billingHistoryItem.paymentId {
            fetching.value = true
            paymentService.fetchPaymentDetails(accountNumber: AccountsStore.shared.currentAccount.accountNumber, paymentId: paymentId).subscribe(onNext: { [weak self] paymentDetail in
                self?.fetching.value = false
                self?.paymentDetail.value = paymentDetail
                onCompletion()
            }, onError: { [weak self] err in
                self?.fetching.value = false
                self?.isError.value = true
                onCompletion()
            }).disposed(by: disposeBag)
        } else {
            fetching.value = false
        }
    }
}
