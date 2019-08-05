//
//  HomeEditEmptyCell.swift
//  Mobile
//
//  Created by Samuel Francis on 6/19/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class HomeEditEmptyCell: UICollectionViewCell {
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        background.layer.cornerRadius = 10
        label.textColor = .deepGray
        label.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
}
