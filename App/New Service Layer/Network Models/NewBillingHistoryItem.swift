//
//  NewBillingHistoryItem.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewBillingHistoryItem: Codable {
    let amountPaid: Double?
    let billerID: String?
    let ccfGas: String?
    let chargeAmount: String?
    let date: String?
    let welcomeDescription: String?
    let kwhElec: String?
    let maskedWalletItemAccountNumber: String?
    let outstandingBalance: String?
    let paymentID: String?
    let status: String?
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
        case maskedWalletItemAccountNumber = "masked_wallet_item_account_number"
        case outstandingBalance = "outstanding_balance"
        case paymentID = "payment_id"
        case status = "status"
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
}
