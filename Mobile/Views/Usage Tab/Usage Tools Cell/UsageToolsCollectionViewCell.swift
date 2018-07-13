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
    
    public func configureCell(title: String?, image: UIImage?) {
        titleLabel.text = title
        imageView.image = image
    }
    
}
