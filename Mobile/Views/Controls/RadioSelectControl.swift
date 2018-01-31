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
	
	var titleLabel: UILabel!
	var selectedImageView: UIImageView!
	var detailButton: UIButton!
	
	@IBInspectable var title: String = "" {
		didSet {
			titleLabel.text = title
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
                detailButton.isAccessibilityElement = true
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
		selectedImageView = UIImageView(image: #imageLiteral(resourceName: "ic_radiobutton_deselected"))
		selectedImageView.translatesAutoresizingMaskIntoConstraints = false
		selectedImageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
		selectedImageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
		selectedImageView.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .horizontal)
		selectedImageView.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
		
		titleLabel = UILabel(frame: .zero)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .horizontal)
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
		titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        titleLabel.textColor = .blackText
        titleLabel.numberOfLines = 2
		
		detailButton = UIButton(type: .system)
		detailButton.translatesAutoresizingMaskIntoConstraints = false
		detailButton.setTitleColor(.actionBlue, for: .normal)
		detailButton.titleLabel?.font = OpenSans.semibold.of(textStyle: .headline)
        detailButton.titleLabel?.numberOfLines = 2
		detailButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
		detailButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
		detailButton.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .horizontal)
		detailButton.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailButton]).usingAutoLayout()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 4
        let tgr = UITapGestureRecognizer(target: self, action: #selector(onStackViewTap))
        stackView.addGestureRecognizer(tgr)
        
		addSubview(selectedImageView)
		addSubview(stackView)
		
		selectedImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
		stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true

		selectedImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
		stackView.leadingAnchor.constraint(equalTo: selectedImageView.trailingAnchor, constant: 10).isActive = true
		stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
		
		detailButton.isHidden = true
        
        accessibilitySetup()
	}
    
    @objc func onStackViewTap() {
        sendActions(for: .touchUpInside)
    }
    
    private func accessibilitySetup() {
        isAccessibilityElement = true
        accessibilityLabel = titleLabel.text ?? ""
    }
	
	
	override var intrinsicContentSize: CGSize {
		return CGSize(width: 375, height: 52)
	}
	
	
	static func create(withTitle title: String, selected: Bool = false, shouldFadeSubviewsOnPress: Bool? = nil, backgroundColorOnPress: UIColor? = nil) -> RadioSelectControl {
		let view = RadioSelectControl(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.bind(withTitle: title, selected: selected, shouldFadeSubviewsOnPress: shouldFadeSubviewsOnPress, backgroundColorOnPress: backgroundColorOnPress)
		return view
	}
	
	
	func bind(withTitle title: String, selected: Bool = false, shouldFadeSubviewsOnPress: Bool? = nil, backgroundColorOnPress: UIColor? = nil) {
		titleLabel.text = title
		isSelected = selected
		
		if let shouldFadeSubviewsOnPress = shouldFadeSubviewsOnPress {
			self.shouldFadeSubviewsOnPress = shouldFadeSubviewsOnPress
		}
		
		if let backgroundColorOnPress = backgroundColorOnPress {
			self.backgroundColorOnPress = backgroundColorOnPress
		}
	}
	
	
}
