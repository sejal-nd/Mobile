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
        return "**** " + String(paymentAccount.characters.suffix(4))
    }
    
    var paymentType: String {
        guard let paymentType = billingHistory.description else { return "" } //is supposed to be payment_method but that displays S or R so this was decided
        
        return isSpeedpay ? "" : paymentType
        
    }
    
    var paymentDate: String {
        return billingHistory.date.mmDdYyyyString
    }
    
    //amountPaid and paymentAmount
    var amountPaid: String { 
        if let amountPaid = billingHistory.amountPaid, let returnString = amountPaid.currencyString {
            return returnString
        } else {
            return ""
        }
    }
    
    var chargeAmount: String { 
        if let chargeAmount = billingHistory.chargeAmount, let returnString = chargeAmount.currencyString {
            return returnString
        } else {
            return ""
        }
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
        if let paymentStatus = billingHistory.status {
            return paymentStatus
        } else {
            return ""
        }
    }
    
    var confirmationNumber: String {
        if let confirmationNumber = billingHistory.confirmationNumber {
            return confirmationNumber
        } else {
            return ""
        }
    }
    
    var isBGE: Bool {
        return Environment.sharedInstance.opco == .bge
    }
    
    var isSpeedpay: Bool {
        guard let paymentType = billingHistory.paymentType else { return false }
        return paymentType == "SPEEDPAY"
    }
    
    var isCSS: Bool {
        return paymentType == "CSS"
    }
    
    var paymentTypeLabel: String {
        return isCSS ? "PaymentAccountNickname" : "Payment Type"
    }
    
    var paymentAmountLabel: String {
        return isSpeedpay ? "Payment Amount" : "Amount Paid"
    }
    
    var shouldShowContent: Driver<Bool> {
        return Driver.combineLatest(fetching.asDriver(), isError.asDriver()).map {
            return !$0 && !$1
        }
    }
    
    required init(paymentService: PaymentService, billingHistoryItem: BillingHistoryItem) {
        self.paymentService = paymentService
        self.billingHistory = billingHistoryItem
    }
    
    func fetchPaymentDetails(billingHistoryItem: BillingHistoryItem) {
        if let paymentId = billingHistoryItem.paymentId, billingHistoryItem.encryptedPaymentId != nil {
            fetching.value = true
            self.paymentService.fetchPaymentDetails(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber, paymentId: paymentId).subscribe(onNext: { [weak self] paymentDetail in
                self?.fetching.value = false
                self?.paymentDetail.value = paymentDetail
            }, onError: { [weak self] err in
                self?.fetching.value = false
                self?.isError.value = true
            }).disposed(by: disposeBag)
        } else {
            self.fetching.value = false
        }
    }
}
