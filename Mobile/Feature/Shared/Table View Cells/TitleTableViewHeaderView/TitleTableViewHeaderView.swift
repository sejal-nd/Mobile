//
//  TitleTableViewHeaderView.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class TitleTableViewHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var colorView: UIView! {
        didSet {
            colorView.backgroundColor = .primaryColor
        }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
            titleLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    
    // MARK: - Configuration
    
    public func configure(text: String?, backgroundColor: UIColor = .primaryColor, shouldConstrainWidth: Bool = false, shouldHideSeparator: Bool = false) {
        titleLabel.text = text
        
        colorView.backgroundColor = backgroundColor
        
        // Needed due to scrolling / dequeuing
        if contentViewWidthConstraint != nil {
            contentViewWidthConstraint.isActive = shouldConstrainWidth
        }
        
        separatorView.isHidden = shouldHideSeparator
        accessibilityLabel = text
    }
    
}
