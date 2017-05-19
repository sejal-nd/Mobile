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
    
    var gradientLayer: CAGradientLayer!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        contentView.backgroundColor = .clear
        
        innerContentView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        innerContentView.layer.cornerRadius = 5
        
        gradientView.layer.cornerRadius = 5
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        
        // Round only the top corners
        var path = UIBezierPath(roundedRect:gradientLayer.bounds, byRoundingCorners:[.topLeft, .topRight], cornerRadii: CGSize(width: 5, height:  5))
        var maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        gradientLayer.mask = maskLayer
        
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 238/255, green: 242/255, blue: 248/255, alpha: 1).cgColor
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        accountNumberLabel.textColor = .blackText
        oneTouchPayLabel.textColor = .blackText
        nicknameLabel.textColor = .blackText
        
        bottomBarShadowView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        // Round only the bottom corners
        path = UIBezierPath(roundedRect:bottomBarView.bounds, byRoundingCorners:[.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 5, height:  5))
        maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        bottomBarView.layer.mask = maskLayer
        bottomBarView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        bottomBarLabel.textColor = .blackText
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // disable highlight
    }
    
}
