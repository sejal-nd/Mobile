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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        
        bodyLabel.textColor = .deepGray
        bodyLabel.font = SystemFont.regular.of(textStyle: .body)
    }
    
    func configure(with energyTip: EnergyTip, index: Int) {
        iconImageView.image = energyTip.image
        iconImageView.isHidden = energyTip.image == nil
        titleLabel.text = String.localizedStringWithFormat("Tip #%d: %@", index + 1, energyTip.title)
        bodyLabel.text = energyTip.body
        bodyLabel.setLineHeight(lineHeight: 24)
    }
    
}
