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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .orange//.black
        accountNumber.font = SystemFont.regular.of(textStyle: .headline)
        addressLabel.textColor = .middleGray
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
    }
    
    func configure(withAccount account: Account) {
        let commercialUser = !account.isResidential
        
        accountImageView.image = commercialUser ? UIImage(named: "ic_commercial_mini") : UIImage(named: "ic_residential_mini")
        accountImageView.isAccessibilityElement = false
        accountImageView.accessibilityLabel = commercialUser ? NSLocalizedString("Commercial account", comment: "") : NSLocalizedString("Residential account", comment: "")
        addressLabel.text = account.address
        if let address = account.address {
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address: %@.", comment: ""), address)
        } else {
            addressLabel.accessibilityLabel = nil
        }
        
        let accountNumberText: String
        if account.isDefault {
            accountNumberText = "\(account.accountNumber) (Default)"
        } else if account.isFinaled {
            accountNumberText = "\(account.accountNumber) (Finaled)"
            accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial_disabled") : #imageLiteral(resourceName: "ic_residential_disabled")
        } else if account.isLinked {
            accountNumberText = "\(account.accountNumber) (Linked)"
        } else {
            accountNumberText = account.accountNumber
        }
        
        accountNumber.text = account.accountNumber
        accountNumber.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), accountNumberText)
                
        if account.accountNumber == AccountsStore.shared.currentAccount.accountNumber {
            separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
            checkMarkImageView.isHidden = false
            checkMarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
            checkMarkImageView.isHidden = true
        }
        checkMarkImageView.isAccessibilityElement = false

        self.accessibilityLabel = "\(checkMarkImageView.accessibilityLabel ?? ""), \(accountImageView.accessibilityLabel ?? ""), \(accountNumber.accessibilityLabel ?? ""), "
    }
    
}
