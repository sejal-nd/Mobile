//
//  ConversationalButton.swift
//  Mobile
//
//  Created by Samuel Francis on 7/16/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class ConversationalButton: ButtonControl {
    
    private let titleLabel = UILabel()
    
    @IBInspectable var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
            titleLabel.setLineHeight(lineHeight: 20)
            accessibilityLabel = titleText
        }
    }
    
    override func commonInit() {
        super.commonInit()
        backgroundColorOnPress = .softGray
        normalBackgroundColor = .white
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.accentGray.cgColor
        
        titleLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        titleLabel.textColor = .actionBlue
        titleLabel.numberOfLines = 0
        
        let caretImageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
        caretImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        caretImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        let stackView = UIStackView().usingAutoLayout()
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        
        [titleLabel, caretImageView].forEach(stackView.addArrangedSubview)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
            ])
    }
}

