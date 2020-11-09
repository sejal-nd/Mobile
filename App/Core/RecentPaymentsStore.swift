//
//  PaymentDetailsStore.swift
//  Mobile
//
//  Created by Sam Francis on 7/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct PaymentDetails: Codable {
    let amount: Double
    let date: Date
    let confirmationNumber: String

    init?(dict: [String: Any]) {
        guard let amount = dict["amount"] as? Double,
            let dateString = dict["date"] as? String,
            let confirmationNumber = dict["confirmationNumber"] as? String else { return nil }
        self.amount = amount
        self.date = dateString.extractDate() ?? Date()
        self.confirmationNumber = confirmationNumber
    }
    
    init(amount: Double, date: Date, confirmationNumber: String) {
        self.amount = amount
        self.date = date
        self.confirmationNumber = confirmationNumber
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
                if paymentDetails.date.addingTimeInterval(paymentTimeLimit) > .now {
                    return paymentDetails
                } else {
                    removePaymentDetails(forAccount: account)
                    return nil
                }
            } else if let paymentDetailsDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.paymentDetailsDictionary),
                let paymentDictionary = paymentDetailsDictionary[account.accountNumber] as? [String: Any],
                let paymentDetails = PaymentDetails(dict: paymentDictionary) {
                
                if paymentDetails.date.addingTimeInterval(paymentTimeLimit) > .now {
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
            if let existingDict = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.paymentDetailsDictionary) {
                paymentDetailsDictionary = existingDict
            }
            
            if let paymentDetails = newValue {
                paymentDetailsDictionary[account.accountNumber] = [
                    "amount": paymentDetails.amount,
                    "date": paymentDetails.date.apiFormatString,
                    "confirmationNumber": paymentDetails.confirmationNumber
                ]
                UserDefaults.standard.set(paymentDetailsDictionary, forKey: UserDefaultKeys.paymentDetailsDictionary)
            } else {
                paymentDetailsDictionary.removeValue(forKey: account.accountNumber)
                UserDefaults.standard.set(paymentDetailsDictionary, forKey: UserDefaultKeys.paymentDetailsDictionary)
            }
            
        }
    }
    
    private func removePaymentDetails(forAccount account: Account) {
        paymentDetailsCache.removeValue(forKey: account.accountNumber)
        var paymentDetailsDictionary = [String: Any]()
        if let existingDict = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.paymentDetailsDictionary) {
            paymentDetailsDictionary = existingDict
        }
        paymentDetailsDictionary.removeValue(forKey: account.accountNumber)
        UserDefaults.standard.set(paymentDetailsDictionary, forKey: UserDefaultKeys.paymentDetailsDictionary)
    }
    
}
