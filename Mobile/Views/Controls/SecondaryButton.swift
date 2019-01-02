//
//  SecondaryButton.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

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
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.masksToBounds = false
        
        titleLabel?.font = SystemFont.bold.of(textStyle: .title1)
        setTitleColor(.actionBlue, for: .normal)
        setTitleColor(.actionBlue, for: .highlighted)
        setTitleColor(.middleGray, for: .disabled)
        
        layer.cornerRadius = 10.0
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                layer.shadowOpacity = 0
                backgroundColor = .softGray
            } else {
                layer.shadowOpacity = 0.2
                backgroundColor = .white
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                layer.shadowOpacity = 0.2
                backgroundColor = .white
                accessibilityTraits = .button
            } else {
                layer.shadowOpacity = 0
                backgroundColor = .softGray
                accessibilityTraits = [.button, .notEnabled]
            }
        }
    }

}
