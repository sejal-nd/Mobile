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
    
    static func budgetBillingInfo(accountNumber: String) {
        ServiceLayer.request(router: .budgetBillingInfo(accountNumber: accountNumber)) { (result: Result<NewBudgetBilling, NetworkingError>) in
            switch result {
            case .success(let data):

                // fetch accounts todo

                print("NetworkTest POST BUDGET BILL INFO SUCCESS: \(data.isEnrolled) BREAK")

            case .failure(let error):
                print("NetworkTest POST BUDGET BILL INFO FAIL: \(error)")
                //                completion(.failure(error))
            }
        }
    }
    
    static func budgetBillingEnroll(accountNumber: String) {
        ServiceLayer.request(router: .budgetBillingEnroll(accountNumber: accountNumber)) { (result: Result<GenericResponse, NetworkingError>) in
            switch result {
            case .success(let data):

                // fetch accounts todo

                print("NetworkTest POST BUDGET BILL ENROLL SUCCESS: \(data.success) BREAK")

            case .failure(let error):
                print("NetworkTest POST BUDGET BILL UNENROLL FAIL: \(error)")
                //                completion(.failure(error))
            }
        }
    }
    
    static func budgetBillingUnenroll(accountNumber: String, reason: String) {
        let encodedObject = BudgetBillingUnenrollRequest(reason: reason, comment: "")
        
        ServiceLayer.request(router: .budgetBillingUnenroll(accountNumber: accountNumber, encodable: encodedObject)) { (result: Result<GenericResponse, NetworkingError>) in
            switch result {
            case .success(let data):
                
                // fetch accounts todo
                
                print("NetworkTest POST BUDGET BILL UNENROLL SUCCESS: \(data.success) BREAK")
                
            case .failure(let error):
                print("NetworkTest POST BUDGET BILL UNENROLL FAIL: \(error)")
                //                completion(.failure(error))
            }
        }
    }

    
//    static func autoPayUnenroll(accountNumber: String, reason: String) {
//
//    let httpBodyParameters: [String: Any] = ["reason": reason,
//                                             "comments": ""]
//        
//        do {
//            let httpBody = try JSONSerialization.data(withJSONObject: httpBodyParameters)
//            print("REQ SCHEDULE")
//            
//            ServiceLayer.request(router: .autoPayUnenroll(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<TODO, Error>) in
//                switch result {
//                case .success(let data):
//                    
//                    // fetch accounts todo
//                    
//                    print("NetworkTest POST 5  UNENROLL SUCCESS: \(data.message) BREAK")
//                    
//                case .failure(let error):
//                    print("NetworkTest POST 5 UNENROLL FAIL: \(error)")
//                    //                completion(.failure(error))
//                }
//            }
//        } catch let error {
//            print("Error encoding values: \(error)")
//            print("REQ ERROR")
//        }
//    }
    
    // POST.
    static func autoPay(accountNumber: String,
                        walletItemId: String?,
                        amountType: AmountType,
                        amountThreshold: String,
                        paymentDaysBeforeDue: String) {
//        var httpBodyParameters = ["amount_type": amountType.rawValue,
//                                  "payment_date_type": "before due",
//                                  "payment_days_before_due": paymentDaysBeforeDue,
//                                  "auto_pay_request_type": "Start"]
//
//        if let walletId = walletItemId {
//            httpBodyParameters["wallet_item_id"] = walletId
//        }
//        if amountType == .upToAmount {
//            httpBodyParameters["amount_threshold"] = amountThreshold
//        }
        
        let encodedObject = AutoPayEnrollRequest(amountType: amountType.rawValue,
                                                 paymentDateType: "before due",
                                                 paymentDaysBeforeDue: paymentDaysBeforeDue,
                                                 requestType: "Start", walletItemId: walletItemId,
                                                 amountThreshold: amountType == .upToAmount ? amountThreshold : nil)
        
            ServiceLayer.request(router: .autoPayEnroll(accountNumber: accountNumber, encodable: encodedObject)) { (result: Result<NewAutoPayResult, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 5 SUCCESS: \(data.message) BREAK")
                    
                case .failure(let error):
                    print("NetworkTest POST 5 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
    }
    
//    static func autoPayInfo(accountNumber: String) {
//        ServiceLayer.request(router: .autoPayInfo(accountNumber: accountNumber)) { (result: Result<TODO, Error>) in
//            switch result {
//            case .success(let data):
//
//                // fetch accounts todo
//
//                print("NetworkTest POST 5 INFO SUCCESS: \(data.message) BREAK")
//
//            case .failure(let error):
//                print("NetworkTest POST 5 INFO FAIL: \(error)")
//                //                completion(.failure(error))
//            }
//        }
//    }
    
    static func deleteWalletItem(walletItem : WalletItem) {
        let opCo = Environment.shared.opco
//        let httpBodyParameters: [String: Any] = [
//            "account_number": AccountsStore.shared.accounts[0].accountNumber,
//            "wallet_item_id": walletItem.walletItemId ?? "",
//            "masked_wallet_item_acc_num": walletItem.maskedWalletItemAccountNumber ?? "",
//            "biller_id": "\(opCo.rawValue)Registered",
//            "payment_category_type": walletItem.bankOrCard == .bank ? "check" : "credit"
//        ]
        
        let encodedObject = WalletItemDeleteRequest(accountNumber: AccountsStore.shared.accounts[0].accountNumber,
                                                    walletItemId: walletItem.walletItemId ?? "",
                                                    maskedWalletItemAccountNumber: walletItem.maskedWalletItemAccountNumber ?? "",
                                                    billerId: "\(opCo.rawValue)Registered",
                                                    paymentCategoryType: walletItem.bankOrCard == .bank ? "check" : "credit")
        
        print("REQ SCHEDULE")
            
            ServiceLayer.request(router: .deleteWalletItem(encodable: encodedObject)) { (result: Result<GenericResponse, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 4 SUCCESS: \(data.success) BREAK")
                    
                case .failure(let error):
                    print("NetworkTest POST 4 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
            
            //            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<NewBillingHistoryResult, Error>) in
            //                                                                            switch result {
            //                case .success(let data):
            //
            //                    // fetch accounts todo
            //
            //                    print("NetworkTest POST 2 SUCCESS: \(data.billingHistoryItems.count) BREAK")
            //                case .failure(let error):
            //                    print("NetworkTest POST 2 FAIL: \(error)")
            //                    //                completion(.failure(error))
            //                }
            //            }

    }
    
    static func pay(customerId: String,
                    bankOrCard: BankOrCard,
                    temporary: Bool,
                    isWalletEmpty: Bool,
                    walletItemId: String? = nil) {
//        var httpBodyParameters = [
//            "pmCategory": bankOrCard == .bank ? "DD" : "CC", // "DC" = Debit Card
//            "postbackUrl": "",
//        ]
//
//        var strParameters = "pageView=mobile;postMessagePmDetailsOrigin=\(Environment.shared.mcsConfig.paymentusUrl);"
//        if temporary {
//            strParameters += "nickname=false;primaryPM=false;"
//        } else {
//            if isWalletEmpty { // If wallet is empty, hide the default checkbox because Paymentus automatically sets first wallet items as default
//                strParameters += "primaryPM=false;"
//            }
//            httpBodyParameters["ownerId"] = customerId
//        }
//        httpBodyParameters["strParam"] = strParameters
//
//        if let wid = walletItemId { // Indicates that this is an edit operation (as opposed to an add)
//            httpBodyParameters["wallet_item_id"] = wid
//        }
        
        var ownerId: String?
        var walletItemId: String?
        
        var stringParameters = "pageView=mobile;postMessagePmDetailsOrigin=\(Environment.shared.mcsConfig.paymentusUrl);"
        if temporary {
            stringParameters += "nickname=false;primaryPM=false;"
        } else {
            if isWalletEmpty { // If wallet is empty, hide the default checkbox because Paymentus automatically sets first wallet items as default
                stringParameters += "primaryPM=false;"
            }
            ownerId = customerId
        }
        
        if let wid = walletItemId { // Indicates that this is an edit operation (as opposed to an add)
            walletItemId = wid
        }
        
        // "DC" = Debit Card
        let encodedObject = PaymentRequest(category: bankOrCard == .bank ? "DD" : "CC",
                                           postbackURL: "",
                                           ownerId: ownerId,
                                           stringParameter: stringParameters,
                                           walletItemId: walletItemId)
        
            print("REQ SCHEDULE")
            
            ServiceLayer.request(router: .payment(encodable: encodedObject)) { (result: Result<NewPaymentResult, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 3 SUCCESS: \(data.data) BREAK")
                    
                case .failure(let error):
                    print("NetworkTest POST 3 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
            
            //            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<NewBillingHistoryResult, Error>) in
            //                                                                            switch result {
            //                case .success(let data):
            //
            //                    // fetch accounts todo
            //
            //                    print("NetworkTest POST 2 SUCCESS: \(data.billingHistoryItems.count) BREAK")
            //                case .failure(let error):
            //                    print("NetworkTest POST 2 FAIL: \(error)")
            //                    //                completion(.failure(error))
            //                }
            //            }
    }
    
    
    static func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date) {
        
        let startDateString = DateFormatter.yyyyMMddFormatter.string(from: startDate)
        let endDateString = DateFormatter.yyyyMMddFormatter.string(from: endDate)
        
//        var httpBodyParameters = [
//            "start_date": startDateString,
//            "end_date": endDateString,
//            "statement_type": "03"
//        ]
        
        let opCo = Environment.shared.opco
        var billerId: String?
        if opCo == .comEd || opCo == .peco {
            billerId = "\(opCo.rawValue)Registered"
        }
        
        
        
        let encodedObject = BillingHistoryRequest(startDate: startDateString,
                                                  endDate: endDateString,
                                                  statementType: "03",
                                                  billerId: billerId)
            print("REQ SCHEDULE")
            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, encodable: encodedObject)) { (result: Result<NewBillingHistoryResult, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 2 SUCCESS: \(data.billingHistoryItems.count) BREAK")
                case .failure(let error):
                    print("NetworkTest POST 2 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
    }
    
    static func schedulePayment(accountNumber: String,
                                paymentAmount: Double,
                                paymentDate: Date,
                                walletId: String,
                                walletItem: WalletItem) {
        print("payment service schedule")
        let opCo = Environment.shared.opco
        
//        let httpBodyParameters: [String: Any] = [
//            "payment_amount": String.init(format: "%.02f", paymentAmount),
//            "payment_date": paymentDate.paymentFormatString,
//            "payment_category_type": walletItem.bankOrCard == .bank ? "Check" : "Credit",
//            "wallet_id": walletId,
//            "wallet_item_id": walletItem.walletItemId ?? "",
//            "is_existing_account": !walletItem.isTemporary,
//            "biller_id": "\(opCo.rawValue)Registered",
//            "masked_wallet_item_account_number": walletItem.maskedWalletItemAccountNumber ?? ""
//        ]
        
        let encodedObject = ScheduledPaymentUpdateRequest(paymentAmount: String.init(format: "%.02f", paymentAmount),
                                                          paymentDate: paymentDate.paymentFormatString,
                                                          paymentCategoryType: walletItem.bankOrCard == .bank ? "Check" : "Credit",
                                                          walletId: walletId,
                                                          billerId: "\(opCo.rawValue)Registered",
            walletItemId: walletItem.walletItemId ?? "",
            isExistingAccount: !walletItem.isTemporary,
            maskedWalletItemAccountNumber: walletItem.maskedWalletItemAccountNumber ?? "")
        
            ServiceLayer.request(router: .scheduledPayment(accountNumber: accountNumber,
                                                           encodable: encodedObject)) { (result: Result<GenericResponse, NetworkingError>) in
                                                            switch result {
                                                            case .success(let data):
                                                                
                                                                // fetch accounts todo
                                                                
                                                                print("NetworkTest POST 1 SUCCESS: \(data.confirmationNumber) BREAK")
                                                            case .failure(let error):
                                                                print("NetworkTest POST 1 FAIL: \(error)")
                                                                //                completion(.failure(error))
                                                            }
            }

    }
    
    static func cancelSchduledPayment(accountNumber: String, paymentAmount: Double, paymentId: String) {
//        let httpBodyParameters: [String: Any] = [
//            "payment_amount":
//        ]
        
        let encodedObject = SchedulePaymentCancelRequest(paymentAmount: String.init(format: "%.02f", paymentAmount))

            ServiceLayer.request(router: .scheduledPaymentDelete(accountNumber: accountNumber, paymentId: paymentId,
                                                                 encodable: encodedObject)) { (result: Result<GenericResponse, NetworkingError>) in
                                                                    switch result {
                                                                    case .success(let data):
                                                                        
                                                                        // fetch accounts todo
                                                                        
                                                                        print("NetworkTest POST 1 CANCEL SUCCESS: \(data.confirmationNumber) BREAK")
                                                                    case .failure(let error):
                                                                        print("NetworkTest POST 1 CANCEL FAIL: \(error)")
                                                                        //                completion(.failure(error))
                                                                    }
            }
        
    }
    
    static func updateScheduledPayment(paymentId: String,
                                       accountNumber: String,
                                       paymentAmount: Double,
                                       paymentDate: Date,
                                       walletId: String,
                                       walletItem: WalletItem) {
        let opCo = Environment.shared.opco
//        var httpBodyParameters: [String: Any] = [
//            "payment_amount": String.init(format: "%.02f", paymentAmount),
//            "payment_date": paymentDate.paymentFormatString,
//            "payment_category_type": walletItem.bankOrCard == .bank ? "Check" : "Credit",
//            "payment_id": paymentId,
//            "wallet_id": walletId,
//            "biller_id": "\(opCo.rawValue)Registered"
//        ]
//
//        if !walletItem.isEditingItem, let walletItemId = walletItem.walletItemId { // User selected a new payment method
//            httpBodyParameters["wallet_item_id"] = walletItemId
//            httpBodyParameters["is_existing_account"] = !walletItem.isTemporary
//            httpBodyParameters["masked_wallet_item_account_number"] = walletItem.maskedWalletItemAccountNumber ?? ""
//        }

        var  newWalletItemId: String? = nil
        var isExistingAccount: Bool? = nil
        var maskedWalletItemAccountNumber: String? = nil
        if !walletItem.isEditingItem, let walletItemId = walletItem.walletItemId { // User selected a new payment method
            newWalletItemId = walletItemId
            isExistingAccount = !walletItem.isTemporary
            maskedWalletItemAccountNumber = walletItem.maskedWalletItemAccountNumber ?? ""
        }
        
        let encodedObject = ScheduledPaymentUpdateRequest(paymentAmount: String.init(format: "%.02f", paymentAmount),
                                                          paymentDate: paymentDate.paymentFormatString, paymentCategoryType: walletItem.bankOrCard == .bank ? "Check" : "Credit",
                                                          paymentId: paymentId,
                                                          walletId: walletId, billerId: "\(opCo.rawValue)Registered",
            walletItemId: newWalletItemId, isExistingAccount: isExistingAccount,
            maskedWalletItemAccountNumber: maskedWalletItemAccountNumber)
        
            print("REQ SCHEDULE")
            ServiceLayer.request(router: .scheduledPaymentUpdate(accountNumber: accountNumber, paymentId: paymentId, encodable: encodedObject)) { (result: Result<GenericResponse, NetworkingError>) in
                switch result {
                case .success(let data):

                    // fetch accounts todo

                    print("NetworkTest POST 1 UPDATE SUCCESS: \(data.confirmationNumber) BREAK")
                case .failure(let error):
                    print("NetworkTest POST 1 UPDDATE FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }

    }
    
}
