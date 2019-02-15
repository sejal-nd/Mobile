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
    @IBOutlet weak var accountStatusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .black
        accountNumber.font = SystemFont.regular.of(textStyle: .headline)
        addressLabel.textColor = .middleGray
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountStatusLabel.textColor = .middleGray
    }
    
    func configure(withAccount account: Account) {
        let commercialUser = !account.isResidential
        
        accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
        accountImageView.isAccessibilityElement = false
        accountImageView.accessibilityLabel = commercialUser ? NSLocalizedString("Commercial account", comment: "") : NSLocalizedString("Residential account", comment: "")
        accountNumber.text = account.accountNumber
        accountNumber.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), account.accountNumber)
        addressLabel.text = account.address
        if let address = account.address {
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address: %@.", comment: ""), address)
        } else {
            addressLabel.accessibilityLabel = nil
        }
        
        if account.isDefault {
            accountStatusLabel.text = NSLocalizedString("Default", comment: "")
        } else if account.isFinaled {
            accountStatusLabel.text = NSLocalizedString("Finaled", comment: "")
            accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial_disabled") : #imageLiteral(resourceName: "ic_residential_disabled")
        } else if account.isLinked {
            accountStatusLabel.text = NSLocalizedString("Linked", comment: "")
        } else {
            accountStatusLabel.text = nil
        }
        
        accountStatusLabel.isHidden = !(account.isDefault || account.isFinaled || account.isLinked)
        
        if account.accountNumber == AccountsStore.shared.currentAccount.accountNumber {
            separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
            checkMarkImageView.isHidden = false
            checkMarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
            checkMarkImageView.isHidden = true
        }
        checkMarkImageView.isAccessibilityElement = false
        
        if let text = accountStatusLabel.text {
            accountStatusLabel.accessibilityLabel = "\(text) account"
        } else {
            accountStatusLabel.accessibilityLabel = nil
        }
        self.accessibilityLabel = "\(checkMarkImageView.accessibilityLabel ?? ""), \(accountImageView.accessibilityLabel ?? ""), \(accountNumber.accessibilityLabel ?? ""), " +
        "\(addressLabel.accessibilityLabel ?? "") \(accountStatusLabel.accessibilityLabel ?? "")"
        
    }
    
}
