//
//  TitleTableViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var contentContainerView: UIView!
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
            detailLabel.font = SystemFont.medium.of(textStyle: .headline)
        }
    }
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    
    private var bgColor = UIColor.primaryColor
    
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentContainerView.backgroundColor = bgColor
        
        detailLabel.isHidden = true
        
    }
    
    
    // MARK: - Cell Selection
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            contentContainerView.backgroundColor = bgColor.darker(by: 10)
        } else {
            contentContainerView.backgroundColor = bgColor
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            contentContainerView.backgroundColor = bgColor.darker(by: 10)
        } else {
            contentContainerView.backgroundColor = bgColor
        }
    }
    
    
    // MARK: - Configure
    
    public func configure(image: UIImage, text: String, detailText: String? = nil, backgroundColor: UIColor, shouldConstrainWidth: Bool = false) {
        iconImageView.image = image
        titleLabel.text = text
        detailLabel.text = detailText
        
        detailLabel.isHidden = detailText != nil ? false : true
        
        contentViewWidthConstraint.isActive = shouldConstrainWidth

        contentContainerView.backgroundColor = backgroundColor
        
        bgColor = backgroundColor
    }
    
}
