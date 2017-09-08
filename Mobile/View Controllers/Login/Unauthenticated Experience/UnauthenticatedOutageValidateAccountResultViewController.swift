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
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberHeaderLabel: UILabel!
    @IBOutlet weak var streetNumberHeaderLabel: UILabel!
    @IBOutlet weak var unitNumberHeaderLabel: UILabel!
    @IBOutlet weak var firstSeparatorView: UIView!
    
    var viewModel: UnauthenticatedOutageViewModel! // Passed from UnauthenticatedOutageValidateAccountViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        navigationItem.leftBarButtonItem = cancelButton
        
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please select your account:", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        accountNumberHeaderLabel.textColor = .middleGray
        accountNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        accountNumberHeaderLabel.text = NSLocalizedString("Account #", comment: "")
        
        streetNumberHeaderLabel.textColor = .middleGray
        streetNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        streetNumberHeaderLabel.text = NSLocalizedString("Street #", comment: "")
        
        unitNumberHeaderLabel.textColor = .middleGray
        unitNumberHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        unitNumberHeaderLabel.text = NSLocalizedString("Unit #", comment: "")
        
        firstSeparatorView.backgroundColor = tableView.separatorColor
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData() // To properly set the width constraints
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UnauthenticatedOutageStatusViewController {
            vc.viewModel = viewModel
        }
    }
    

}

extension UnauthenticatedOutageValidateAccountResultViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.outageStatusArray!.count
    }
}

extension UnauthenticatedOutageValidateAccountResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LookupToolResultCell", for: indexPath) as! AccountLookupToolResultCell
        
        let outageStatus = viewModel.outageStatusArray![indexPath.row]
        cell.accountNumberLabel.text = outageStatus.maskedAccountNumber ?? "nil"
        cell.streetNumberLabel.text = outageStatus.addressNumber ?? "nil"
        cell.unitNumberLabel.text = outageStatus.unitNumber
        
        cell.accountNumberLabelWidthConstraint.constant = accountNumberHeaderLabel.frame.size.width
        cell.streetNumberLabelWidthConstraint.constant = streetNumberHeaderLabel.frame.size.width
        cell.unitNumberLabelWidthConstraint.constant = unitNumberHeaderLabel.frame.size.width
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedOutageStatus = viewModel.outageStatusArray![indexPath.row]
        performSegue(withIdentifier: "outageStatusSegue", sender: self)
    }
}
