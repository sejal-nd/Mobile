//
//  WalletViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 5/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

class WalletViewModel {

    required init() {

    }
    
    var footerLabelText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.\n\nBank account verification may take up to three business days. Once activated, we will notify you via email and you may then enroll in AutoPay or begin scheduling payments for free.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("We accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
    }
}
