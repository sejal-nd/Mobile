//
//  BGEAutoPayInfo.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

enum AmountType: String {
    case upToAmount = "upto amount"
    case amountDue = "amount due"
}

struct BGEAutoPayInfo: Mappable {
    let walletItemId: String?
    let paymentAccountNickname: String?
    let paymentAccountLast4: String?
    let amountType: AmountType?
    let amountThreshold: Double?
    let paymentDaysBeforeDue: Int?
    let confirmationNumber: String
    
    init(map: Mapper) throws {
        walletItemId = map.optionalFrom("wallet_item_id")
        paymentAccountNickname = map.optionalFrom("payment_acount") // Yes, this is mispelled
        paymentAccountLast4 = map.optionalFrom("masked_account_number", transformation: extractLast4)
        amountType = map.optionalFrom("amount_type")
        amountThreshold = map.optionalFrom("amount_threshold") { object in
            guard let string = object as? String else {
                throw MapperError.convertibleError(value: object, type: String.self)
            }
            
            guard let double = Double(string) else {
                throw MapperError.convertibleError(value: string, type: Double.self)
            }
            
            return double
        }
        
        paymentDaysBeforeDue = map.optionalFrom("payment_days_before_due") { object in
            guard let string = object as? String else {
                throw MapperError.convertibleError(value: object, type: String.self)
            }
            
            guard let int = Int(string) else {
                throw MapperError.convertibleError(value: string, type: Int.self)
            }
            
            return int
        }
        
        confirmationNumber = try map.from("confirmation_number")
    }
}
