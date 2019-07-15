//
//  SetDefaultAccountTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class SetDefaultAccountTableViewCell: UITableViewCell {

    @IBOutlet weak var radioButtonImageView: UIImageView!
    @IBOutlet weak var accountTypeImageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dividerLine: UIView!
    @IBOutlet weak var dividerLineHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        radioButtonImageView.image = #imageLiteral(resourceName: "ic_radiobutton_deselected")
        
        accountNumberLabel.textColor = .deepGray
        accountNumberLabel.font = SystemFont.regular.of(textStyle: .headline)

        addressLabel.textColor = .deepGray
        addressLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        dividerLine.backgroundColor = .accentGray
        
        selectionStyle = .none
    }
    
    override func updateConstraints() {
        dividerLineHeightConstraint.constant = 1.0 / UIScreen.main.scale
        super.updateConstraints()
    }
    
    func configureWith(account: Account) {
        accountNumberLabel.text = account.accountNumber
        addressLabel.text = account.address
        accountTypeImageView.image = account.isResidential ? #imageLiteral(resourceName: "ic_residential_mini.pdf") : #imageLiteral(resourceName: "ic_commercial_mini.pdf")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        radioButtonImageView.image = selected ? #imageLiteral(resourceName: "ic_radiobutton_selected") : #imageLiteral(resourceName: "ic_radiobutton_deselected")
    }
    
}
