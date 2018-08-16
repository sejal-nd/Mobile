//
//  WalletTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 5/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WalletTableViewCell: UITableViewCell {
    
    @IBOutlet weak var innerContentView: ButtonControl!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet private weak var bottomBarShadowView: UIView!
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet weak var bottomBarLabel: UILabel!
    @IBOutlet weak var expiredView: UIView!
    @IBOutlet weak var expiredLabel: UILabel!
    
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
            UIColor(red: 238/255, green: 242/255, blue: 248/255, alpha: 1).cgColor
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
        
        bottomBarLabel.textColor = .blackText
        bottomBarLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        expiredView.layer.borderWidth = 2
        expiredView.layer.borderColor = UIColor.errorRed.cgColor
        expiredLabel.textColor = .errorRed
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
        
        bottomBarLabel.text = NSLocalizedString("No Fee Applied", comment: "") // Default display
        switch Environment.shared.opco {
        case .comEd, .peco:
            if walletItem.bankOrCard == .card {
                accountImageView.image = #imageLiteral(resourceName: "opco_credit_card")
                bottomBarLabel.text = NSLocalizedString(billingInfo.convenienceFee!.currencyString! + " Convenience Fee", comment: "")
                a11yLabel = NSLocalizedString("Saved credit card", comment: "")
            } else {
                accountImageView.image = #imageLiteral(resourceName: "opco_bank")
                a11yLabel = NSLocalizedString("Saved bank account", comment: "")
            }
        case .bge:
            if walletItem.bankOrCard == .card {
                accountImageView.image = #imageLiteral(resourceName: "opco_credit_card")
                bottomBarLabel.text = NSLocalizedString(billingInfo.convenienceFeeString(isComplete: false), comment: "")
                a11yLabel = NSLocalizedString("Saved credit card", comment: "")
            } else {
                accountImageView.image = #imageLiteral(resourceName: "opco_bank")
                a11yLabel = NSLocalizedString("Saved bank account", comment: "")
            }
        }
        
        a11yLabel += NSLocalizedString(" button", comment: "")

        // Nickname
        if let nickname = walletItem.nickName {
            let displayNickname: String
            if Environment.shared.opco != .bge, let maskedNumber = walletItem.maskedWalletItemAccountNumber {
                let last4 = maskedNumber[maskedNumber.index(maskedNumber.endIndex, offsetBy: -4)...]
                displayNickname = nickname == last4 ? "" : nickname
            } else {
                displayNickname = nickname
            }
            
            nicknameLabel.text = displayNickname.uppercased()
            if Environment.shared.opco == .bge {
                if walletItem.bankOrCard == .bank {
                    if let bankAccountType = walletItem.bankAccountType {
                        if bankAccountType.rawValue.uppercased() == "SAVING"{
                            nicknameLabel.text = NSLocalizedString(String(format:"%@, SAVINGS", nickname),comment: "")
                        } else {
                            nicknameLabel.text = NSLocalizedString(String(format:"%@, CHECKING", nickname),comment: "")
                        }
                    }
                }
            }
        } else {
            nicknameLabel.text = ""
            if Environment.shared.opco == .bge {
                if let bankAccountType = walletItem.bankAccountType {
                    nicknameLabel.text = bankAccountType.rawValue.uppercased()
                }
            }
        }
        
        if let nicknameText = nicknameLabel.text, !nicknameText.isEmpty {
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
            a11yLabel += NSLocalizedString(", Default payment account", comment: "")
        }
        
        if walletItem.isExpired {
            a11yLabel += NSLocalizedString(", expired", comment: "")
        }
        
        innerContentView.accessibilityLabel = a11yLabel + ", \(bottomBarLabel.text!)"
        
        expiredView.isHidden = !walletItem.isExpired
        expiredLabel.text = walletItem.isExpired ? NSLocalizedString("Expired", comment: "") : ""
    }
    
}
