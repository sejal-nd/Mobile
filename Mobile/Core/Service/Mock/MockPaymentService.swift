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
    
    func schedulePayment(accountNumber: String,
                         paymentAmount: Double,
                         paymentDate: Date,
                         walletId: String,
                         walletItem: WalletItem) -> Observable<String> {
        return .just("123456")
    }
    
    func updatePayment(paymentId: String,
                       accountNumber: String,
                       paymentAmount: Double,
                       paymentDate: Date,
                       walletId: String,
                       walletItem: WalletItem) -> Observable<Void> {
        return .just(())
    }
    
    func cancelPayment(accountNumber: String, paymentId: String) -> Observable<Void> {
        return .just(())
    }
    
}
