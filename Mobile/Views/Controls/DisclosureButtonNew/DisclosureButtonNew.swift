//
//  DisclosureButtonNew.swift
//  Mobile
//
//  Created by Marc Shilling on 6/28/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DisclosureButtonNew: UIButton {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var caretAccessory: UIImageView!
    
    @IBInspectable var descriptionText: String? {
        didSet {
            updateLabels()
        }
    }
    
    @IBInspectable var valueText: String? {
        didSet {
            updateLabels()
        }
    }
    
    var stormTheme = false {
        didSet {
            view.backgroundColor = .stormModeGray
            descriptionLabel.textColor = .white
            valueLabel.textColor = .white
            caretAccessory.image = #imageLiteral(resourceName: "ic_caret_white.pdf")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .clear
        Bundle.main.loadNibNamed(className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        addSubview(view)
        
        fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)

        descriptionLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        descriptionLabel.textColor = .middleGray
        
        valueLabel.font = SystemFont.regular.of(textStyle: .headline)
        valueLabel.textColor = .deepGray

        updateLabels()
    }
    
    public func setHideCaret(caretHidden: Bool) {
        caretAccessory.isHidden = caretHidden
    }
    
    private func updateLabels() {
        // If both a description and value are set, display both
        // If only a description is set, display the description as the centered value label
        if let value = valueText, !value.isEmpty {
            descriptionLabel.text = descriptionText
            descriptionLabel.isHidden = descriptionText?.isEmpty ?? true
            valueLabel.text = value
        } else {
            valueLabel.text = descriptionText
            descriptionLabel.isHidden = true
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                view.backgroundColor = stormTheme ? UIColor.stormModeGray.darker(by: 10) : .softGray
            } else {
                view.backgroundColor = stormTheme ? .stormModeGray : .white
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                view.backgroundColor = stormTheme ? .stormModeGray : .white
                descriptionLabel.textColor = .middleGray
                valueLabel.textColor = .deepGray
                caretAccessory.alpha = 1
                accessibilityTraits = .button
            } else {
                view.backgroundColor = stormTheme ? UIColor.stormModeGray.darker(by: 10) : .softGray
                descriptionLabel.textColor = UIColor.middleGray.withAlphaComponent(0.5)
                valueLabel.textColor = UIColor.deepGray.withAlphaComponent(0.5)
                caretAccessory.alpha = 0.5
                accessibilityTraits = [.button, .notEnabled]
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 55)
    }
    
}


extension Reactive where Base: DisclosureButtonNew {
    
    var descriptionText: Binder<String?> {
        return Binder(base) { button, text in
            button.descriptionText = text
        }
    }
    
    var valueText: Binder<String?> {
        return Binder(base) { button, text in
            button.valueText = text
        }
    }
    
}
