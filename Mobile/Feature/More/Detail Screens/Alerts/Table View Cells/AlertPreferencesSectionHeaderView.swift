//
//  AlertPreferencesSectionHeaderView.swift
//  Mobile
//
//  Created by Samuel Francis on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class AlertPreferencesSectionHeaderView: UIView {
    private let label = UILabel().usingAutoLayout()
    private let caretImageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret_down")).usingAutoLayout()
    let separator = UIView().usingAutoLayout()
    var tapped: (() -> ())?
    
    init() {
        super.init(frame: .zero)
        createView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createView()
    }
    
    private func createView() {
        backgroundColor = .white
        label.textColor = .deepGray
        label.font = SystemFont.medium.of(textStyle: .callout)
        
        let contentView = UIView().usingAutoLayout()
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentView.addTabletWidthConstraints(horizontalPadding: 0)
        
        contentView.addSubview(label)
        contentView.addSubview(caretImageView)
        label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(lessThanOrEqualTo: caretImageView.leadingAnchor, constant: 8).isActive = true
        caretImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        caretImageView.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        
        separator.backgroundColor = .accentGray
        
        contentView.addSubview(separator)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(tapRecognizer:)))
        addGestureRecognizer(tap)
        
        isAccessibilityElement = true
        accessibilityTraits.insert(.header)
    }
    
    func configure(withTitle title: String, isExpanded: Bool) {
        label.text = title
        caretImageView.image = isExpanded ? #imageLiteral(resourceName: "ic_caret_up") : #imageLiteral(resourceName: "ic_caret_down")
        separator.isHidden = isExpanded
        
        accessibilityLabel = "\(isExpanded ? "Hide" : "Show") \(title)"
        UIAccessibility.post(notification: .screenChanged, argument: self)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 59)
    }
    
    @objc func didTap(tapRecognizer: UITapGestureRecognizer) {
        accessibilityLabel = nil
        tapped?()
    }
}
