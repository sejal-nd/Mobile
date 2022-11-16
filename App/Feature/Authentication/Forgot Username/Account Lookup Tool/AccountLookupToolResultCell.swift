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
        
        accountNumberLabel.textColor = .neutralDark
        accountNumberLabel.font = .headlineSemibold
        
        streetNumberLabel.textColor = .neutralDark
        streetNumberLabel.font = .headline
        
        unitNumberLabel.textColor = .neutralDark
        unitNumberLabel.font = .headline
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        radioButtonImageView.image = selected ? #imageLiteral(resourceName: "ic_radiobutton_selected") : #imageLiteral(resourceName: "ic_radiobutton_deselected")
    }

}
