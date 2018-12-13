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
                         bankAccountType: BankAccountType,
                         routingNumber: String,
                         bankAccountNumber: String,
                         isUpdate: Bool) -> Observable<Void> {
        return .error(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil))
    }
    
    
    func unenrollFromAutoPay(accountNumber: String, reason: String) -> Observable<Void> {
        return .error(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil))
    }
    
    /// Return the next 90 days, minus weekends
    func fetchWorkdays() -> Observable<[Date]> {
        let today = Calendar.opCo.startOfDay(for: Date())
        
        let workDays = (0..<90)
            .map { Calendar.opCo.date(byAdding: DateComponents(day: $0), to: today)! }
            .filter { !Calendar.opCo.isDateInWeekend($0) }
        
        return .just(workDays)
    }
    
    func schedulePayment(payment: Payment) -> Observable<String> {
        return Observable.just("").delay(2, scheduler: MainScheduler.instance)
    }
    
    func scheduleBGEOneTimeCardPayment(accountNumber: String, paymentAmount: Double, paymentDate: Date, creditCard: CreditCard) -> Observable<String> {
        return Observable.just("").delay(2, scheduler: MainScheduler.instance)
    }
    
    func fetchPaymentDetails(accountNumber: String, paymentId: String) -> Observable<PaymentDetail> {
        return .just(PaymentDetail(walletItemId: "1234", paymentAmount: 100, paymentDate: Date(timeIntervalSince1970: 13)))
    }
    
    func updatePayment(paymentId: String, payment: Payment) -> Observable<Void> {
        return .just(())
    }
    
    func cancelPayment(accountNumber: String, paymentId: String, bankOrCard: BankOrCard?, paymentDetail: PaymentDetail) -> Observable<Void> {
        return .just(())
    }
    
    func fetchPaymentFreezeDate() -> Observable<Date> {
        return Observable.just(Calendar.opCo.date(from: DateComponents(year: 2088, month: 11, day: 10))!)
//            .delay(2, scheduler: MainScheduler.instance)
    }
    
}
