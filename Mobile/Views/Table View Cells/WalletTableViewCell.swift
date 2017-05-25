//
//  WalletTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 5/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WalletTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet private weak var bottomBarShadowView: UIView!
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet weak var bottomBarLabel: UILabel!
    
    var gradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
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
        oneTouchPayLabel.textColor = .blackText
        nicknameLabel.textColor = .blackText
        
        bottomBarShadowView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        bottomBarView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        bottomBarLabel.textColor = .blackText
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
    
    
    func bindToWalletItem(_ walletItem: WalletItem) {
        
        // Nickname
        if let nickname = walletItem.nickName {
            if Environment.sharedInstance.opco == .bge {
                if let bankAccountType = walletItem.bankAccountType {
                    nicknameLabel.text = "\(nickname), \(bankAccountType.rawValue.uppercased())"
                } else {
                    nicknameLabel.text = nickname.uppercased()
                }
            } else {
                nicknameLabel.text = nickname.uppercased()
            }
        } else {
            if Environment.sharedInstance.opco == .bge {
                if let bankAccountType = walletItem.bankAccountType {
                    nicknameLabel.text = bankAccountType.rawValue.uppercased()
                }
            } else {
                nicknameLabel.text = ""
            }
        }

        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            accountNumberLabel.text = "**** \(last4Digits)"
        } else {
            accountNumberLabel.text = ""
        }
        
        bottomBarLabel.text = NSLocalizedString("No Fee Applied", comment: "") // Default display
        switch Environment.sharedInstance.opco {
        case .comEd, .peco:
            if walletItem.paymentCategoryType == .credit {
                bottomBarLabel.text = NSLocalizedString("$2.35 Convenience Fee", comment: "")
                if let paymentMethodType = walletItem.paymentMethodType {
                    switch paymentMethodType {
                    case .visa:
                        accountImageView.image = #imageLiteral(resourceName: "ic_visa")
                    case .mastercard:
                        accountImageView.image = #imageLiteral(resourceName: "ic_mastercard")
                    default:
                        accountImageView.image = #imageLiteral(resourceName: "ic_credit_placeholder")
                    }
                }
            } else if walletItem.paymentCategoryType == .check {
                accountImageView.image = #imageLiteral(resourceName: "opco_bank")
            }
        case .bge:
            accountImageView.image = #imageLiteral(resourceName: "opco_bank")
            
            bottomBarLabel.textColor = .successGreenText
            bottomBarLabel.text = NSLocalizedString("Verification Status: Active", comment: "")
            
            // if credit card:
            // bottomBarLabel.text = NSLocalizedString("Fees: $1.50 Residential | 2.4% Business", comment: "")
        }
        
        // TODO: Make this work
        oneTouchPayView.isHidden = true
        
    }
    
}
