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
        
        let trolleyGreyColor = UIColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 1)
        
        accountNumberLabel.textColor = .darkJungleGreen
        streetNumberLabel.textColor = trolleyGreyColor
        unitNumberLabel.textColor = trolleyGreyColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
