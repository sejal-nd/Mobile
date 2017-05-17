//
//  AdvancedAccountPickerTableViewCell.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AdvancedAccountPickerTableViewCell: UITableViewCell {

    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumber: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var accountImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var accountStatusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .black
        addressLabel.textColor = .middleGray
        accountStatusLabel.textColor = .middleGray
    }
    
}
