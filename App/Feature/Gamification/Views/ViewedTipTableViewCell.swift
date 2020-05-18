//
//  ViewedTipTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 12/9/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class ViewedTipTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reminderImageView: UIImageView!
    @IBOutlet weak var favoriteImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        reminderImageView.isHidden = true
        favoriteImageView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        reminderImageView.isHidden = true
        favoriteImageView.isHidden = true
    }

}
