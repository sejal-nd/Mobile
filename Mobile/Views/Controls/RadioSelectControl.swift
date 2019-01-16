//
//  RadioSelectControl.swift
//  NibTest
//
//  Created by Sam Francis on 6/19/17.
//  Copyright © 2017 SamFrancis. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RadioSelectControl: ButtonControl {
	
	let titleLabel = UILabel().usingAutoLayout()
	let selectedImageView = UIImageView(image: #imageLiteral(resourceName: "ic_radiobutton_deselected")).usingAutoLayout()
	let detailButton = UIButton(type: .system).usingAutoLayout()
    let detailLabel = UILabel().usingAutoLayout()
    let separatorView = UIView().usingAutoLayout()
    var detailBottomPadding: NSLayoutConstraint?
    
    @IBInspectable var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    @IBInspectable var subtitle: String = "" {
        didSet {
            detailLabel.text = subtitle
            if subtitle.isEmpty {
                detailBottomPadding?.constant = 14
                detailLabel.isHidden = true
            } else {
                detailBottomPadding?.constant = 6
                detailLabel.isHidden = false
            }
        }
    }
    
    @IBInspectable var detailButtonTitle: String? {
        didSet {
            UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                detailButton.setTitle(detailButtonTitle, for: .normal)
                detailButton.layoutIfNeeded()
            }
            detailButton.isHidden = !isSelected || detailButtonTitle == nil
        }
    }
	
	@IBInspectable var detailButtonTitleColor: UIColor? {
		didSet {
			detailButton.setTitleColor(detailButtonTitleColor, for: .normal)
		}
	}
	
	override var isSelected: Bool {
		didSet {
			selectedImageView.image = isSelected ? #imageLiteral(resourceName: "ic_radiobutton_selected"):#imageLiteral(resourceName: "ic_radiobutton_deselected")
			detailButton.isHidden = !isSelected || detailButtonTitle == nil
            if isSelected && !detailButton.isHidden {
                isAccessibilityElement = false
                accessibilityElements = [titleLabel, detailButton]
            } else {
                accessibilitySetup()
            }
		}
	}
    
	override func commonInit() {
		super.commonInit()
		createSubviews()
	}
	
	
	func createSubviews() {
		selectedImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
		selectedImageView.setContentCompressionResistancePriority(.required, for: .vertical)
		selectedImageView.setContentHuggingPriority(.required, for: .horizontal)
		selectedImageView.setContentHuggingPriority(.required, for: .vertical)
		
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .horizontal)
		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        titleLabel.textColor = .blackText
        titleLabel.numberOfLines = 2
		
		detailButton.setTitleColor(.actionBlue, for: .normal)
		detailButton.titleLabel?.font = OpenSans.semibold.of(textStyle: .headline)
        detailButton.titleLabel?.numberOfLines = 2
		detailButton.setContentCompressionResistancePriority(.required, for: .horizontal)
		detailButton.setContentCompressionResistancePriority(.required, for: .vertical)
		detailButton.setContentHuggingPriority(.required, for: .horizontal)
		detailButton.setContentHuggingPriority(.required, for: .vertical)
        
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        detailLabel.textColor = .blackText
        
        separatorView.backgroundColor = .accentGray
        
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, detailButton]).usingAutoLayout()
        titleStack.axis = .horizontal
        titleStack.distribution = .fill
        titleStack.spacing = 4
        
        let detailStack = UIStackView(arrangedSubviews: [titleStack, detailLabel]).usingAutoLayout()
        detailStack.axis = .vertical
        detailStack.distribution = .fill
        detailStack.spacing = 4
        
        let tgr = UITapGestureRecognizer(target: self, action: #selector(onStackViewTap))
        detailStack.addGestureRecognizer(tgr)
        
		addSubview(selectedImageView)
		addSubview(detailStack)
		
		selectedImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        detailStack.topAnchor.constraint(equalTo: topAnchor, constant: 14).isActive = true
        detailBottomPadding = bottomAnchor.constraint(equalTo: detailStack.bottomAnchor, constant: 14)
        detailBottomPadding?.isActive = true

		selectedImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
		detailStack.leadingAnchor.constraint(equalTo: selectedImageView.trailingAnchor, constant: 10).isActive = true
		detailStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        
        addSubview(separatorView)
        
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: detailStack.leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
		detailButton.isHidden = true
        detailLabel.isHidden = true
        separatorView.isHidden = true
        
        accessibilitySetup()
	}
    
    @objc func onStackViewTap() {
        sendActions(for: .touchUpInside)
    }
    
    private func accessibilitySetup() {
        isAccessibilityElement = true
        
        var a11yLabel = title
        if !subtitle.isEmpty {
            a11yLabel += ", \(subtitle)"
        }
        if isSelected {
            a11yLabel += ", selected"
        }
        accessibilityLabel = a11yLabel
    }
    
    static func create(withTitle title: String, subtitle: String = "", detailButtonTitle: String? = nil, showSeparator: Bool = false) -> RadioSelectControl {
        let view = RadioSelectControl().usingAutoLayout()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.configure(title: title, subtitle: subtitle, detailButtonTitle: detailButtonTitle, showSeparator: showSeparator)
        return view
    }
	
    func configure(title: String, subtitle: String = "", detailButtonTitle: String? = nil, showSeparator: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.detailButtonTitle = detailButtonTitle
        separatorView.isHidden = !showSeparator
        shouldFadeSubviewsOnPress = false
    }
	
}
