//
//  AccountInfoBar.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountInfoBar: UIView {
    
    var label: UILabel!

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
        
        label = UILabel(frame: .zero)
        label.numberOfLines = 2
        label.textColor = .deepGray
        label.font = SystemFont.medium.of(textStyle: .subheadline)
        label.textAlignment = .center

        update()
        
        addSubview(label)
    }
    
    func update() {
        if let currentAccount = AccountsStore.sharedInstance.currentAccount {
            var labelText = "ACCOUNT \(currentAccount.accountNumber)"
            if let address = currentAccount.address {
                labelText.append("\n\(address)")
            }
            label.text = labelText
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
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
    }
}
