//
//  AuthenticatedService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public enum PaymentService {
    
    static func autoPayInfo(accountNumber: String, completion: @escaping (Result<BGEAutoPayInfo, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayInfo(accountNumber: accountNumber), completion: completion)
    }
    
    static func autoPayEnroll(accountNumber: String, request: AutoPayEnrollRequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        var router: Router
        
        if request.isUpdate {
            router = .updateAutoPay(accountNumber: accountNumber, request: request)
        }
        else {
            router = .autoPayEnroll(accountNumber: accountNumber, request: request)
        }
        
        NetworkingLayer.request(router: router, completion: completion)
    }
    
    static func enrollAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayEnrollBGE(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func updateAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .updateAutoPayBGE(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func autoPayUnenroll(accountNumber: String, request: AutoPayUnenrollRequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayUnenroll(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func schedulePayment(accountNumber: String, request: ScheduledPaymentUpdateRequest, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .scheduledPayment(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func cancelSchduledPayment(accountNumber: String, paymentId: String, request: SchedulePaymentCancelRequest, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
            NetworkingLayer.request(router: .scheduledPaymentDelete(accountNumber: accountNumber, paymentId: paymentId, request: request), completion: completion)
    }
    
    static func updateScheduledPayment(paymentId: String, accountNumber: String, request: ScheduledPaymentUpdateRequest, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
            NetworkingLayer.request(router: .scheduledPaymentUpdate(accountNumber: accountNumber, paymentId: paymentId, request: request), completion: completion)
    }
}
