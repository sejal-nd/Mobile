//
//  UIAlertViewController+FiservCutoff.swift
//  Mobile
//
//  Created by Samuel Francis on 11/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func fiservCutoffAlert(handler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let message = String.localizedStringWithFormat("Payment via the mobile application is temporarily unavailable. Please check if there is an update available in the app store. You can make a payment on the %@ website if needed. Sorry for the inconvenience.", Environment.shared.opco.displayString)
        
        let alert = UIAlertController(title: NSLocalizedString("Payment Temporarily Unavailable", comment: ""),
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default , handler: handler))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Open App Store", comment: ""), style: .default , handler: {
            handler?($0)
            UIApplication.shared.openUrlIfCan(Environment.shared.opco.appStoreLink)
        }))
        return alert
    }
}
