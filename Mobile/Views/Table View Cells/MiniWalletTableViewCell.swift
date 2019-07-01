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
        iconImageView.image = walletItem.paymentMethodType.imageMini
        
        if let nickname = walletItem.nickName {
            nicknameLabel.isHidden = false
            nicknameLabel.text = nickname
        } else {
            nicknameLabel.isHidden = true
        }
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            accountNumberLabel.text = "**** \(last4Digits)"
        } else {
            accountNumberLabel.text = ""
        }
        
        var a11yDescription = walletItem.accessibilityDescription()
        if isSelectedItem {
            a11yDescription += ", Selected"
            checkmarkImageView.isHidden = false
        } else {
            checkmarkImageView.isHidden = true
        }
        
        innerContentView.accessibilityLabel = "Saved \(a11yDescription)"
        
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
