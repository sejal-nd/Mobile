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
        
        titleLabel!.font = SystemFont.bold.of(size: 20)
        setTitleColor(.actionBlue, for: .normal)
        setTitleColor(.actionBlue, for: .highlighted)
        setTitleColor(.middleGray, for: .disabled)
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
                layer.shadowOpacity = 0
                backgroundColor = .softGray
            }
            else {
                layer.shadowOpacity = 0.2
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
                layer.shadowOpacity = 0.2
                backgroundColor = .white
            } else {
                layer.shadowOpacity = 0
                backgroundColor = .softGray
            }
            super.isEnabled = newValue
        }
    }

}
