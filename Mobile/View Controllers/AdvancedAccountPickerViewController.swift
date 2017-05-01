//
//  AccountListViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol AdvancedAccountPickerViewControllerDelegate {
    func advancedAccountPickerViewController(_ advancedAccountPickerViewController: AdvancedAccountPickerViewController, didSelectAccount account: Account)
}

class AdvancedAccountPickerViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var accounts = [Account]()
    var expandedStates = [Bool]()
    var currentAccount: Account?
    
    var delegate: AdvancedAccountPickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 64
        for _ in accounts {
            expandedStates.append(false)
        }
    }
    
    func showPremises(sender: UIButton) {
        if let cell = tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? AdvancedAccountPickerDropDownTableViewCell {
            print("tapped \(cell)")
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
        currentAccount = accounts[indexPath.row]
        delegate?.advancedAccountPickerViewController(self, didSelectAccount: currentAccount!)
        self.navigationController?.popViewController(animated: true)
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
        if indexPath.row == 0 && Environment.sharedInstance.opco == .bge {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewDropDownCell", for: indexPath) as! AdvancedAccountPickerDropDownTableViewCell
            
            let account = accounts[indexPath.row]
            
            cell.accountImageView.image = account.accountType == .Commercial ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
            cell.accountNumber.text = account.accountNumber
            cell.addressLabel.text = account.address
            cell.accountStatusLabel.text = ""
            cell.viewAddressesButton.tag = indexPath.row
            cell.viewAddressesButton.addTarget(self, action: #selector(showPremises), for: .touchUpInside)
            
            if account.accountNumber == currentAccount?.accountNumber {
                cell.accountImageViewLeadingConstraint.constant = 39
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                cell.checkMarkImageView.isHidden = false
            } else {
                cell.accountImageViewLeadingConstraint.constant = 16
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                cell.checkMarkImageView.isHidden = true
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AdvancedAccountPickerTableViewCell
            
            let account = accounts[indexPath.row]
            
            cell.accountImageView.image = account.accountType == .Commercial ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
            cell.accountNumber.text = account.accountNumber
            cell.addressLabel.text = account.address
            cell.accountStatusLabel.text = ""
            
            if account.accountNumber == currentAccount?.accountNumber {
                cell.accountImageViewLeadingConstraint.constant = 39
                cell.separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
                cell.checkMarkImageView.isHidden = false
            } else {
                cell.accountImageViewLeadingConstraint.constant = 16
                cell.separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
                cell.checkMarkImageView.isHidden = true
            }
            return cell
        }
            
        
        
        
    }
    
}



