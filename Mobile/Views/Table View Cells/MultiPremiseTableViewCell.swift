//
//  MultiPremiseTableViewCell.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MultiPremiseTableViewCell: UITableViewCell {

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
        
        let isCurrentAccount = account == AccountsStore.sharedInstance.currentAccount
        
        //top portion is the same as AdvancedAccountPickerTableViewCell
        let commercialUser = UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) && Environment.sharedInstance.opco != .bge
        
        self.accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
        self.accountImageView.isAccessibilityElement = true
        self.accountImageView.accessibilityLabel = commercialUser ? NSLocalizedString("Commercial account", comment: "") : NSLocalizedString("Residential account", comment: "")
        self.accountNumber.text = account.accountNumber
        self.accountNumber.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), account.accountNumber)
        self.addressLabel.text = account.address
        if let address = account.address {
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
        
        if account.accountNumber == AccountsStore.sharedInstance.currentAccount.accountNumber {
            self.accountImageViewLeadingConstraint.constant = 39
            self.separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
            self.checkMarkImageView.isHidden = false
            self.checkMarkImageView.isAccessibilityElement = true
            self.checkMarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            self.accountImageViewLeadingConstraint.constant = 16
            self.separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
            self.checkMarkImageView.isHidden = true
            self.checkMarkImageView.isAccessibilityElement = false
        }
        var premises = account.premises
        
        //make sure currentIndex is first in list
        let index = premises.index(of: account.currentPremise!)
        let currentPremise = premises.remove(at: index!)
        premises.insert(currentPremise, at: 0)
        
        //premise info
        for (index, premise) in premises.enumerated() {
            guard let address = premise.address else {
                return
            }
            let showCheck = isCurrentAccount && index == 0
            let view = MultiPremiseAddressView.instanceFromNib(showsCheck: showCheck, labelText: address)
            self.premiseAddressStackView.addArrangedSubview(view)
            
        }
    }

}
