//
//  AccountInfoBar.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/18/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountInfoBarNew: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(AccountInfoBarNew.className, owner: self, options: nil)
        
        self.frame = contentView.frame
        addSubview(contentView)
        
        style()
        
        let currentAccount = AccountsStore.shared.currentAccount
        configure(accountNumberText: currentAccount.accountNumber, addressText: currentAccount.address)
    }
    
    private func style() {
        accountNumberLabel.textColor = .deepGray
        accountNumberLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        addressLabel.textColor = .deepGray
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
    }
}


// MARK: - Public API

extension AccountInfoBarNew {
    public func configure(accountNumberText: String, addressText: String?) {
        accountNumberLabel.text = NSLocalizedString("Account \(accountNumberText)", comment: "")
        accountNumberLabel.accessibilityLabel = "Account number: \(accountNumberText)"
        addressLabel.text = NSLocalizedString("\(addressText ?? "")", comment: "")
        if let addressText = addressText {
            addressLabel.accessibilityLabel = "Street address: \(addressText)"
        }
    }
}
