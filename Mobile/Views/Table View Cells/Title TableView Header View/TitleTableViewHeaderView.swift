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
            titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    
    // MARK: - Configuration
    
    public func configure(text: String?, backgroundColor: UIColor = .primaryColor) {
        titleLabel.text = text
        
        colorView.backgroundColor = backgroundColor
    }
    
}
