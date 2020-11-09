//
//  BillService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 7/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension BillService: ReactiveCompatible {}

extension Reactive where Base == BillService {
    static func fetchBudgetBillingInfo(accountNumber: String) -> Observable<BudgetBilling> {
        return Observable.create { observer -> Disposable in
            BillService.fetchBudgetBillingInfo(accountNumber: accountNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func enrollBudgetBilling(accountNumber: String) -> Observable<Void> {
        return Observable<GenericResponse>.create { observer -> Disposable in
            BillService.enrollBudgetBilling(accountNumber: accountNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }.map { _ in ()}
    }
    
    static func unenrollBudgetBilling(accountNumber: String, reason: String) -> Observable<Void> {
        return Observable<GenericResponse>.create { observer -> Disposable in
            BillService.unenrollBudgetBilling(accountNumber: accountNumber, reason: reason) { observer.handle(result: $0) }
            return Disposables.create()
        }.map { _ in ()}
    }
    
    static func enrollPaperlessBilling(accountNumber: String, email: String?) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            BillService.enrollPaperlessBilling(accountNumber: accountNumber, email: email) { observer.handle(result: $0) }
            return Disposables.create()
        }.map { _ in ()}
    }
    
    static func unenrollPaperlessBilling(accountNumber: String) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            BillService.unenrollPaperlessBilling(accountNumber: accountNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }.map { _ in ()}
    }
    
    static func fetchBillPdf(accountNumber: String, billDate: Date, documentID: String) -> Observable<BillPDF> {
        return Observable.create { observer -> Disposable in
            BillService.fetchBillPdf(accountNumber: accountNumber, billDate: billDate, documentID: documentID) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date) -> Observable<BillingHistoryResult> {
        return Observable.create { observer -> Disposable in
            BillService.fetchBillingHistory(accountNumber: accountNumber, startDate: startDate, endDate: endDate) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
}
