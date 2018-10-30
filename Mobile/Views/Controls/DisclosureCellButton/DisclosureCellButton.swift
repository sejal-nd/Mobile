//
//  DisclosureCellButton.swift
//  Mobile
//
//  Created by Samuel Francis on 10/29/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class DisclosureCellButton: ButtonControl {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
            titleLabel.font = SystemFont.medium.of(textStyle: .headline)
        }
    }
    @IBOutlet weak var detailLabel: UILabel! {
        didSet {
            detailLabel.textColor = .white
            detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet weak var disclosureImageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    
    override func commonInit() {
        super.commonInit()
        
        Bundle.main.loadNibNamed(DisclosureCellButton.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        addSubview(view)
        
        view.layer.cornerRadius = 10
        view.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        
        if StormModeStatus.shared.isOn {
            normalBackgroundColor = .clear
            backgroundColorOnPress = UIColor.black.withAlphaComponent(0.15)
        } else {
            normalBackgroundColor = UIColor.primaryColor
            backgroundColorOnPress = UIColor.primaryColor.darker(by: 10)
        }
        
        detailLabel.isHidden = true
    }
    
    // MARK: - Configure
    
    public func configure(image: UIImage?,
                          text: String?,
                          detailText: String? = nil,
                          shouldHideDisclosure: Bool = false,
                          shouldHideSeparator: Bool = false,
                          enabled: Bool = true) {
        iconImageView.image = image
        titleLabel.text = text
        detailLabel.text = detailText
        detailLabel.isHidden = detailText != nil ? false : true
        disclosureImageView.isHidden = shouldHideDisclosure
        separatorView.isHidden = shouldHideSeparator
        accessibilityLabel = "\(text ?? ""). \(detailText ?? "")"
        isEnabled = enabled
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 60)
    }
}
