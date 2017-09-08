//
//  AccountInfoBar.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountInfoBar: UIView {
    
    var label = UILabel(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .softGray
        
        label.numberOfLines = 2
        label.textColor = .deepGray
        label.font = SystemFont.medium.of(textStyle: .subheadline)
        label.textAlignment = .center

        update()
        
        addSubview(label)
    }
    
    func update(accountNumber: String? = nil, address: String? = nil) {
        if let overrideAccount = accountNumber, let overrideAddress = address {
            label.text = "ACCOUNT \(overrideAccount)\n\(overrideAddress)"
            label.accessibilityLabel = "Account number: \(overrideAccount), Street address: \(overrideAddress)"
        } else if let currentAccount = AccountsStore.sharedInstance.currentAccount {
            var a11y = ""
            var labelText = "ACCOUNT \(currentAccount.accountNumber)"
            a11y.append("Account number: \(currentAccount.accountNumber)")
            if let address = currentAccount.address {
                labelText.append("\n\(address)")
                a11y.append(", Street address: \(address)")
            }
            label.text = labelText
            label.accessibilityLabel = a11y
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        addBottomBorder(color: .accentGray, width: 1)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let leadingConstraint = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        leadingConstraint.priority = 999
        leadingConstraint.isActive = true
        
        let trailingConstraint = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        trailingConstraint.priority = 999
        trailingConstraint.isActive = true
        
        label.widthAnchor.constraint(lessThanOrEqualToConstant: 460).isActive = true
    }
}
