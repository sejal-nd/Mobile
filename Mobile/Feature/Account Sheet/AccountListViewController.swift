//
//  AdvancedAccountPickerViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

//protocol AdvancedAccountPickerViewControllerDelegate: class {
//    func advancedAccountPickerViewController(_ advancedAccountPickerViewController: AdvancedAccountPickerViewController, didSelectAccount account: Account)
//}


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
        
        registerNibs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // perhaps we can handle this at the accountStore layer so that we never have to bother doing this.  always keep the array up to date.
        accounts = AccountsStore.reorderAccountList()
        
        print("Accounts: \(accounts.count)...\n\n\n\(accounts)")
        
        
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
    
    private func registerNibs() {
        let accountListCell = UINib(nibName: AccountListRow.className, bundle: nil)
        tableView.register(accountListCell, forCellReuseIdentifier: AccountListRow.className)
        
        tableView.isScrollEnabled = false
    }

}


// MARK: - Table View Delegate

extension AccountListViewController: UITableViewDelegate {
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 200
//    }
    
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
        
        
//        if account.isMultipremise {
//            UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select premises address", comment: ""))
//            self.accountIndexToEditPremise = indexPath.row
//
//            let dataArray = account.premises.map { $0.addressLineString }
//            PickerView.showStringPicker(withTitle: NSLocalizedString("Select Premise", comment: ""),
//                            data: dataArray,
//                            selectedIndex: 0,
//                            onDone: { [weak self] value, index in
//                                guard let self = self else { return }
//                                self.accounts[self.accountIndexToEditPremise].currentPremise = self.accounts[self.accountIndexToEditPremise].premises[index]
//
//                                AccountsStore.shared.accounts = self.accounts
//
//                                self.exitWith(selectedAccount: self.accounts[self.accountIndexToEditPremise])
//                },
//                            onCancel: nil)
//        } else {
        
//        }
    }
    
    func exitWith(selectedAccount: Account) {
//        delegate?.advancedAccountPickerViewController(self, didSelectAccount: selectedAccount)
//        if UIDevice.current.userInterfaceIdiom == .pad {
            dismiss(animated: true, completion: nil)
//        } else {
//            navigationController?.popViewController(animated: true)
//        }
    }
    
}


// MARK: - Table View Data Source

extension AccountListViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
//    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Accounts: \(accounts.count)")
        return accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let account = accounts[indexPath.row]
//        
//        print("cellForROw@")
//        
//        if account.isMultipremise {
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountListRow.className, for: indexPath) as! AccountListRow
            cell.configure(withAccount: account)
            return cell
//        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: AdvancedAccountPickerTableViewCell.className, for: indexPath) as! AdvancedAccountPickerTableViewCell
//            cell.configure(withAccount: account)
//            return cell
//        }
    }
}


