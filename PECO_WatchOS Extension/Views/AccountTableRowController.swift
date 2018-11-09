//
//  AddressTableRowController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class AccountTableRowController: NSObject {
    
    @IBOutlet var checkmarkImageView: WKInterfaceImage!
    @IBOutlet var imageView: WKInterfaceImage!
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var detailLabel: WKInterfaceLabel!
    
    
    // MARK: - Configuration
    
    public func configure(account: Account) {
        titleLabel.setText(account.accountNumber)
        detailLabel.setText(account.address)
        imageView.setImageNamed(account.isResidential ? AppImage.residential.name : AppImage.commercial.name)
        
        guard let currentAccount = AccountsStore.shared.currentAccount else {
            checkmarkImageView.setHidden(true)
            return
        }
        checkmarkImageView.setHidden(currentAccount == account ? false : true)
    }
    
}
