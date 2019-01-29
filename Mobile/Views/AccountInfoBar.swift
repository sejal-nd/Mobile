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
        var a11y = ""
        if let overrideAccount = accountNumber {
            var labelText = "ACCOUNT \(overrideAccount)"
            a11y.append("Account number: \(overrideAccount)")
            if let overrideAddress = address {
                labelText.append("\n\(overrideAddress)")
                a11y.append(", Street address: \(overrideAddress)")
            }
            label.text = labelText
            label.accessibilityLabel = a11y
        } else if AccountsStore.shared.currentIndex != nil {
            let currentAccount = AccountsStore.shared.currentAccount
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
        
        label.addTabletWidthConstraints(horizontalPadding: 8)
    }
    
    override var isHidden: Bool {
        didSet {
            label.isAccessibilityElement = !isHidden
        }
    }
}
