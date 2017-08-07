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
    
    let fetchingTracker = ActivityTracker()
    let fetching: Driver<Bool>
    
    private lazy var paymentDetail: Observable<PaymentDetail> = Observable.just(self.billingHistory)
        .filter { $0.encryptedPaymentId != nil }
        .map { $0.paymentId }
        .unwrap()
        .flatMap(self.fetchPaymentDetails)
        .debug("******")
    
    private(set) lazy var paymentAccount: Driver<String?> = self.paymentDetail.asDriver(onErrorDriveWith: .empty()).map {
        guard let paymentAccount = $0.accountNumber else { return "" }
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
    
    private(set) lazy var convenienceFee: Driver<String?> = self.paymentDetail.asDriver(onErrorDriveWith: .empty()).map {
        guard let convFee = $0.convenienceFee else { return "" }
        return convFee.currencyString
    }
    
    private(set) lazy var totalAmountPaid: Driver<String?> = self.paymentDetail.asDriver(onErrorDriveWith: .empty()).map {
        guard let convFee = $0.convenienceFee else { return "" }
        let returnValue = convFee + $0.paymentAmount
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
    
    required init(paymentService: PaymentService, billingHistoryItem: BillingHistoryItem) {
        self.paymentService = paymentService
        self.billingHistory = billingHistoryItem
        self.fetching = self.fetchingTracker.asDriver()
    }
    
    func fetchPaymentDetails(paymentId: String) -> Observable<PaymentDetail> {
        return paymentService.fetchPaymentDetails(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber, paymentId: paymentId)
        .trackActivity(fetchingTracker)
    }
}
