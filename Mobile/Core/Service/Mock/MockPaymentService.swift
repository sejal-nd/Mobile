//
//  MockPaymentService.swift
//  Mobile
//
//  Created by Sam Francis on 8/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockPaymentService: PaymentService {
    func fetchBGEAutoPayInfo(accountNumber: String, completion: @escaping (_ result: ServiceResult<BGEAutoPayInfo>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil)))
    }
    
    
    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
                            paymentDaysBeforeDue: String,
                            effectivePeriod: EffectivePeriod,
                            effectiveEndDate: Date?,
                            effectiveNumPayments: String,
                            isUpdate: Bool,
                            completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil)))
    }
    
    
    func unenrollFromAutoPayBGE(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil)))
        
    }
    
    
    func enrollInAutoPay(accountNumber: String,
                         nameOfAccount: String,
                         bankAccountType: BankAccountType,
                         routingNumber: String,
                         bankAccountNumber: String,
                         isUpdate: Bool,
                         completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil)))
    }
    
    
    func unenrollFromAutoPay(accountNumber: String,
                             reason: String,
                             completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil)))
        
    }
    
    func fetchWorkdays(completion: @escaping (_ result: ServiceResult<[Date]>) -> Void) {
        completion(ServiceResult.Success([Date()]))
    }
    
    func schedulePayment(payment: Payment, completion: @escaping (_ result: ServiceResult<String>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            completion(ServiceResult.Success(""))
        }
    }
    
    func scheduleBGEOneTimeCardPayment(accountNumber: String, paymentAmount: Double, paymentDate: Date, creditCard: CreditCard, completion: @escaping (ServiceResult<String>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            completion(ServiceResult.Success(""))
        }
    }
    
    func fetchPaymentDetails(accountNumber: String, paymentId: String, completion: @escaping (_ result: ServiceResult<PaymentDetail>) -> Void) {
        completion(.Success(PaymentDetail(walletItemId: "1234", paymentAmount: 100, paymentDate: Date(timeIntervalSince1970: 13))))
    }
    
    func updatePayment(paymentId: String, payment: Payment, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil)))
    }
    
    func cancelPayment(accountNumber: String, paymentId: String, bankOrCard: BankOrCard?, paymentDetail: PaymentDetail, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "", serviceMessage: nil, cause: nil)))
    }
    
    
}



