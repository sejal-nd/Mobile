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
        }
    }
    
    public var identifier = "TitleTableViewCell" // currently unused
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let selectedColorView = UIView()
        selectedColorView.backgroundColor = .red
        
        selectedBackgroundView = selectedColorView
        print("Set selected")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
    }
    
    // MARK: - Configure
    
    public func configure(image: UIImage?, text: String?) {
        // Style
        backgroundColor = .primaryColor
        
        let selectedColorView = UIView()
        selectedColorView.backgroundColor = UIColor.primaryColor.darker(by: 10)
        selectedBackgroundView = selectedColorView
        
        accessoryView = UIImageView(image: UIImage(named: "ic_chevron"))
        
        // Set
        iconImageView.image = image
        titleLabel.text = text
        
        // Accessibility
        titleLabel.accessibilityLabel = titleLabel.text
    }
    
}
