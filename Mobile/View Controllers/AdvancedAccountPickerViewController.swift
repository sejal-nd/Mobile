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

class AdvancedAccountPickerViewController: DismissableFormSheetViewController {
    
    weak var delegate: AdvancedAccountPickerViewControllerDelegate?

    @IBOutlet weak var tableView: UITableView!
    
    var expandedStates = [Bool]()
    var accounts: [Account]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 64
        
        // Make the currently selected account the first item in list
        let index = AccountsStore.sharedInstance.accounts.index(of: AccountsStore.sharedInstance.currentAccount)
        let currentAccount = accounts.remove(at: index!)
        accounts.insert(currentAccount, at: 0)
        
        for _ in accounts {
            expandedStates.append(false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }

}

extension AdvancedAccountPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.advancedAccountPickerViewController(self, didSelectAccount: accounts[indexPath.row])
        if UIDevice.current.userInterfaceIdiom == .pad {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
}

extension AdvancedAccountPickerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let account = accounts[indexPath.row]
        
        if account.currentPremise != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! MultiPremiseTableViewCell
            cell.configureCellWith(account: account)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AdvancedAccountPickerTableViewCell
            cell.configureCellWith(account: account)
            return cell
        }
        
//        // Decision made on 5/2/17 that BGE is unable to display multi-premise addresses
//        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewDropDownCell", for: indexPath) as! MultiPremiseDropDownTableViewCell
//        
//        let account = accounts[indexPath.row]
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



