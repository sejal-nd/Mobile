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

extension PaymentService: ReactiveCompatible {}

extension Reactive where Base == PaymentService {
    
    static func autoPayInfo(accountNumber: String) -> Observable<BGEAutoPayInfo> {
        return Observable.create { observer -> Disposable in
            PaymentService.autoPayInfo(accountNumber: accountNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func autoPayEnroll(accountNumber: String, request: AutoPayEnrollRequest) -> Observable<Void> {
        return Observable<AutoPayResult>.create { observer -> Disposable in
            PaymentService.autoPayEnroll(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: {
            RxNotifications.shared.accountDetailUpdated.onNext(())
        })
    }
    
    static func autoPayEnrollBGE(accountNumber: String, request: AutoPayEnrollBGERequest) -> Observable<Void> {
        return Observable<AutoPayResult>.create { observer -> Disposable in
            PaymentService.enrollAutoPayBGE(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: {
            RxNotifications.shared.accountDetailUpdated.onNext(())
        })
    }
    
    static func updateAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest) -> Observable<Void> {
        return Observable<AutoPayResult>.create { observer -> Disposable in
            PaymentService.updateAutoPayBGE(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: {
            RxNotifications.shared.accountDetailUpdated.onNext(())
        })
    }
    
    static func autoPayUnenroll(accountNumber: String, request: AutoPayUnenrollRequest) -> Observable<Void> {
        return Observable<AutoPayResult>.create { observer -> Disposable in
            PaymentService.autoPayUnenroll(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .mapTo(())
        .do(onNext: {
            RxNotifications.shared.accountDetailUpdated.onNext(())
        })
    }
    
    static func schedulePayment(accountNumber: String, request: ScheduledPaymentUpdateRequest) -> Observable<String> {
        return Observable<GenericResponse>.create { observer -> Disposable in
            PaymentService.schedulePayment(accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .map { $0.confirmationNumber! }
        .do(onNext: { _ in
            RxNotifications.shared.recentPaymentsUpdated.onNext(())
            AppRating.logRatingEvent()
        })
    }
    
    static func cancelSchduledPayment(accountNumber: String, paymentId: String, request: SchedulePaymentCancelRequest) -> Observable<Void> {
        return Observable<GenericResponse>.create { observer -> Disposable in
            PaymentService.cancelSchduledPayment(accountNumber: accountNumber, paymentId: paymentId, request: request) { observer.handle(result: $0) }
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
            PaymentService.updateScheduledPayment(paymentId: paymentId, accountNumber: accountNumber, request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
        .map { $0.confirmationNumber }
        .do(onNext: { _ in
            RxNotifications.shared.recentPaymentsUpdated.onNext(())
            AppRating.logRatingEvent()
        })
    }
}
