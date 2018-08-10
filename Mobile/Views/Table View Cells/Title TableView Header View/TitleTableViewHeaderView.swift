//
//  TitleTableViewHeaderView.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class TitleTableViewHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
            titleLabel.font = OpenSans.semibold.of(size: 18)
        }
    }
    
    
    // MARK: - Configuration
    
    public func configure(text: String?) {
        // Style
        colorView.backgroundColor = .primaryColor
        
        // Set Value
        titleLabel.text = text
    }
    
}
