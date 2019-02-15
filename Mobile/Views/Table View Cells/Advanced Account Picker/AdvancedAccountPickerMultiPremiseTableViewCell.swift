//
//  AdvancedAccountPickerMultiPremiseTableViewCell.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AdvancedAccountPickerMultiPremiseTableViewCell: UITableViewCell {

    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumber: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var accountImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var accountStatusLabel: UILabel!
    @IBOutlet var premiseAddressStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .black
        accountNumber.font = SystemFont.regular.of(textStyle: .headline)
        addressLabel.textColor = .middleGray
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountStatusLabel.textColor = .middleGray
    }
    
    override func prepareForReuse() {
        let addressViews = premiseAddressStackView.arrangedSubviews
        for view in addressViews {
            premiseAddressStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
    func configureCellWith(account: Account) {
        
        let isCurrentAccount = account == AccountsStore.shared.currentAccount
        
        //top portion is the same as AdvancedAccountPickerTableViewCell
        let commercialUser = !account.isResidential
        
        self.accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
        self.accountImageView.isAccessibilityElement = false
        self.accountImageView.accessibilityLabel = commercialUser ? NSLocalizedString("Commercial account", comment: "") : NSLocalizedString("Residential account", comment: "")
        self.accountNumber.text = account.accountNumber
        self.accountNumber.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), account.accountNumber)
        
        if let currPremise = account.currentPremise, let address = currPremise.addressGeneral {
            self.addressLabel.text = address
            self.addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address %@", comment: ""), address)
        } else if let address = account.address {
            self.addressLabel.text = address
            self.addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address %@", comment: ""), address)
        }

        if account.isDefault {
            self.accountStatusLabel.text = NSLocalizedString("Default", comment: "")
        } else if account.isFinaled {
            self.accountStatusLabel.text = NSLocalizedString("Finaled", comment: "")
            self.accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial_disabled") : #imageLiteral(resourceName: "ic_residential_disabled")
        } else if account.isLinked {
            self.accountStatusLabel.text = NSLocalizedString("Linked", comment: "")
        } else {
            self.accountStatusLabel.text = ""
        }
        
        if account.accountNumber == AccountsStore.shared.currentAccount.accountNumber {
            
            self.separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
            self.checkMarkImageView.isHidden = false
            self.checkMarkImageView.isAccessibilityElement = true
            self.checkMarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            
            self.separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
            self.checkMarkImageView.isHidden = true
            self.checkMarkImageView.isAccessibilityElement = false
        }
        
        let premises = account.premises
        let currentPremiseIndex = premises.index(of: account.currentPremise!)
        
        //premise info
        for (index, premise) in premises.enumerated() {
            
            let address = premise.addressLineString
            let showCheck = isCurrentAccount && index == currentPremiseIndex
            let view = MultiPremiseAddressView.instanceFromNib(showsCheck: showCheck, labelText: address)
            view.addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
            view.checkMark.isAccessibilityElement = showCheck ? true : false
            if showCheck {
                view.checkMark.accessibilityLabel = NSLocalizedString("Selected premises. \(address)", comment: "")
            } else {
                view.addressLabel.isAccessibilityElement = true
                view.addressLabel.accessibilityLabel = NSLocalizedString("Premises \(address)", comment: "")
            }
            
            self.premiseAddressStackView.addArrangedSubview(view)
            premiseAddressStackView.setNeedsLayout()
            premiseAddressStackView.layoutIfNeeded()
            
        }
        
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
        
        self.accessibilityLabel = "Multiple premises account.  \(checkMarkImageView.accessibilityLabel ?? ""). \(accountImageView.accessibilityLabel ?? "").  \(accountNumber.accessibilityLabel ?? ""). " +
        "\(addressLabel.accessibilityLabel ?? "") \(accountStatusLabel.accessibilityLabel ?? "")."
    }

}
