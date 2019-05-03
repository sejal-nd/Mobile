//
//  TabCollectionViewCell.swift
//  Mobile
//
//  Created by Samuel Francis on 5/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class TabCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var highlightBar: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        styleDeselected()
    }
    
    private func styleSelected() {
        titleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        titleLabel.textColor = .actionBlue
        highlightBar.isHidden = false
    }
    
    private func styleDeselected() {
        titleLabel.font = SystemFont.regular.of(textStyle: .footnote)
        titleLabel.textColor = .middleGray
        highlightBar.isHidden = true
    }
    
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            styleSelected()
        } else {
            styleDeselected()
        }
    }
}
