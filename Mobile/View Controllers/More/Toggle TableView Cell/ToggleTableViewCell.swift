//
//  ToggleTableViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class ToggleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
        }
    }
    @IBOutlet weak var toggle: UISwitch! {
        didSet {
            
        }
    }

    // MARK: - Configure
    
    public func configure(image: UIImage?, text: String?, viewController: MoreViewController) {
        // Style
        backgroundColor = .primaryColor
        
        // Set
        iconImageView.image = image
        titleLabel.text = text
        
        // Accessibility
        titleLabel.accessibilityLabel = titleLabel.text
    }
    
    
    // MARK: - Action
    
}
