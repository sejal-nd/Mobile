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
    
    var accounts: [Account]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.estimatedRowHeight = 64
        
        // Make the currently selected account the first item in list
        let index = AccountsStore.sharedInstance.accounts.index(of: AccountsStore.sharedInstance.currentAccount)
        let currentAccount = accounts.remove(at: index!)
        accounts.insert(currentAccount, at: 0)
        
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
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let account = accounts[indexPath.row]
        
        if account.premises.count > 0 {
            return 125
        } else {
            return 64
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
        let account = accounts[indexPath.row]
        
        if account.premises.count > 0 {
            return 125
        } else {
            return 64
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let account = accounts[indexPath.row]
        
        if account.premises.count > 0 {//TODO: should be 1 (depending if there's always a premise that matches the account)
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewMultPremiseCell", for: indexPath) as! MultiPremiseTableViewCell
            cell.configureCellWith(account: account)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AdvancedAccountPickerTableViewCell
            cell.configureCellWith(account: account)
            return cell
        }
    }
    
}



