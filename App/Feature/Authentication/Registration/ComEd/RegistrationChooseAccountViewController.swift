//
//  RegistrationChooseAccountViewController.swift
//  Mobile
//
//  Created by Adarsh Maurya on 27/07/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class RegistrationChooseAccountViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberHeaderLabel: UILabel!
    @IBOutlet weak var streetNumberHeaderLabel: UILabel!
    @IBOutlet weak var unitNumberHeaderLabel: UILabel!
    @IBOutlet weak var firstSeparatorView: UIView!
    @IBOutlet weak var selectAccountButton: PrimaryButton!
    
    var viewModel: RegistrationViewModel!
    weak var delegate: RegistrationViewControllerDelegate?

    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Select an Account", comment: "")
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("Select the account you would like to use for registration. If more than one account is associated with the one you choose, they will be registered together.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        instructionLabel.setLineHeight(lineHeight: 24)
        
        accountNumberHeaderLabel.textColor = .deepGray
        accountNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberHeaderLabel.text = NSLocalizedString("Account #", comment: "")
        
        streetNumberHeaderLabel.textColor = .deepGray
        streetNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        streetNumberHeaderLabel.text = NSLocalizedString("Street #", comment: "")
        
        unitNumberHeaderLabel.textColor = .deepGray
        unitNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        unitNumberHeaderLabel.text = NSLocalizedString("Unit #", comment: "")
        
        firstSeparatorView.backgroundColor = tableView.separatorColor
        
        tableView.isHidden = true
        tableView.tableFooterView = UIView() // Hides extra separators
        
        viewModel.selectAccountButtonEnabled.drive(selectAccountButton.rx.isEnabled).disposed(by: disposeBag)
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
        if let index = viewModel.multipleAccounts.firstIndex(where: {$0.accountNumber == viewModel.selectedAccount.value?.accountNumber}) {
            tableView.selectRow(at: IndexPath(row: index, section: .zero),
                                animated: false,
                                scrollPosition: .none)
        }
        
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
        LoadingView.show()
        viewModel.validateAccount(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)

            let segueIdentifier = "createCredentialsB2cSegue"
            self?.performSegue(withIdentifier: segueIdentifier, sender: self)
            }, onMultipleAccounts:  { [weak self] in
                LoadingView.hide()
                GoogleAnalytics.log(event: .registerAccountValidation)
               
                let segueIdentifier = "createCredentialsB2cSegue"
                self?.performSegue(withIdentifier: segueIdentifier, sender: self)
            }, onError: { [weak self] (title, message) in
                LoadingView.hide()
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
        })
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        if let vc = segue.destination as? RegistrationCreateCredentialsViewControllerNew {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? B2CRegistrationViewController {
            vc.validatedAccount = viewModel.validatedAccountResponse
            vc.selectedAccount = viewModel.selectedAccount.value
            vc.delegate = delegate
        }
    }
}

extension RegistrationChooseAccountViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  viewModel.multipleAccounts.count
    }
}

extension RegistrationChooseAccountViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LookupToolResultCell", for: indexPath) as! AccountLookupToolResultCell
        
        let account = viewModel.multipleAccounts[indexPath.row]
    
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
        viewModel.selectedAccount.accept(viewModel.multipleAccounts[indexPath.row])
    }
}
