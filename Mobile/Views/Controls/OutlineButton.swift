//
//  OutlineButton.swift
//  Mobile
//
//  Created by Sam Francis on 10/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class OutlineButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .clear
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.masksToBounds = false
        
        titleLabel?.font = SystemFont.bold.of(textStyle: .title1)
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .highlighted)
        
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // If button is not full width, add rounded corners
        if frame.size.width != UIScreen.main.bounds.size.width {
            layer.cornerRadius = 2
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                layer.shadowOpacity = 0
                backgroundColor = UIColor.white.withAlphaComponent(0.3)
                layer.borderColor = UIColor.clear.cgColor
            }
            else {
                layer.shadowOpacity = 0.2
                backgroundColor = .clear
                layer.borderColor = UIColor.white.cgColor
            }
        }
    }


}

