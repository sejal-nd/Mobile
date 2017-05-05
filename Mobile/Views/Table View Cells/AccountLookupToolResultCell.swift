//
//  AccountLookupToolResultCell.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountLookupToolResultCell: UITableViewCell {
    
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var streetNumberLabel: UILabel!
    @IBOutlet weak var unitNumberLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        accountNumberLabel.textColor = .blackText
        streetNumberLabel.textColor = .deepGray
        unitNumberLabel.textColor = .deepGray
    }

}
