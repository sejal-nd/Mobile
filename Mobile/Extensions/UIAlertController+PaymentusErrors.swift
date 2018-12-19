//
//  UIAlertController+PaymentusErrors.swift
//  Mobile
//
//  Created by Marc Shilling on 12/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func paymentusErrorAlertController(forError error: ServiceError,
                                              walletItem: WalletItem,
                                              callHandler: @escaping ((UIAlertAction) -> ())) -> UIAlertController {
        let title: String
        let message: String
        var includeCallCTA = false
        
        switch error.serviceCode {
        case ServiceErrorCode.blockedPaymentMethod.rawValue:
            title = NSLocalizedString("Transaction Issue", comment: "")
            if walletItem.bankOrCard == .bank {
                message = NSLocalizedString("Please select another payment method. The previously selected payment method has been disabled and is not available.", comment: "")
            } else {
                message = String.localizedStringWithFormat("Please select another payment method. Card ending in %@ was declined.", walletItem.maskedWalletItemAccountNumber ?? "XXXX")
            }
            includeCallCTA = true
        case ServiceErrorCode.blockedUtilityAccount.rawValue:
            title = NSLocalizedString("Unable to process payment", comment: "")
            message = String.localizedStringWithFormat("Your utility account has been disabled and electronic payments are not available at this time. Please review other payment options or contact %@ customer service for further assistance.", Environment.shared.opco.displayString)
            includeCallCTA = true
        case ServiceErrorCode.blockedPaymentType.rawValue:
            title = NSLocalizedString("Blocked Payment Method", comment: "")
            message = String.localizedStringWithFormat("The %@ payment type selected is not available for use. Please select another payment method.", walletItem.bankOrCard == .bank ? "bank account" : "card")
        case ServiceErrorCode.duplicatePayment.rawValue:
            title = NSLocalizedString("Duplicate Payment", comment: "")
            message = NSLocalizedString("The transaction was blocked due to a duplicate payment submitted with the same payment amount, payment date, and payment method within the last 24 hours.", comment: "")
        case ServiceErrorCode.paymentAccountVelocity.rawValue:
            title = NSLocalizedString("Blocked Payment Method", comment: "")
            message = NSLocalizedString("The payment method selected is not available due to overuse. Please select another payment method.", comment: "")
        case ServiceErrorCode.utilityAccountVelocity.rawValue:
            title = NSLocalizedString("Unable to process payment", comment: "")
            message = String.localizedStringWithFormat("Your utility account has been disabled due to overuse and electronic payments are not available at this time. Please review other payment options or contact %@ customer service for further assistance.", Environment.shared.opco.displayString)
            includeCallCTA = true
        default:
            title = NSLocalizedString("Payment Error", comment: "")
            message = NSLocalizedString("Unable to process electronic payments for your account at this time. Please try again later or view other payment options.", comment: "")
        }
        
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if includeCallCTA {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: callHandler))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Call", comment: ""), style: .default, handler: callHandler))
        } else {
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        }
        return alert
    }
}

