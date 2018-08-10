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
        }
    }

    
    // MARK: - Cell Selection
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            backgroundColor = UIColor.primaryColor.darker(by: 10)
        } else {
            backgroundColor = .primaryColor
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            backgroundColor = UIColor.primaryColor.darker(by: 10)
        } else {
            backgroundColor = .primaryColor
        }
    }
    
    
    // MARK: - Configure
    
    public func configure(image: UIImage?, text: String?) {
        // Style
        backgroundColor = .primaryColor

        accessoryView = UIImageView(image: UIImage(named: "ic_chevron"))
        
        // Set
        iconImageView.image = image
        titleLabel.text = text
        
        // Accessibility
        titleLabel.accessibilityLabel = titleLabel.text
    }
    
}
