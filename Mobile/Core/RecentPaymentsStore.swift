//
//  PaymentDetailsStore.swift
//  Mobile
//
//  Created by Sam Francis on 7/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct PaymentDetails: Mappable {
    let amount: Double
    let date: Date
    
    init(map: Mapper) throws {
        amount = try map.from("amount")
        date = try map.from("date", transformation: PaymentDetails.extractDate)
    }
    
    init(amount: Double, date: Date) {
        self.amount = amount
        self.date = date
    }
    
    private static func extractDate(object: Any?) throws -> Date {
        guard let dateString = object as? String else {
            throw MapperError.convertibleError(value: object, type: Date.self)
        }
        return dateString.apiFormatDate
    }
}

class RecentPaymentsStore {
    
    private let paymentTimeLimit: TimeInterval = 86_400 // 24 hours
    
    static let shared = RecentPaymentsStore()
    
    // Private init protects against another instance being accidentally instantiated
    private init() { }
    
    private var paymentDetailsCache = [String: PaymentDetails]()
    
    subscript(account: Account) -> PaymentDetails? {
        get {
            if let paymentDetails = paymentDetailsCache[account.accountNumber] {
                if paymentDetails.date.addingTimeInterval(paymentTimeLimit) > Date() {
                    return paymentDetails
                } else {
                    removePaymentDetails(forAccount: account)
                    return nil
                }
            } else if let paymentDetailsDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.PaymentDetailsDictionary),
                let paymentDictionary = paymentDetailsDictionary[account.accountNumber] as? NSDictionary,
                let paymentDetails = PaymentDetails.from(paymentDictionary) {
                
                if paymentDetails.date.addingTimeInterval(paymentTimeLimit) > Date() {
                    paymentDetailsCache[account.accountNumber] = paymentDetails
                    return paymentDetails
                } else {
                    removePaymentDetails(forAccount: account)
                    return nil
                }
            } else {
                return nil
            }
        }
        set(newValue) {
            paymentDetailsCache[account.accountNumber] = newValue
            
            var paymentDetailsDictionary = [String: Any]()
            if let existingDict = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.PaymentDetailsDictionary) {
                paymentDetailsDictionary = existingDict
            }
            
            if let paymentDetails = newValue {
                paymentDetailsDictionary[account.accountNumber] = [
                    "amount": paymentDetails.amount,
                    "date": paymentDetails.date.apiFormatString
                ]
                UserDefaults.standard.set(paymentDetailsDictionary, forKey: UserDefaultKeys.PaymentDetailsDictionary)
            } else {
                paymentDetailsDictionary.removeValue(forKey: account.accountNumber)
                UserDefaults.standard.set(paymentDetailsDictionary, forKey: UserDefaultKeys.PaymentDetailsDictionary)
            }
            
        }
    }
    
    private func removePaymentDetails(forAccount account: Account) {
        paymentDetailsCache.removeValue(forKey: account.accountNumber)
        var paymentDetailsDictionary = [String: Any]()
        if let existingDict = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.PaymentDetailsDictionary) {
            paymentDetailsDictionary = existingDict
        }
        paymentDetailsDictionary.removeValue(forKey: account.accountNumber)
        UserDefaults.standard.set(paymentDetailsDictionary, forKey: UserDefaultKeys.PaymentDetailsDictionary)
    }
    
}
