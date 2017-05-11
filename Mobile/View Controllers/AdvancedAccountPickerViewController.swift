//
//  AccountListViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol AdvancedAccountPickerViewControllerDelegate: class {
    func advancedAccountPickerViewController(_ advancedAccountPickerViewController: AdvancedAccountPickerViewController, didSelectAccount account: Account)
}

class AdvancedAccountPickerViewController: UIViewController {
    
    weak var delegate: AdvancedAccountPickerViewControllerDelegate?

    @IBOutlet weak var tableView: UITableView!
    
    var expandedStates = [Bool]()
    var accounts = [Account]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 64
        for _ in AccountsStore.sharedInstance.accounts {
            expandedStates.append(false)
        }
        moveCurrentAccountToFrontOfAccountArray()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    func moveCurrentAccountToFrontOfAccountArray() {
        let index = AccountsStore.sharedInstance.accounts.index(of: AccountsStore.sharedInstance.currentAccount)
        let currentAccount = accounts.remove(at: index!)
        accounts.insert(currentAccount, at: 0)
    }
    
    func showPremises(sender: UIButton) {
        if let cell = tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? AdvancedAccountPickerDropDownTableViewCell {
            if cell.isExpanded == false {
                cell.viewAddressesLabel.isHidden = true
                cell.premisesLabel.text = "1215 E Fort Ave\n2109 Spring Garden St\n500 Norris St\n700 12th St NW"
                cell.caretImageView.image? = #imageLiteral(resourceName: "ic_carat_up")
                cell.isExpanded = true
            } else {
                cell.viewAddressesLabel.isHidden = false
                cell.premisesLabel.text = nil
                cell.caretImageView.image? = #imageLiteral(resourceName: "ic_carat_down")
                cell.isExpanded = false
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

}

extension AdvancedAccountPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.advancedAccountPickerViewController(self, didSelectAccount: AccountsStore.sharedInstance.accounts[indexPath.row])
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension AdvancedAccountPickerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AccountsStore.sharedInstance.accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AdvancedAccountPickerTableViewCell
        
        let account = accounts[indexPath.row]
        let commercialUser = UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) && Environment.sharedInstance.opco != .bge
        
        cell.accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
        cell.accountNumber.text = account.accountNumber
        cell.addressLabel.text = account.address

        if account.isLinked {
            cell.accountStatusLabel.text = "Linked"
        } else if account.isDefault {
            cell.accountStatusLabel.text = "Default"
        } else if account.isFinaled {
            cell.accountStatusLabel.text = "Finaled"
            cell.accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial_disabled") : #imageLiteral(resourceName: "ic_residential_disabled")
        } else {
            cell.accountStatusLabel.text = ""
        }
        
        if account.accountNumber == AccountsStore.sharedInstance.currentAccount.accountNumber {
            cell.accountImageViewLeadingConstraint.constant = 39
            cell.separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
            cell.checkMarkImageView.isHidden = false
        } else {
            cell.accountImageViewLeadingConstraint.constant = 16
            cell.separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
            cell.checkMarkImageView.isHidden = true
        }
        return cell
        
//        // Decision made on 5/2/17 that BGE is unable to display multi-premise addresses
//        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewDropDownCell", for: indexPath) as! AdvancedAccountPickerDropDownTableViewCell
//        
//        let account = AccountsStore.sharedInstance.accounts[indexPath.row]
//        
//        cell.accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
//        cell.accountNumber.text = account.accountNumber
//        cell.addressLabel.text = account.address
//        cell.accountStatusLabel.text = ""
//        cell.viewAddressesButton.tag = indexPath.row
//        cell.viewAddressesButton.addTarget(self, action: #selector(showPremises), for: .touchUpInside)
//        
//        if account.accountNumber == AccountsStore.sharedInstance.currentAccount.accountNumber {
//            cell.accountImageViewLeadingConstraint.constant = 39
//            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//            cell.checkMarkImageView.isHidden = false
//        } else {
//            cell.accountImageViewLeadingConstraint.constant = 16
//            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//            cell.checkMarkImageView.isHidden = true
//        }
//        return cell
    }
    
}



