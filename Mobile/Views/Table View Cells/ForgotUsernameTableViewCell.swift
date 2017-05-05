//
//  ForgotUsernameTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 4/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class ForgotUsernameTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var checkmarkAccessory: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        label.textColor = .blackText
        checkmarkAccessory.isHidden = true
        
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        checkmarkAccessory.isHidden = !selected
    }

}
