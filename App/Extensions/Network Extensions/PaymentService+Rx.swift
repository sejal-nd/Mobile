//
//  PaymentService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 7/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxSwiftExt

extension PaymentServiceNew: ReactiveCompatible {}

extension Reactive where Base == PaymentServiceNew {
    
    static func autoPayInfo(accountNumber: String) -> Observable<NewBGEAutoPayInfo> {
        return Observable.create { observer -> Disposable in
            PaymentServiceNew.autoPayInfo(accountNumber: accountNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func autoPayEnroll(accountNumber: String, request: AutoPayEnrollRequest) -> Observable<Void> {
        return Observable<NewAutoPayResult>.create { observer -> Disposable in
            PaymentServiceNew.autoPayEnroll(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: {
            RxNotifications.shared.accountDetailUpdated.onNext(())
        })
    }
    
    static func autoPayEnrollBGE(accountNumber: String, request: AutoPayEnrollBGERequest) -> Observable<Void> {
        return Observable<NewAutoPayResult>.create { observer -> Disposable in
            PaymentServiceNew.enrollAutoPayBGE(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: {
            RxNotifications.shared.accountDetailUpdated.onNext(())
        })
    }
    
    static func autoPayUnenroll(accountNumber: String, request: AutoPayUnenrollRequest) -> Observable<Void> {
        return Observable<NewAutoPayResult>.create { observer -> Disposable in
            PaymentServiceNew.autoPayUnenroll(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: {
            RxNotifications.shared.accountDetailUpdated.onNext(())
        })
    }
    
    static func schedulePayment(accountNumber: String, request: ScheduledPaymentUpdateRequest) -> Observable<String?> {
        return Observable<GenericResponse>.create { observer -> Disposable in
            PaymentServiceNew.schedulePayment(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .map { $0.confirmationNumber }
        .do(onNext: { _ in
            RxNotifications.shared.recentPaymentsUpdated.onNext(())
            AppRating.logRatingEvent()
        })
    }
    
    static func cancelSchduledPayment(accountNumber: String, paymentId: String, request: SchedulePaymentCancelRequest) -> Observable<Void> {
        return Observable<GenericResponse>.create { observer -> Disposable in
            PaymentServiceNew.cancelSchduledPayment(accountNumber: accountNumber, paymentId: paymentId, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: { _ in
            RxNotifications.shared.recentPaymentsUpdated.onNext(())
            AppRating.logRatingEvent()
        })
    }
    
    static func updateScheduledPayment(paymentId: String, accountNumber: String, request: ScheduledPaymentUpdateRequest) -> Observable<String?> {
        return Observable<GenericResponse>.create { observer -> Disposable in
            PaymentServiceNew.updateScheduledPayment(paymentId: paymentId, accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .map { $0.confirmationNumber }
        .do(onNext: { _ in
            RxNotifications.shared.recentPaymentsUpdated.onNext(())
            AppRating.logRatingEvent()
        })
    }
}
