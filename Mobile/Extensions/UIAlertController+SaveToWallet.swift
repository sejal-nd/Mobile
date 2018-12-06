//
//  UIAlertController+SaveToWallet.swift
//  Mobile
//
//  Created by Marc Shilling on 12/5/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func saveToWalletActionSheet(bankOrCard: BankOrCard,
                                        saveHandler: @escaping ((UIAlertAction) -> ()),
                                        dontSaveHandler: @escaping ((UIAlertAction) -> ())) -> UIAlertController {
        let title = bankOrCard == .bank ?
            NSLocalizedString("Add Bank Account", comment: "") :
            NSLocalizedString("Add Credit/Debit Card", comment: "")
        let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
        let alert = UIAlertController(title: title, message: nil, preferredStyle: style)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Save to My Wallet", comment: ""), style: .default, handler: saveHandler))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Don't Save to My Wallet", comment: ""), style: .default, handler: dontSaveHandler))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        return alert
    }
}
