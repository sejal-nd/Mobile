//
//  TitleTableViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
            titleLabel.font = SystemFont.regular.of(textStyle: .callout)
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
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectionView = UIView()
        if StormModeStatus.shared.isOn {
            selectionView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        } else {
            selectionView.backgroundColor = UIColor.primaryColor.darker(by: 10)
        }
        selectedBackgroundView = selectionView
        
        detailLabel.isHidden = true
    }
    
    // MARK: - Configure
    
    public func configure(image: UIImage?, text: String?, detailText: String? = nil, shouldConstrainWidth: Bool = false, shouldHideDisclosure: Bool = false, shouldHideSeparator: Bool = false, disabled: Bool = false) {
        iconImageView.image = image
        titleLabel.text = text
        detailLabel.text = detailText
        
        accessibilityLabel = text
        
        detailLabel.isHidden = detailText != nil ? false : true
        
        disclosureImageView.isHidden = shouldHideDisclosure
        
        separatorView.isHidden = shouldHideSeparator
        
        contentView.accessibilityLabel = "\(text ?? ""). \(detailText ?? "")"
    }
    
}
