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
        return .error(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil))
    }
    
    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
                            paymentDaysBeforeDue: String,
                            effectivePeriod: EffectivePeriod,
                            effectiveEndDate: Date?,
                            effectiveNumPayments: String,
                            isUpdate: Bool) -> Observable<Void> {
        return .error(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil))
    }
    
    func unenrollFromAutoPayBGE(accountNumber: String) -> Observable<Void> {
        return .error(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil))
        
    }
    
    func enrollInAutoPay(accountNumber: String,
                         nameOfAccount: String,
                         bankAccountType: String,
                         routingNumber: String,
                         bankAccountNumber: String,
                         isUpdate: Bool) -> Observable<Void> {
        return .error(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil))
    }
    
    func unenrollFromAutoPay(accountNumber: String, reason: String) -> Observable<Void> {
        return .error(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil))
    }
    
    func schedulePayment(payment: Payment) -> Observable<String> {
        return Observable.just("123456").delay(2, scheduler: MainScheduler.instance)
    }
    
    func fetchPaymentDetails(accountNumber: String, paymentId: String) -> Observable<PaymentDetail> {
        return .just(PaymentDetail(walletItemId: "1234", paymentAmount: 100, paymentDate: Date(timeIntervalSince1970: 13)))
    }
    
    func updatePayment(paymentId: String, payment: Payment) -> Observable<Void> {
        return .just(())
    }
    
    func cancelPayment(accountNumber: String, paymentId: String, paymentDetail: PaymentDetail) -> Observable<Void> {
        return .just(())
    }
    
}
