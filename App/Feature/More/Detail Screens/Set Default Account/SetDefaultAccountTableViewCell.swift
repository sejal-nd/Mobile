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
        radioButtonImageView.isAccessibilityElement = false
        
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
    
    func configure(withAccount account: Account) {
        accountTypeImageView.image = account.isResidential ? #imageLiteral(resourceName: "ic_residential_mini.pdf") : #imageLiteral(resourceName: "ic_commercial_mini.pdf")
        accountTypeImageView.isAccessibilityElement = false
        accountTypeImageView.accessibilityLabel = account.isResidential ? NSLocalizedString("Residential account", comment: "") :
            NSLocalizedString("Commercial account", comment: "")
        
        // Account Number
        let accountNumberText: String
        if account.isDefault {
            accountNumberText = "\(account.displayName) (Default)"
        } else if account.isFinaled {
            let status = Environment.shared.opco.isPHI ? "(Inactive)" : "(Finaled)"
            accountNumberText = "\(account.displayName) \(status)"
        } else if account.isLinked {
            accountNumberText = "\(account.displayName) (Linked)"
        } else {
            accountNumberText = account.displayName
        }
        accountNumberLabel.text = accountNumberText
        
        accountNumberLabel.accessibilityLabel = Environment.shared.opco.isPHI ? String(format: NSLocalizedString("Account %@", comment: ""), accountNumberText) : String(format: NSLocalizedString("Account number %@", comment: ""), accountNumberText)
        
        // If no address, use " " so that all the cells maintain equal height (nil or empty would collapse StackView)
        addressLabel.text = account.address ?? " "

        self.accessibilityLabel = "\(isSelected ? NSLocalizedString("Selected", comment: "") : ""), \(accountTypeImageView.accessibilityLabel ?? ""), \(accountNumberLabel.accessibilityLabel ?? "")"
    }
    
    func setIsEnabled(_ enabled: Bool) {
        radioButtonImageView.alpha = enabled ? 1 : 0.2
        accountTypeImageView.alpha = enabled ? 1 : 0.2
        accountNumberLabel.alpha = enabled ? 1 : 0.2
        addressLabel.alpha = enabled ? 1 : 0.2
        accessibilityTraits = enabled ? .none : .notEnabled
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        radioButtonImageView.image = selected ? #imageLiteral(resourceName: "ic_radiobutton_selected") : #imageLiteral(resourceName: "ic_radiobutton_deselected")
    }
    
}
