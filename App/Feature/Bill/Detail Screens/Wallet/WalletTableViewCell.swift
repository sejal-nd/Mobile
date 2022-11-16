//
//  WalletTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 11/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class WalletTableViewCell: UITableViewCell {
    
    @IBOutlet weak var innerContentView: UIView!
    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var expiredView: UIView!
    @IBOutlet weak var expiredLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var gradientLayer = CAGradientLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        innerContentView.layer.borderColor = UIColor.accentGray.cgColor
        innerContentView.layer.borderWidth = 1
        innerContentView.layer.cornerRadius = 8
        innerContentView.layer.masksToBounds = true
        
        accountNumberLabel.textColor = .neutralDark
        accountNumberLabel.font = .subheadline

        nicknameLabel.textColor = .neutralDark
        nicknameLabel.font = .caption1
        
        // Default
        oneTouchPayLabel.textColor = .successGreenText
        oneTouchPayLabel.font = .caption2

        oneTouchPayView.layer.borderColor = UIColor.successGreenText.cgColor
        oneTouchPayView.layer.borderWidth = 1
        
        // Expired
        expiredLabel.textColor = .errorPrimary
        expiredLabel.font = .caption2
        
        expiredView.layer.borderColor = UIColor.errorPrimary.cgColor
        expiredView.layer.borderWidth = 1
        
        editButton.accessibilityLabel = NSLocalizedString("Edit payment method", comment: "")
        deleteButton.accessibilityLabel = NSLocalizedString("Delete payment method", comment: "")
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // disable highlight
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        oneTouchPayView.layer.cornerRadius = oneTouchPayView.bounds.height / 2
        expiredView.layer.cornerRadius = oneTouchPayView.bounds.height / 2
    }
    
    
    func bindToWalletItem(_ walletItem: WalletItem, billingInfo: BillingInfo) {
        accountImageView.image = walletItem.paymentMethodType.imageLarge
        nicknameLabel.text = walletItem.nickName?.uppercased()
        
        if let last4Digits = walletItem.maskedAccountNumber?.last4Digits() {
            if let ad = UIApplication.shared.delegate as? AppDelegate, let window = ad.window {
                if window.bounds.width < 375 { // If smaller than iPhone 6 width
                    accountNumberLabel.text = "...\(last4Digits)"
                } else {
                    accountNumberLabel.text = "**** \(last4Digits)"
                }
            }
        } else {
            accountNumberLabel.text = ""
        }
        
        oneTouchPayView.isHidden = true // Calculated in cellForRowAtIndexPath
        
        expiredView.isHidden = !walletItem.isExpired
        expiredLabel.text = walletItem.isExpired ? NSLocalizedString("Expired", comment: "") : ""
        
        let a11yDescription = walletItem.accessibilityDescription(includingDefaultPaymentMethodInfo: true)
        innerContentView.accessibilityLabel = "Saved \(a11yDescription)"
        innerContentView.isAccessibilityElement = true
        self.accessibilityElements = [innerContentView, editButton, deleteButton] as [UIView]
    }
    
}

