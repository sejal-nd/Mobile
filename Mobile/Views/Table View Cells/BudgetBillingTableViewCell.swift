//
//  BudgetBillingTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BudgetBillingTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var radioButtonImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        label.textColor = .darkJungleGreen
        radioButtonImageView.image = #imageLiteral(resourceName: "ic_radiobutton_deselected")
        
        selectionStyle = .none
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        radioButtonImageView.image = selected ? #imageLiteral(resourceName: "ic_radiobutton_selected") : #imageLiteral(resourceName: "ic_radiobutton_deselected")
    }

}
