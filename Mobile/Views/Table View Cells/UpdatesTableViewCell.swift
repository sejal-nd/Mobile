//
//  UpdatesTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UpdatesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var innerContentView: ButtonControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        innerContentView.layer.cornerRadius = 4.0
        innerContentView.layer.masksToBounds = true
        innerContentView.backgroundColorOnPress = .softGray
        
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 2.0)
        
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }

}
