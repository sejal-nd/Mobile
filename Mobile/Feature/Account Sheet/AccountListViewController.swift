//
//  AdvancedAccountPickerViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var isScrollEnabled = false {
        didSet {
            tableView.isScrollEnabled = isScrollEnabled
        }
    }
    
    private var accounts = AccountsStore.shared.accounts ?? [Account]()
    private var accountIndexToEditPremise = -1

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // perhaps we can handle this at the accountStore layer so that we never have to bother doing this.  always keep the array up to date.
//        accounts = AccountsStore.reorderAccountList()
        
//        
//        // Make the currently selected account the first item in list
//        let currentAccount = accounts.remove(at: AccountsStore.shared.currentIndex)
//        accounts.insert(currentAccount, at: 0)
//        
//        if StormModeStatus.shared.isOn {
//            navigationController?.setColoredNavBar()
//        } else {
//            navigationController?.setWhiteNavBar()
//        }
    }
    
    deinit {
        print("deinit tvc")
    }
    
    
    // MARK: - Helper
    
    private func configureTableView() {
//        let accountListCell = UINib(nibName: AccountListRow.className, bundle: nil)
//        tableView.register(accountListCell, forCellReuseIdentifier: AccountListRow.className)
        
        tableView.isScrollEnabled = false
        tableView.tableFooterView = UIView()
    }

}


// MARK: - Table View Delegate

extension AccountListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let account = accounts[indexPath.row]
        if account.isMultipremise {
            let cell = tableView.cellForRow(at: indexPath) as! AccountListRow
            cell.didPress()
            tableView.beginUpdates()
            tableView.endUpdates()
        } else {
            self.exitWith(selectedAccount: accounts[indexPath.row])
        }
    }
    
    func exitWith(selectedAccount: Account) {
        dismiss(animated: true, completion: nil)
    }
    
}


// MARK: - Table View Data Source

extension AccountListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountListRow.className, for: indexPath) as! AccountListRow
        let account = accounts[indexPath.row]
        cell.configure(withAccount: account)
        return cell
    }
}


