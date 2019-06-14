//
//  AdvancedAccountPickerViewController.swift
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
    
    var accounts: [Account]!
    var accountIndexToEditPremise = -1

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tableView = UITableView().usingAutoLayout()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        title = NSLocalizedString("Accounts", comment: "")
        hidesBottomBarWhenPushed = true
        
        let nib1 = UINib(nibName: AdvancedAccountPickerTableViewCell.className, bundle: nil)
        let nib2 = UINib(nibName: AdvancedAccountPickerMultiPremiseTableViewCell.className, bundle: nil)
        tableView.register(nib1, forCellReuseIdentifier: AdvancedAccountPickerTableViewCell.className)
        tableView.register(nib2, forCellReuseIdentifier: AdvancedAccountPickerMultiPremiseTableViewCell.className)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make the currently selected account the first item in list
        let currentAccount = accounts.remove(at: AccountsStore.shared.currentIndex)
        accounts.insert(currentAccount, at: 0)
        
        if StormModeStatus.shared.isOn {
            navigationController?.setColoredNavBar()
        } else {
            navigationController?.setWhiteNavBar()
        }
    }

}

extension AdvancedAccountPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let account = accounts[indexPath.row]
        
        if account.isMultipremise {
            UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select premises address", comment: ""))
            self.accountIndexToEditPremise = indexPath.row
            
            let dataArray = account.premises.map { $0.addressLineString }
            PickerView.showStringPicker(withTitle: NSLocalizedString("Select Premise", comment: ""),
                            data: dataArray,
                            selectedIndex: 0,
                            onDone: { [weak self] value, index in
                                guard let self = self else { return }
                                self.accounts[self.accountIndexToEditPremise].currentPremise = self.accounts[self.accountIndexToEditPremise].premises[index]
                                
                                AccountsStore.shared.accounts = self.accounts
                                
                                self.exitWith(selectedAccount: self.accounts[self.accountIndexToEditPremise])
                },
                            onCancel: nil)
        } else {
            self.exitWith(selectedAccount: accounts[indexPath.row])
        }
    }
    
    func exitWith(selectedAccount: Account) {
        delegate?.advancedAccountPickerViewController(self, didSelectAccount: selectedAccount)
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
        return 64
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let account = accounts[indexPath.row]
        if account.isMultipremise {
            return UITableView.automaticDimension
        } else {
            return 64
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let account = accounts[indexPath.row]
        
        if account.isMultipremise {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdvancedAccountPickerMultiPremiseTableViewCell", for: indexPath) as! AdvancedAccountPickerMultiPremiseTableViewCell
            cell.configureCellWith(account: account)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdvancedAccountPickerTableViewCell", for: indexPath) as! AdvancedAccountPickerTableViewCell
            cell.configure(withAccount: account)
            return cell
        }
    }
}


