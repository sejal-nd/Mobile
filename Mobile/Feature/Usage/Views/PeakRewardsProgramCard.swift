//
//  PeakRewardsProgramCard.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PeakRewardsProgramCard: UIView {
    
    convenience init(title: String, body: String) {
        self.init(frame: .zero)
        
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .deepGray
        titleLabel.textAlignment = .center
        titleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        let separator = UIView()
        separator.backgroundColor = .accentGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        let descriptionContainer = UIView()
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = body
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .deepGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        descriptionContainer.addSubview(descriptionLabel)
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: descriptionContainer.topAnchor).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: descriptionContainer.bottomAnchor).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: descriptionContainer.leadingAnchor, constant: 10).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: descriptionContainer.trailingAnchor, constant: -10).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, separator, descriptionContainer])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -21).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 11).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -11).isActive = true
        
        isAccessibilityElement = true
        accessibilityElements = nil
        accessibilityLabel = title + ", " + body
    }
    
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

}
