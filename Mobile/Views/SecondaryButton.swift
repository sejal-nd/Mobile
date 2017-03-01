//
//  SecondaryButton.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

@IBDesignable
class SecondaryButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .white
        
        titleLabel!.font = UIFont.boldSystemFont(ofSize: 20)
        setTitleColor(.secondaryButtonText, for: .normal)
        setTitleColor(.secondaryButtonText, for: .highlighted)
        setTitleColor(.primaryButtonDisabled, for: .disabled)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // If button is not full width, add rounded corners
        if frame.size.width != UIScreen.main.bounds.size.width {
            layer.cornerRadius = 2
        }
    }
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if newValue {
                backgroundColor = .secondaryButtonHighlight
            }
            else {
                backgroundColor = .white
            }
            super.isHighlighted = newValue
        }
    }
    
    override var isEnabled: Bool {
        get {
            return super.isEnabled
        }
        set {
            if newValue {
                backgroundColor = .white
            } else {
                backgroundColor = .secondaryButtonHighlight
            }
            super.isEnabled = newValue
        }
    }

}
