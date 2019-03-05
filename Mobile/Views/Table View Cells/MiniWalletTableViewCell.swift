//
//  MiniWalletTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MiniWalletTableViewCell: UITableViewCell {
    
    @IBOutlet weak var innerContentView: ButtonControl!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var expiredView: UIView!
    @IBOutlet weak var expiredLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        innerContentView.layer.cornerRadius = 10
        innerContentView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        innerContentView.backgroundColorOnPress = .softGray
        
        iconImageView.image = #imageLiteral(resourceName: "opco_bank_mini")
        
        accountNumberLabel.font = SystemFont.medium.of(textStyle: .headline)
        accountNumberLabel.textColor = .blackText
        nicknameLabel.font = SystemFont.medium.of(textStyle: .footnote)
        nicknameLabel.textColor = .middleGray
        
        checkmarkImageView.isHidden = true
        
        expiredView.layer.borderWidth = 2
        expiredView.layer.borderColor = UIColor.errorRed.cgColor
        expiredLabel.textColor = .errorRed
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bindToWalletItem(_ walletItem: WalletItem, isSelectedItem: Bool) {
        var a11yLabel = ""
        
        if walletItem.bankOrCard == .bank {
            iconImageView.image = #imageLiteral(resourceName: "opco_bank_mini")
            a11yLabel = NSLocalizedString("Bank account", comment: "")
        } else {
            iconImageView.image = #imageLiteral(resourceName: "opco_credit_card_mini")
            a11yLabel = NSLocalizedString("Credit card", comment: "")
        }
        
        if let nickname = walletItem.nickName {
            nicknameLabel.isHidden = false
            nicknameLabel.text = nickname
            if let nicknameText = nicknameLabel.text, !nicknameText.isEmpty {
                a11yLabel += ", \(nicknameText)"
            }
        } else {
            nicknameLabel.isHidden = true
        }
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            accountNumberLabel.text = "**** \(last4Digits)"
            let a11yDigits = last4Digits.map(String.init).joined(separator: " ")
            a11yLabel += String(format: NSLocalizedString(", Account number ending in, %@", comment: ""), a11yDigits)
        } else {
            accountNumberLabel.text = ""
        }
        
        if walletItem.isExpired {
            a11yLabel += NSLocalizedString(", expired", comment: "")
        }
        
        if isSelectedItem {
            a11yLabel += ", Selected"
            checkmarkImageView.isHidden = false
        } else {
            checkmarkImageView.isHidden = true
        }
        
        innerContentView.accessibilityLabel = a11yLabel
        
        expiredView.isHidden = !walletItem.isExpired
        expiredLabel.text = walletItem.isExpired ? NSLocalizedString("Expired", comment: "") : ""
    }

}

class MiniWalletSectionHeaderCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .white
        
        label.font = OpenSans.semibold.of(textStyle: .title2)
        label.textColor = .deepGray
    }
}

class MiniWalletAddAccountCell: UITableViewCell {
    
    @IBOutlet weak var innerContentView: ButtonControl!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        innerContentView.layer.cornerRadius = 10
        innerContentView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        innerContentView.backgroundColorOnPress = .softGray
        
        label.font = SystemFont.medium.of(textStyle: .title1)
        label.textColor = .blackText
    }
    
}
