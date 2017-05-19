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
    @IBOutlet private weak var bottomBarShadowView: UIView!
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet weak var bottomBarLabel: UILabel!
    
    var gradientLayer: CAGradientLayer!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = .clear
        
        innerContentView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        innerContentView.layer.cornerRadius = 5
        
        gradientView.layer.cornerRadius = 5
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.cornerRadius = 5
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 238/255, green: 242/255, blue: 248/255, alpha: 1).cgColor
        ]
        gradientView.layer.addSublayer(gradientLayer)
        
        bottomBarShadowView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        bottomBarView.roundBottomCorners(radius: 5)
        
        bottomBarLabel.textColor = .blackText
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        // disable selection style
    }
    
}
