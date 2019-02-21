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
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet private weak var bottomBarShadowView: UIView!
    @IBOutlet private weak var bottomBarView: UIView!
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
        
        innerContentView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        innerContentView.layer.cornerRadius = 5
        
        gradientView.layer.cornerRadius = 5
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1).cgColor
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        accountNumberLabel.textColor = .blackText
        accountNumberLabel.font = OpenSans.regular.of(textStyle: .title1)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.font = OpenSans.regular.of(textStyle: .footnote)
        nicknameLabel.textColor = .blackText
        nicknameLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        bottomBarShadowView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        bottomBarView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        expiredView.layer.borderWidth = 2
        expiredView.layer.borderColor = UIColor.errorRed.cgColor
        expiredLabel.textColor = .errorRed
        
        editButton.accessibilityLabel = NSLocalizedString("Edit payment method", comment: "")
        deleteButton.accessibilityLabel = NSLocalizedString("Delete payment method", comment: "")
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // disable highlight
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layoutIfNeeded() // Needed for frames to be correct
        
        // Round only the top corners
        gradientLayer.frame = gradientView.frame
        let gradientPath = UIBezierPath(roundedRect:gradientLayer.bounds, byRoundingCorners:[.topLeft, .topRight], cornerRadii: CGSize(width: 5, height:  5))
        let gradientMaskLayer = CAShapeLayer()
        gradientMaskLayer.path = gradientPath.cgPath
        gradientLayer.mask = gradientMaskLayer
        
        // Round only the bottom corners
        let bottomBarPath = UIBezierPath(roundedRect:bottomBarView.bounds, byRoundingCorners:[.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 5, height:  5))
        let bottomBarMaskLayer = CAShapeLayer()
        bottomBarMaskLayer.path = bottomBarPath.cgPath
        bottomBarView.layer.mask = bottomBarMaskLayer
    }
    
    
    func bindToWalletItem(_ walletItem: WalletItem, billingInfo: BillingInfo) {
        var a11yLabel = ""
        
        accountImageView.image = walletItem.paymentMethodType.imageLarge
        
        a11yLabel = walletItem.bankOrCard == .card ? NSLocalizedString("Saved \(walletItem.paymentMethodType.displayString) card", comment: "") : NSLocalizedString("Saved bank account", comment: "")

        nicknameLabel.text = walletItem.nickName?.uppercased()
        if let nicknameText = nicknameLabel.text {
            a11yLabel += ", \(nicknameText)"
        }
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            if let ad = UIApplication.shared.delegate as? AppDelegate, let window = ad.window {
                if window.bounds.width < 375 { // If smaller than iPhone 6 width
                    accountNumberLabel.text = "...\(last4Digits)"
                } else {
                    accountNumberLabel.text = "**** \(last4Digits)"
                }
            }
            let a11yDigits = last4Digits.map(String.init).joined(separator: " ")
            a11yLabel += String(format: NSLocalizedString(", Account number ending in, %@", comment: ""), a11yDigits)
        } else {
            accountNumberLabel.text = ""
        }
        
        oneTouchPayView.isHidden = true // Calculated in cellForRowAtIndexPath
        if walletItem.isDefault {
            a11yLabel += NSLocalizedString(", Default payment method", comment: "")
        }
        
        if walletItem.isExpired {
            a11yLabel += NSLocalizedString(", expired", comment: "")
        }

        innerContentView.accessibilityLabel = a11yLabel
        innerContentView.isAccessibilityElement = true
        self.accessibilityElements = [innerContentView, editButton, deleteButton]
        
        expiredView.isHidden = !walletItem.isExpired
        expiredLabel.text = walletItem.isExpired ? NSLocalizedString("Expired", comment: "") : ""
    }
    
}

