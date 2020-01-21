//
//  GiftCollectionViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 12/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GiftCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        isSelected = false
    }

    override var isSelected: Bool {
        didSet {
            selectedImageView.isHidden = !isSelected
        }
    }

}
