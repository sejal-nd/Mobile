//
//  TitleTableViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
            titleLabel.font = SystemFont.medium.of(textStyle: .headline)
        }
    }
    
    private var bgColor = UIColor.primaryColor
    
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = bgColor
    }
    
    
    // MARK: - Cell Selection
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            backgroundColor = UIColor.primaryColor.darker(by: 10)
        } else {
            backgroundColor = bgColor
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            backgroundColor = UIColor.primaryColor.darker(by: 10)
        } else {
            backgroundColor = bgColor
        }
    }
    
    
    // MARK: - Configure
    
    public func configure(image: UIImage, text: String, backgroundColor: UIColor) {
        iconImageView.image = image
        titleLabel.text = text
        self.backgroundColor = backgroundColor
        
        bgColor = backgroundColor
    }
    
}
