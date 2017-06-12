//
//  AccountDetailsView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountDetailsView: UIView {

    @IBOutlet weak var dividerLine: UIView!

    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var streetNumberLabel: UILabel!
    @IBOutlet weak var unitNumberLabel: UILabel!
    
    override func awakeFromNib() {
        dividerLine.backgroundColor = .accentGray
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 375, height: 73)
    }
    
    static func create(withAccount account: AccountLookupResult) -> AccountDetailsView {
        let view = Bundle.main.loadViewFromNib() as AccountDetailsView
        
        view.bind(withAccount: account)
        
        return view
    }
    
    private func bind(withAccount account: AccountLookupResult) {
        accountNumberLabel.text = "****\(account.accountNumber ?? "0000")"
        accountNumberLabel.font = SystemFont.bold.of(textStyle: .headline)

        streetNumberLabel.text = account.streetNumber
        streetNumberLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        unitNumberLabel.text = account.unitNumber
        unitNumberLabel.font = SystemFont.regular.of(textStyle: .headline)
    }
}
