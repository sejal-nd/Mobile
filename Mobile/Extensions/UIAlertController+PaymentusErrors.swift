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
            title = NSLocalizedString("Payment Method Declined", comment: "")
            if walletItem.bankOrCard == .bank {
                message = NSLocalizedString("Please select another payment method. The previously selected payment method has been disabled and is not available.", comment: "")
            } else {
                if let maskedNum = walletItem.maskedWalletItemAccountNumber {
                    message = String.localizedStringWithFormat("Please select another payment method. Card ending in %@ was declined.", maskedNum)
                } else { // Should never happen, but just in case
                    message = NSLocalizedString("Please select another payment method. Card was declined.", comment: "")
                }
            }
        case ServiceErrorCode.blockedUtilityAccount.rawValue:
            title = NSLocalizedString("Unable to process electronic payments", comment: "")
            message = String.localizedStringWithFormat("Your utility account has been disabled and electronic payments are not available at this time. Please review other payment options, or contact %@ customer service for further assistance.", Environment.shared.opco.displayString)
            includeCallCTA = true
        case ServiceErrorCode.blockedPaymentType.rawValue:
            title = NSLocalizedString("Payment Method Unavailable", comment: "")
            message = String.localizedStringWithFormat("%@ payments are not available on your account at this time. Please select another payment method or contact %@ customer service.", walletItem.paymentMethodType.displayString, Environment.shared.opco.displayString)
            includeCallCTA = true
        case ServiceErrorCode.duplicatePayment.rawValue:
            title = NSLocalizedString("Duplicate Payment", comment: "")
            message = String.localizedStringWithFormat("Recent transaction blocked due to duplicate payment. Matching amount using the same %@ was submitted within the last 24 hours.", walletItem.paymentCategoryType.displayString)
        case ServiceErrorCode.paymentAccountVelocityBank.rawValue:
            fallthrough
        case ServiceErrorCode.paymentAccountVelocityCard.rawValue:
            title = NSLocalizedString("Please select another payment method", comment: "")
            message = NSLocalizedString("Electronic payments with this payment method are not available at this time due to overuse.", comment: "")
        case ServiceErrorCode.utilityAccountVelocity.rawValue:
            title = NSLocalizedString("Unable to process electronic payments", comment: "")
            message = String.localizedStringWithFormat("Electronic payments for your utility account are not available at this time due to overuse. Please review other payment options, or contact %@ customer service for further assistance.", Environment.shared.opco.displayString)
            includeCallCTA = true
        default:
            title = NSLocalizedString("Payment Error", comment: "")
            message = NSLocalizedString("Unable to process electronic payments for your account at this time. Please try again later or view other payment options.", comment: "")
        }
        
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if includeCallCTA {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Call", comment: ""), style: .default, handler: callHandler))
        } else {
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        }
        return alert
    }
}

