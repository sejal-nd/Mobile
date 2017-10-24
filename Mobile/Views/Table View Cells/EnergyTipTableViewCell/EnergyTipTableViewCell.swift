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
    @IBOutlet weak var whyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        titleLabel.textColor = .primaryColor
        titleLabel.font = OpenSans.bold.of(size: 20)
        
        whyLabel.textColor = .deepGray
        whyLabel.font = OpenSans.regular.of(textStyle: .body)
    }
    
    func configure(with energyTip: EnergyTip) {
        iconImageView.image = energyTip.image
        iconImageView.isHidden = energyTip.image == nil
        titleLabel.text = energyTip.title
        whyLabel.text = energyTip.parsedBody
        whyLabel.setLineHeight(lineHeight: 25)
    }
    
}
