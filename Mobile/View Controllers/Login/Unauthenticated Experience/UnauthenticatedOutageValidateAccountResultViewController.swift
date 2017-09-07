//
//  UnauthenticatedOutageValidateAccountResultViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 9/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UnauthenticatedOutageValidateAccountResultViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: UnauthenticatedOutageViewModel! // Passed from UnauthenticatedOutageValidateAccountViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData() // To properly set the width constraints
    }
    
    

}

extension UnauthenticatedOutageValidateAccountResultViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
}

extension UnauthenticatedOutageValidateAccountResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "LookupToolResultCell", for: indexPath) as! AccountLookupToolResultCell
//        
//        let account = viewModel.accountLookupResults[indexPath.row]
//        cell.accountNumberLabel.text = account.accountNumber?.maskAllButLast4Digits()
//        cell.streetNumberLabel.text = account.streetNumber
//        cell.unitNumberLabel.text = account.unitNumber
//        
//        cell.accountNumberLabelWidthConstraint.constant = accountNumberHeaderLabel.frame.size.width
//        cell.streetNumberLabelWidthConstraint.constant = streetNumberHeaderLabel.frame.size.width
//        cell.unitNumberLabelWidthConstraint.constant = unitNumberHeaderLabel.frame.size.width
//        
//        return cell
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let selectedAccount = viewModel.accountLookupResults[indexPath.row]
//        for vc in (self.navigationController?.viewControllers)! {
//            guard let dest = vc as? ForgotUsernameViewController else {
//                continue
//            }
//            self.delegate = dest
//            self.delegate?.accountLookupToolDidSelectAccount(accountNumber: selectedAccount.accountNumber!, phoneNumber: self.viewModel.phoneNumber.value)
//            self.navigationController?.popToViewController(dest, animated: true)
//            break
//        }
    }
}
