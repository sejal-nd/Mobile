//
//  AccountLookupToolResultCell.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountLookupToolResultCell: UITableViewCell {
    
    @IBOutlet weak var radioButtonImageView: UIImageView!
    
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var streetNumberLabel: UILabel!
    @IBOutlet weak var unitNumberLabel: UILabel!
    
    @IBOutlet weak var accountNumberLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var streetNumberLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var unitNumberLabelWidthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        accessibilityTraits = .button
        
        accountNumberLabel.textColor = .deepGray
        accountNumberLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        streetNumberLabel.textColor = .deepGray
        streetNumberLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        unitNumberLabel.textColor = .deepGray
        unitNumberLabel.font = SystemFont.regular.of(textStyle: .headline)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        radioButtonImageView.image = selected ? #imageLiteral(resourceName: "ic_radiobutton_selected") : #imageLiteral(resourceName: "ic_radiobutton_deselected")
    }

}
