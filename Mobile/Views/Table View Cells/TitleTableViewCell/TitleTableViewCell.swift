//
//  TitleTableViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift

class TitleTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    // NOTE: You must utilize contentContainerView as a button for row selection rather than didSelectRowAtIndexPath
    // because didSelectRowAtIndexPath will allow taps outside of the 460 max width on iPad
    @IBOutlet weak var contentContainerView: ButtonControl!
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
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var disclosureImageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentContainerView.normalBackgroundColor = UIColor.primaryColor
        contentContainerView.backgroundColorOnPress = UIColor.primaryColor.darker(by: 10)
        
        detailLabel.isHidden = true
        accessibilityTraits = .button
    }
    
    
    // MARK: - Configure
    
    public func configure(image: UIImage?, text: String?, detailText: String? = nil, backgroundColor: UIColor, backgroundColorOnPress: UIColor? = nil, shouldConstrainWidth: Bool = false, shouldHideDisclosure: Bool = false, shouldHideSeparator: Bool = false, disabled: Bool = false) {
        iconImageView.image = image
        titleLabel.text = text
        detailLabel.text = detailText
        
        detailLabel.isHidden = detailText != nil ? false : true
        
        // Needed due to scrolling / dequeuing
        if contentViewWidthConstraint != nil {
            contentViewWidthConstraint.isActive = shouldConstrainWidth
        }
        
        disclosureImageView.isHidden = shouldHideDisclosure
        
        separatorView.isHidden = shouldHideSeparator
        
        contentContainerView.isEnabled = !disabled
        contentContainerView.normalBackgroundColor = backgroundColor
        contentContainerView.backgroundColorOnPress = backgroundColorOnPress ?? backgroundColor.darker(by: 10)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
}
