//
//  MockPaymentService.swift
//  Mobile
//
//  Created by Sam Francis on 8/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Foundation

class MockPaymentService: PaymentService {
    func fetchBGEAutoPayInfo(accountNumber: String) -> Observable<BGEAutoPayInfo> {
        let dataFile = MockJSONManager.File.autoPayInfo
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
                            paymentDaysBeforeDue: String,
                            isUpdate: Bool) -> Observable<Void> {
        return .just(())
    }
    
    func unenrollFromAutoPayBGE(accountNumber: String) -> Observable<Void> {
        return .just(())
    }
    
    func enrollInAutoPay(accountNumber: String,
                         nameOfAccount: String,
                         bankAccountType: String,
                         routingNumber: String,
                         bankAccountNumber: String,
                         isUpdate: Bool) -> Observable<Void> {
        return .just(())
    }
    
    func unenrollFromAutoPay(accountNumber: String, reason: String) -> Observable<Void> {
        return .just(())
    }
    
    func schedulePayment(payment: Payment) -> Observable<String> {
        return .just("123456")
    }
    
    func fetchPaymentDetails(accountNumber: String, paymentId: String) -> Observable<PaymentDetail> {
        return .just(PaymentDetail(walletItemId: "1234", paymentAmount: 100, paymentDate: Date(timeIntervalSince1970: 13), convenienceFee: 1.50,  paymentAccount: "Test Account", accountNumber: "1234"))
    }
    
    func updatePayment(paymentId: String, payment: Payment) -> Observable<Void> {
        return .just(())
    }
    
    func cancelPayment(accountNumber: String, paymentId: String, paymentDetail: PaymentDetail) -> Observable<Void> {
        return .just(())
    }
    
}
