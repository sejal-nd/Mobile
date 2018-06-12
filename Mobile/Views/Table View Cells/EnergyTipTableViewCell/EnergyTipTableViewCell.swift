//
//  EnergyTipTableViewCell.swift
//  Mobile
//
//  Created by Sam Francis on 10/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class EnergyTipTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var roundedView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        titleLabel.textColor = .primaryColor
        titleLabel.font = OpenSans.bold.of(size: 20)
        titleLabel.numberOfLines = 0
        
        bodyLabel.textColor = .deepGray
        bodyLabel.font = OpenSans.regular.of(textStyle: .body)
        bodyLabel.numberOfLines = 0
        
        roundedView.layer.cornerRadius = 10
        roundedView.layer.masksToBounds = true
    }
    
    func configure(with energyTip: EnergyTip) {
        iconImageView.image = energyTip.image
        iconImageView.isHidden = energyTip.image == nil
        titleLabel.text = energyTip.title
        bodyLabel.text = energyTip.body
        bodyLabel.setLineHeight(lineHeight: 25)
    }
    
}
