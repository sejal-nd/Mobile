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
    var bottomSeparator: UIView!
	
	@IBInspectable var title: String = "" {
		didSet {
			titleLabel.text = title
		}
	}
	
	@IBInspectable var detailButtonTitle: String? {
		didSet {
			detailButton.setTitle(detailButtonTitle, for: .normal)
			detailButton.isHidden = !isSelected || detailButtonTitle == nil
		}
	}
	
	@IBInspectable var detailButtonTitleColor: UIColor? {
		didSet {
			detailButton.setTitleColor(detailButtonTitleColor, for: .normal)
		}
	}
	
	override var isHighlighted: Bool {
		didSet {
			selectedImageView.image = (isSelected || isHighlighted) ? #imageLiteral(resourceName: "ic_radiobutton_selected"):#imageLiteral(resourceName: "ic_radiobutton_deselected")
		}
	}
	
	override var isSelected: Bool {
		didSet {
			selectedImageView.image = (isSelected || isHighlighted) ? #imageLiteral(resourceName: "ic_radiobutton_selected"):#imageLiteral(resourceName: "ic_radiobutton_deselected")
			detailButton.isHidden = !isSelected || detailButtonTitle == nil
		}
	}
    
    func ShowBottomSeparator(_ show: Bool) {
        bottomSeparator.isHidden = !show
    }
	
	
	override func commonInit() {
		super.commonInit()
		createSubviews()
	}
	
	
	func createSubviews() {
		selectedImageView = UIImageView(image: #imageLiteral(resourceName: "ic_radiobutton_deselected"))
		selectedImageView.translatesAutoresizingMaskIntoConstraints = false
		selectedImageView.setContentCompressionResistancePriority(999, for: .horizontal)
		selectedImageView.setContentCompressionResistancePriority(999, for: .vertical)
		selectedImageView.setContentHuggingPriority(999, for: .horizontal)
		selectedImageView.setContentHuggingPriority(999, for: .vertical)
		
		titleLabel = UILabel(frame: .zero)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.setContentCompressionResistancePriority(751, for: .horizontal)
		titleLabel.setContentCompressionResistancePriority(999, for: .vertical)
		titleLabel.setContentHuggingPriority(751, for: .horizontal)
		titleLabel.setContentHuggingPriority(999, for: .vertical)
        titleLabel.numberOfLines = 0
		
		detailButton = UIButton(type: .system)
		detailButton.translatesAutoresizingMaskIntoConstraints = false
		detailButton.setTitleColor(#colorLiteral(red: 0, green: 0.3490196078, blue: 0.6431372549, alpha: 1), for: .normal)
		detailButton.titleLabel?.font = .systemFont(ofSize: 16, weight: UIFontWeightSemibold)
		detailButton.setContentCompressionResistancePriority(999, for: .horizontal)
		detailButton.setContentCompressionResistancePriority(999, for: .vertical)
		detailButton.setContentHuggingPriority(999, for: .horizontal)
		detailButton.setContentHuggingPriority(999, for: .vertical)
        
        var separatorFrame = CGRect()
        separatorFrame.origin.x = 0
        separatorFrame.origin.y = 0
        separatorFrame.size.width = 375
        separatorFrame.size.height = 5
        
        bottomSeparator = UIView(frame: separatorFrame)
        bottomSeparator.backgroundColor = UIColor(colorLiteralRed: 216.0, green: 216.0, blue: 216.0, alpha: 1)
		
		addSubview(selectedImageView)
		addSubview(titleLabel)
		addSubview(detailButton)
        addSubview(bottomSeparator)
		
		selectedImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
		titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
		detailButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
		
		selectedImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
		titleLabel.leadingAnchor.constraint(equalTo: selectedImageView.trailingAnchor, constant: 10).isActive = true
		detailButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4).isActive = true
		detailButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
		
		detailButton.isHidden = true
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
