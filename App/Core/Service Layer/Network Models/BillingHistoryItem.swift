//
//  BillingHistoryItem.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct BillingHistoryItem: Codable {
    let amountPaid: Double?
    let billerID: String?
    let ccfGas: String?
    let chargeAmount: Double?
    let date: Date
    let welcomeDescription: String?
    let kwhElec: Double?
    let maskedAccountNumber: String?
    let outstandingBalance: Double?
    let paymentID: String?
    let statusString: String?
    let totalAmountDue: Double?
    let walletID: String?
    let walletItemID: String?
    let paymentType: String?
    let confirmationNumber: String?
    let type: String?
    let encryptedPaymentID: String?
    let documentID: String?
    let convenienceFee: Double?
    let totalAmount: Double?
    let channelCode: String?
    let paymentMethod: String?
    let flagAllowDeletes: String?
    let flagAllowEdits: String?
    
    enum CodingKeys: String, CodingKey {
        case amountPaid = "amount_paid"
        case billerID = "biller_id"
        case ccfGas = "ccf_gas"
        case chargeAmount = "charge_amount"
        case date = "date"
        case welcomeDescription = "description"
        case kwhElec = "kwh_elec"
        case maskedAccountNumber = "masked_wallet_item_account_number"
        case outstandingBalance = "outstanding_balance"
        case paymentID = "payment_id"
        case statusString = "status"
        case totalAmountDue = "total_amount_due"
        case walletID = "wallet_id"
        case walletItemID = "wallet_item_id"
        case paymentType = "payment_type"
        case confirmationNumber = "confirmation_number"
        case type = "type"
        case encryptedPaymentID = "encrypted_payment_id"
        case documentID = "documentID"
        case convenienceFee = "convenience_fee"
        case totalAmount = "total_amount"
        case channelCode = "channel_code"
        case paymentMethod = "payment_method"
        case flagAllowDeletes = "flag_allow_deletes"
        case flagAllowEdits = "flag_allow_edits"
    }
    
    var isAutoPayPayment: Bool {
        return channelCode == "SCHEDULED_PAYMENT"
    }
    
    var isFuelFundDonation: Bool {
        return channelCode == "FFD"
    }
    
    var isBillPDF: Bool {
        return type == "billing"
    }
    
    var paymentMethodType: PaymentMethodType? {
        if let paymentTypeStr = paymentType {
            return paymentMethodTypeForPaymentusString(paymentTypeStr)
        }
        
        return nil
    }
    
    var status: BillingHistoryStatus {
        return BillingHistoryStatus(identifier: statusString)
    }
    
    enum BillingHistoryStatus: String, Codable {
        case scheduled
        case pending
        case success
        case failed
        case canceled
        case returned
        case refunded
        case unknown
        
        init(identifier: String?) {
            guard let id = identifier?.lowercased() else {
                self = .unknown
                return
            }
            
            switch id {
            case "scheduled":
                self = .scheduled
            case "pending":
                self = .pending
            case "posted", "accepted":
                self = .success
            case "failed", "declined":
                self = .failed
            case "cancelled", "void":
                self = .canceled
            case "returned":
                self = .returned
            case "refunded":
                self = .refunded
            default:
                self = .unknown
            }
        }
    }
    
    var isFuture: Bool {
        if isBillPDF { // EM-2638: Bills should always be in the past
            return false
        }
        
        switch status {
        case .scheduled, .pending:
            return true
        case .success, .failed, .canceled, .returned, .refunded, .unknown:
            return false
        }
    }
}
