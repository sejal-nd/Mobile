//
//  AdvancedAccountPickerDropDownTableViewCell.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AdvancedAccountPickerDropDownTableViewCell: UITableViewCell {

    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumber: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var accountImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var accountStatusLabel: UILabel!
    @IBOutlet weak var premisesLabel: UILabel!
    @IBOutlet weak var viewAddressesLabel: UILabel!
    @IBOutlet weak var viewAddressesButton: UIButton!
    @IBOutlet weak var bottomPremisLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var caretImageView: UIImageView!
    
    var isExpanded = false

}
