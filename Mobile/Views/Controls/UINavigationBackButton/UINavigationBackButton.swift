//
//  UINavigationBackButton.swift
//  Mobile
//
//  Created by Marc Shilling on 6/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UINavigationBackButton: UIButton {

    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var backLabel: UILabel!
    
    override func awakeFromNib() {
        backgroundColor = .clear
        arrowImage.image = arrowImage.image!.withRenderingMode(.alwaysTemplate)
        arrowImage.tintColor = .white
        backLabel.textColor = .white
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                arrowImage.alpha = 0.2
                backLabel.alpha = 0.2
            }
            else {
                arrowImage.alpha = 1.0
                backLabel.alpha = 1.0
            }
        }
    }
    
}
