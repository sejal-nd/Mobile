//
//  SecondaryButton.swift
//  Mobile
//
//  Created by Marc Shilling on 6/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class SecondaryButton: UIButton {
    
    private enum SecondaryButtonCondensation: Int {
        case none
        case condensed
        case supercondensed
    }
    
    @IBInspectable var tintWhite: Bool = false {
        didSet {
            updateTitleColors()
            updateEnabledState()
        }
    }
    
    @IBInspectable var condensationValue: Int = 0 {
        didSet {
            let condensation = SecondaryButtonCondensation(rawValue: condensationValue) ?? .none
            switch condensation {
            case .none:
                titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
            case .condensed:
                titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
            case .supercondensed:
                titleLabel?.font = SystemFont.semibold.of(textStyle: .caption1)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        layer.borderWidth = 1
        
        updateTitleColors()
        updateEnabledState()
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        layer.cornerRadius = frame.size.height / 2
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = tintWhite ? UIColor.white.withAlphaComponent(0.2) : .softGray
            } else {
                backgroundColor = tintWhite ? .clear : .white
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            updateEnabledState()
        }
    }
    
    private func updateTitleColors() {
        let titleColor: UIColor, highlightColor: UIColor, disabledColor: UIColor
        
        if tintWhite {
            titleColor = .white
            highlightColor = .white
            disabledColor = UIColor.white.withAlphaComponent(0.5)
        } else {
            titleColor = .actionBlue
            highlightColor = .actionBlue
            disabledColor = UIColor.deepGray.withAlphaComponent(0.4)
        }
        
        setTitleColor(titleColor, for: .normal)
        setTitleColor(highlightColor, for: .highlighted)
        setTitleColor(disabledColor, for: .disabled)
    }
    
    private func updateEnabledState() {
        backgroundColor = tintWhite ? .clear : .white
        layer.borderColor = tintWhite ? UIColor.white.cgColor : UIColor.accentGray.cgColor
        if isEnabled {
            accessibilityTraits = .button
        } else {
            accessibilityTraits = [.button, .notEnabled]
            if tintWhite {
                layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            }
        }
    }

}
