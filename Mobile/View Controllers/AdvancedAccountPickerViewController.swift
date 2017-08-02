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
    
    var premisePickerView: ExelonPickerContainerView!
    
    var zPositionForWindow:CGFloat = 0.0
    
    var accountIndexToEditPremise = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        buildPickerView()
    }
    
    func buildPickerView() {
        
        let currentWindow = UIApplication.shared.keyWindow
        premisePickerView = ExelonPickerContainerView(frame: (currentWindow?.frame)!)
        
        currentWindow?.addSubview(premisePickerView)
        
        premisePickerView.leadingAnchor.constraint(equalTo: (currentWindow?.leadingAnchor)!, constant: 0).isActive = true
        premisePickerView.trailingAnchor.constraint(equalTo: (currentWindow?.trailingAnchor)!, constant: 0).isActive = true
        premisePickerView.topAnchor.constraint(equalTo: (currentWindow?.topAnchor)!, constant: 0).isActive = true
        
        let height = premisePickerView.containerView.frame.size.height + 8
        premisePickerView.bottomConstraint.constant = height
        
        premisePickerView.delegate = self
        
        zPositionForWindow = (currentWindow?.layer.zPosition)!
        
        premisePickerView.isHidden = true
    }
    
    func showPickerView(_ showPicker: Bool, completion: (() -> ())? = nil) {
        if showPicker {
            self.premisePickerView.isHidden = false
            
            let row = 0
            
            self.premisePickerView.selectRow(row)
        }
        
        self.premisePickerView.layer.zPosition = showPicker ? self.zPositionForWindow : -1
        UIApplication.shared.keyWindow?.layer.zPosition = showPicker ? -1 : self.zPositionForWindow
        
        var bottomAnchorLength = self.premisePickerView.containerView.frame.size.height + 8
        var alpha:Float = 0.0
        
        if showPicker {
            alpha = 0.6
            bottomAnchorLength = -8
        }
        
        self.premisePickerView.bottomConstraint.constant = bottomAnchorLength
        
        self.premisePickerView.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: {
            self.premisePickerView.layoutIfNeeded()
            self.premisePickerView.backgroundColor =  UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: alpha)
        }, completion: { _ in
            if !showPicker {
                self.premisePickerView.accessibilityViewIsModal = false
                self.premisePickerView.isHidden = true
            } else {
                self.premisePickerView.accessibilityViewIsModal = true
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.premisePickerView)
            }
            
            completion?()
        })
    }

}

extension AdvancedAccountPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let account = accounts[indexPath.row]
        
        if account.isMultipremise {
            self.accountIndexToEditPremise = indexPath.row
            
            let dataArray = account.premises.map({ (premise: Premise) -> String in
                return premise.addressLineString
            })
            premisePickerView.addNewData(dataArray: dataArray)
            self.showPickerView(true)
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
        let account = accounts[indexPath.row]
        
        if account.isMultipremise {
            return 125
        } else {
            return 64
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let account = accounts[indexPath.row]
        
        if account.isMultipremise {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewMultPremiseCell", for: indexPath) as! MultiPremiseTableViewCell
            cell.configureCellWith(account: account)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AdvancedAccountPickerTableViewCell
            cell.configure(withAccount: account)
            return cell
        }
    }
}

extension AdvancedAccountPickerViewController: ExelonPickerDelegate {
    func cancelPressed() {
        self.showPickerView(false)
    }
    
    func donePressed(selectedIndex: Int) {
        dLog(message: "selectedIndex \(selectedIndex)")
        
        self.accounts[self.accountIndexToEditPremise].currentPremise = self.accounts[self.accountIndexToEditPremise].premises[selectedIndex]
        
        AccountsStore.sharedInstance.accounts = self.accounts
        
        self.showPickerView(false) { 
            self.exitWith(selectedAccount: self.accounts[self.accountIndexToEditPremise])
        }
    }
}



