//
//  AuthenticatedService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// NOTE: The location of these static methods are subject to change

struct PaymentServiceNew {
    
    static func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date) {
        
        let startDateString = DateFormatter.yyyyMMddFormatter.string(from: startDate)
        let endDateString = DateFormatter.yyyyMMddFormatter.string(from: endDate)
        
        var httpBodyParameters = [
            "start_date": startDateString,
            "end_date": endDateString,
            "statement_type": "03"
        ]
        
        let opCo = Environment.shared.opco
        if opCo == .comEd || opCo == .peco {
            httpBodyParameters["biller_id"] = "\(opCo.rawValue)Registered"
        }
        
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: httpBodyParameters)
            print("REQ SCHEDULE")
            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<NewBillingHistoryResult, Error>) in
                                                                            switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 2 SUCCESS: \(data.billingHistoryItems.count) BREAK")
                case .failure(let error):
                    print("NetworkTest POST 2 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
        } catch let error {
            print("Error encoding values: \(error)")
            print("REQ ERROR")
        }
    }
    
    static func schedulePayment(accountNumber: String,
                                paymentAmount: Double,
                                paymentDate: Date,
                                walletId: String,
                                walletItem: WalletItem) {
        print("payment service schedule")
        let opCo = Environment.shared.opco
        
        let httpBodyParameters: [String: Any] = [
            "payment_amount": String.init(format: "%.02f", paymentAmount),
            "payment_date": paymentDate.paymentFormatString,
            "payment_category_type": walletItem.bankOrCard == .bank ? "Check" : "Credit",
            "wallet_id": walletId,
            "wallet_item_id": walletItem.walletItemId ?? "",
            "is_existing_account": !walletItem.isTemporary,
            "biller_id": "\(opCo.rawValue)Registered",
            "masked_wallet_item_account_number": walletItem.maskedWalletItemAccountNumber ?? ""
        ]
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: httpBodyParameters)
            print("REQ SCHEDULE")
            ServiceLayer.request(router: .scheduledPayment(accountNumber: accountNumber,
                                                           httpBody: httpBody)) { (result: Result<NewScheduledPaymentResult, Error>) in
                                                            switch result {
                                                            case .success(let data):
                                                                
                                                                // fetch accounts todo
                                                                
                                                                print("NetworkTest POST 1 SUCCESS: \(data.confirmationNumber) BREAK")
                                                            case .failure(let error):
                                                                print("NetworkTest POST 1 FAIL: \(error)")
                                                                //                completion(.failure(error))
                                                            }
            }
        } catch let error {
            print("Error encoding values: \(error)")
            print("REQ ERROR")
        }
    }
    
}
