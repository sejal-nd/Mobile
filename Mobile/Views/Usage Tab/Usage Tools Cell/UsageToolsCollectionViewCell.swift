//
//  UsageToolsCollectionViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class UsageToolsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var roundedBgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    class var identifier: String {
        return String(describing: self)
    }
    
    
    // MARK: - Configure
    
    public func configureCell(myUsageToolCard: MyUsageToolCard) {
        styleCell()
        
        titleLabel.text = myUsageToolCard.title
        imageView.image = myUsageToolCard.image
    }
    
    private func styleCell() {
        // Background
        roundedBgView.layer.cornerRadius = 10
        addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
        
        // Label
        titleLabel.textColor = .actionBlue
        titleLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
    }
    
}
