////
////  NewBillingHistoryItem.swift
////  Mobile
////
////  Created by Joseph Erlandson on 3/9/20.
////  Copyright © 2020 Exelon Corporation. All rights reserved.
////
//
//import Foundation
//
//enum NewBillingHistoryStatus {
//    case scheduled
//    case pending
//    case success
//    case failed
//    case canceled
//    case returned
//    case refunded
//    case unknown
//    
//    init(identifier: String?) {
//        guard let id = identifier?.lowercased() else {
//            self = .unknown
//            return
//        }
//        
//        switch id {
//        case "scheduled":
//            self = .scheduled
//        case "pending":
//            self = .pending
//        case "posted", "accepted":
//            self = .success
//        case "failed", "declined":
//            self = .failed
//        case "cancelled", "void":
//            self = .canceled
//        case "returned":
//            self = .returned
//        case "refunded":
//            self = .refunded
//        default:
//            self = .unknown
//        }
//    }
//}
//
//struct NewBillingHistoryItem: Codable {
//    let amountPaid: Double?
//    let date: Date
//    let description: String?
//    let maskedWalletItemAccountNumber: String?
//    let paymentId: String?
//    let statusString: String?
//    let status: NewBillingHistoryStatus
//    let totalAmountDue: Double? // Only sent when isBillPDF = true
//    let paymentMethodType: NewPaymentMethodType?
//    let confirmationNumber: String?
//    let convenienceFee: Double?
//    let totalAmount: Double?
//    
//    let isAutoPayPayment: Bool
//    let isFuelFundDonation: Bool
//    let isBillPDF: Bool
//    
//    var isFuture: Bool {
//        if isBillPDF { // EM-2638: Bills should always be in the past
//            return false
//        }
//        
//        switch status {
//        case .scheduled, .pending:
//            return true
//        case .success, .failed, .canceled, .returned, .refunded, .unknown:
//            return false
//        }
//    }
//}
//
