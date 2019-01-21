//
//  AccountLookupToolResultViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol AccountLookupToolResultViewControllerDelegate: class {
    func accountLookupToolDidSelectAccount(accountNumber: String, phoneNumber: String)
}

class AccountLookupToolResultViewController: UIViewController {
    
    weak var delegate: AccountLookupToolResultViewControllerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberHeaderLabel: UILabel!
    @IBOutlet weak var streetNumberHeaderLabel: UILabel!
    @IBOutlet weak var unitNumberHeaderLabel: UILabel!
    @IBOutlet weak var firstSeparatorView: UIView!
    
    var viewModel: AccountLookupToolViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Account Lookup", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        navigationItem.leftBarButtonItem = cancelButton

        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please select your account:", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        accountNumberHeaderLabel.textColor = .middleGray
        accountNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberHeaderLabel.text = NSLocalizedString("Account Number", comment: "")
        
        streetNumberHeaderLabel.textColor = .middleGray
        streetNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        streetNumberHeaderLabel.text = NSLocalizedString("Street Number", comment: "")
        
        unitNumberHeaderLabel.textColor = .middleGray
        unitNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        unitNumberHeaderLabel.text = NSLocalizedString("Unit Number", comment: "")
        
        firstSeparatorView.backgroundColor = tableView.separatorColor
        
        tableView.isHidden = true
    }
    
    @objc func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // A few oddities going on here. Discovered an iOS 11 only bug where the table view cells would initially
        // be blank until they were scrolled off screen and reused. Also an issue when accessibility text is sized up
        // where we need to re-layout and compute the column width contraints. viewDidLayoutSubviews() will call
        // tableView.reloadData() and re-compute all the constraints. We hide the tableView initially and unhide
        // here so that you don't see the re-layout happen.
        viewDidLayoutSubviews()
        tableView.isHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData() // To properly set the width constraints
        
        // Dynamic sizing for the table header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
}

extension AccountLookupToolResultViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.accountLookupResults.count
    }
}

extension AccountLookupToolResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LookupToolResultCell", for: indexPath) as! AccountLookupToolResultCell
        
        let account = viewModel.accountLookupResults[indexPath.row]
        cell.accountNumberLabel.text = account.accountNumber?.maskAllButLast4Digits()
        cell.streetNumberLabel.text = account.streetNumber
        cell.unitNumberLabel.text = account.unitNumber
        
        var a11yLabel = ""
        if let accountNumber = account.accountNumber, !accountNumber.isEmpty {
            a11yLabel += String(format: NSLocalizedString("Account number ending in %@,", comment: ""), accountNumber.maskAllButLast4Digits().replacingOccurrences(of: "*", with: ""))
        }
        if let streetNumber = account.streetNumber, !streetNumber.isEmpty {
            a11yLabel += String(format: NSLocalizedString("Street number: %@,", comment: ""), streetNumber)
        }
        if let unitNumber = account.unitNumber, !unitNumber.isEmpty {
            a11yLabel += String(format: NSLocalizedString("Unit number: %@", comment: ""), unitNumber)
        }
        cell.accessibilityLabel = a11yLabel

        cell.accountNumberLabelWidthConstraint.constant = accountNumberHeaderLabel.frame.size.width
        cell.streetNumberLabelWidthConstraint.constant = streetNumberHeaderLabel.frame.size.width
        cell.unitNumberLabelWidthConstraint.constant = unitNumberHeaderLabel.frame.size.width

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAccount = viewModel.accountLookupResults[indexPath.row]
        for vc in (self.navigationController?.viewControllers)! {
            guard let dest = vc as? ForgotUsernameViewController else {
                continue
            }
            self.delegate = dest
            self.delegate?.accountLookupToolDidSelectAccount(accountNumber: selectedAccount.accountNumber!, phoneNumber: self.viewModel.phoneNumber.value)
            self.navigationController?.popToViewController(dest, animated: true)
            break
        }
    }
}
