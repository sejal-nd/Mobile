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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        innerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        innerContentView.backgroundColorOnPress = .softGray
        
        iconImageView.image = #imageLiteral(resourceName: "opco_bank_mini")
        
        accountNumberLabel.font = SystemFont.medium.of(textStyle: .headline)
        accountNumberLabel.textColor = .blackText
        nicknameLabel.font = SystemFont.medium.of(textStyle: .footnote)
        nicknameLabel.textColor = .middleGray
        
        checkmarkImageView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bindToWalletItem(_ walletItem: WalletItem) {
        
        if let paymentCategoryType = walletItem.paymentCategoryType {
            if paymentCategoryType == .check {
                iconImageView.image = #imageLiteral(resourceName: "opco_bank_mini")
            } else {
                iconImageView.image = #imageLiteral(resourceName: "opco_credit_card_mini")
            }
        }
        
        if let last4digits = walletItem.maskedWalletItemAccountNumber {
            accountNumberLabel.text = "**** \(last4digits)"
        } else {
            accountNumberLabel.text = ""
        }
        
        nicknameLabel.text = walletItem.nickName
    }

}

class MiniWalletSectionHeaderCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .white
        
        label.font = SystemFont.regular.of(textStyle: .footnote)
        label.textColor = .blackText
    }
}

class MiniWalletAddAccountCell: UITableViewCell {
    
    @IBOutlet weak var innerContentView: ButtonControl!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        innerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        innerContentView.backgroundColorOnPress = .softGray
        
        label.font = SystemFont.medium.of(textStyle: .title1)
        label.textColor = .blackText
    }
    
}
