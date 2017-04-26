//
//  AccountListViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol AccountListViewControllerDelegate {
    func didSelectAccount(currentAccount: Account)
}

class AccountListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var accounts = [Account]()
    var currentAccount: Account?
    
    var delegate: AccountListViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }

}

extension AccountListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AccountTableViewCell {
            let cells = self.tableView.visibleCells as! Array<AccountTableViewCell>
            for cell in cells {
                if cell.accountNumber.text == currentAccount?.accountNumber {
                    cell.accountNumber.textColor = .black
                }
            }
            cell.accountNumber.textColor = .primaryColor
            for account in accounts {
                if account.accountNumber == cell.accountNumber.text {
                    currentAccount = account
                }
            }
            delegate?.didSelectAccount(currentAccount: currentAccount!)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}

extension AccountListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AccountTableViewCell
        let account = accounts[indexPath.row]
        cell.accountNumber.text = account.accountNumber
        cell.addressLabel.text = account.address
        if account.accountType == .Commercial {
            cell.accountImageView.image = #imageLiteral(resourceName: "ic_commercial")
        } else {
            cell.accountImageView.image = #imageLiteral(resourceName: "ic_residential")
        }
        if account.accountNumber == self.currentAccount?.accountNumber {
            cell.accountNumber.textColor = UIColor.primaryColor
            cell.separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
        } else {
            cell.accountImageViewLeadingConstraint.constant = 16
            cell.separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
            cell.checkMarkImageView.isHidden = true
        }
        
        return cell
    }
    
}



