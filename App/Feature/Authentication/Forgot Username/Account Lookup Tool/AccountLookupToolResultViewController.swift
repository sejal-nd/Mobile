//
//  AccountLookupToolResultViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

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
    @IBOutlet weak var selectAccountButton: PrimaryButton!
    
    var viewModel: AccountLookupToolViewModel!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Account Lookup Tool", comment: "")
        addCloseButton()
        instructionLabel.textColor = .neutralDark
        instructionLabel.text = NSLocalizedString("Please select your account.", comment: "")
        instructionLabel.font = .headline
        
        accountNumberHeaderLabel.textColor = .neutralDark
        accountNumberHeaderLabel.font = .footnote
        accountNumberHeaderLabel.text = NSLocalizedString("Account #", comment: "")
        
        streetNumberHeaderLabel.textColor = .neutralDark
        streetNumberHeaderLabel.font = .footnote
        streetNumberHeaderLabel.text = NSLocalizedString("Street #", comment: "")
        
        unitNumberHeaderLabel.textColor = .neutralDark
        unitNumberHeaderLabel.font = .footnote
        unitNumberHeaderLabel.text = NSLocalizedString("Unit #", comment: "")
        
        firstSeparatorView.backgroundColor = tableView.separatorColor
        
        tableView.isHidden = true
        tableView.tableFooterView = UIView() // Hides extra separators
        
        viewModel.selectAccountButtonEnabled.drive(selectAccountButton.rx.isEnabled).disposed(by: disposeBag)
        viewModel.selectValidatedAccountButtonEnabled.drive(selectAccountButton.rx.isEnabled).disposed(by: disposeBag)
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
    
    @IBAction func onSelectAccountPress() {
        FirebaseUtility.logEvent(.forgotUsername(parameters: [.account_selected_cta]))
        if let selectedAccount = viewModel.selectedAccount.value {
            delegate?.accountLookupToolDidSelectAccount(accountNumber: selectedAccount.accountNumber!, phoneNumber: viewModel.phoneNumber.value)
            dismiss(animated: true, completion: nil)
        } else if (viewModel.selectedValidatedPinAccount.value != nil) {
                delegate?.accountLookupToolDidSelectAccount(accountNumber: viewModel.selectedValidatedPinAccount.value?.accountNumber ?? "", phoneNumber: viewModel.phoneNumber.value)
                dismiss(animated: true, completion: nil)
            }
        }
}

extension AccountLookupToolResultViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (viewModel.accountLookupResults.count > 0) {
            return viewModel.accountLookupResults.count
        } else {
            return viewModel.validatePinResult.accounts?.count ?? 0
        }
    }
}

extension AccountLookupToolResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LookupToolResultCell", for: indexPath) as! AccountLookupToolResultCell
        var a11yLabel = ""
        
        if (viewModel.accountLookupResults.count > 0) {
            let account = viewModel.accountLookupResults[indexPath.row]
            
            cell.accountNumberLabel.text = account.accountNumber?.maskAllButLast4Digits()
            cell.streetNumberLabel.text = account.streetNumber
            cell.unitNumberLabel.text = account.unitNumber
            
        
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
        } else if (viewModel.validatePinResult.accounts?.count > 0) {
            let account = viewModel.validatePinResult.accounts?[indexPath.row]
            
            cell.accountNumberLabel.text = account?.accountNumber?.maskAllButLast4Digits()
            cell.streetNumberLabel.text = account?.streetNumber
            cell.unitNumberLabel.text = account?.unitNumber
            
            if let accountNumber = account?.accountNumber, !accountNumber.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Account number ending in %@,", comment: ""), accountNumber.maskAllButLast4Digits().replacingOccurrences(of: "*", with: ""))
            }
            if let streetNumber = account?.streetNumber, !streetNumber.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Street number: %@,", comment: ""), streetNumber)
            }
            if let unitNumber = account?.unitNumber, !unitNumber.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Unit number: %@", comment: ""), unitNumber)
            }
            cell.accessibilityLabel = a11yLabel
        }
        cell.accountNumberLabelWidthConstraint.constant = accountNumberHeaderLabel.frame.size.width
        cell.streetNumberLabelWidthConstraint.constant = streetNumberHeaderLabel.frame.size.width
        cell.unitNumberLabelWidthConstraint.constant = unitNumberHeaderLabel.frame.size.width

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewModel.accountLookupResults.count > 0 {
            viewModel.selectedAccount.accept(viewModel.accountLookupResults[indexPath.row])
        } else {
            viewModel.selectedValidatedPinAccount.accept(viewModel.validatePinResult.accounts?[indexPath.row])
        }
    }
}
