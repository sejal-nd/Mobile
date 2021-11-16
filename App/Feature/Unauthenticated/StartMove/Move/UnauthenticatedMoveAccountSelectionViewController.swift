//
//  UnauthenticatedMoveAccountSelectionViewController.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 03/11/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class UnauthenticatedMoveAccountSelectionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var col1HeaderLabel: UILabel!
    @IBOutlet weak var col2HeaderLabel: UILabel!
    @IBOutlet weak var col3HeaderLabel: UILabel!
    @IBOutlet weak var firstSeparatorView: UIView!
    @IBOutlet weak var selectAccountButton: PrimaryButton!
    var viewModel: UnauthenticatedMoveAccountSelectionViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Select an Account", comment: "")
        addBackButton()
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("Select the account where you would like to stop your service.", comment: "")

        col1HeaderLabel.textColor = .deepGray
        col1HeaderLabel.text = NSLocalizedString("Account #", comment: "")
        col1HeaderLabel.isAccessibilityElement = true
        col1HeaderLabel.accessibilityLabel = NSLocalizedString("Account Number", comment: "")

        col2HeaderLabel.textColor = .deepGray
        col2HeaderLabel.text = NSLocalizedString("Street #", comment: "")
        col2HeaderLabel.isAccessibilityElement = true
        col2HeaderLabel.accessibilityLabel = NSLocalizedString("Street Number", comment: "")

        col3HeaderLabel.textColor = .deepGray
        col3HeaderLabel.text = NSLocalizedString("Unit #", comment: "")
        col3HeaderLabel.isAccessibilityElement = true
        col3HeaderLabel.accessibilityLabel = NSLocalizedString("Unit Number", comment: "")

        firstSeparatorView.backgroundColor = tableView.separatorColor

        tableView.tableFooterView = UIView()
        selectAccountButton.isEnabled = viewModel.canEnableContinue
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    @IBAction func selectAccountPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
        let moveServiceViewController = storyboard.instantiateViewController(withIdentifier: "MoveLandingViewController") as! MoveLandingViewController
        moveServiceViewController.viewModel.unauthMoveData = viewModel.unauthMoveData
        self.navigationController?.pushViewController(moveServiceViewController, animated: true)
    }
    func addBackButton(){
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(UnauthenticatedMoveAccountSelectionViewController.back(sender:)))
        newBackButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    @objc func back(sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
extension UnauthenticatedMoveAccountSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.accountsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSelectionCell", for: indexPath) as! UnauthenticatedMoveAccountSelectionCell

        let accountLookup = viewModel.accountsList[indexPath.row]

        cell.accountNumberLabel.text = viewModel.getMaskedAccountNumber(accountLookup.accountNumber!)
        cell.accountNumberLabel.accessibilityLabel = NSLocalizedString("Account number ending in \(viewModel.getMaskedAccountNumber(accountLookup.accountNumber!))", comment: "")
        cell.streetNumberLabel.text = accountLookup.streetNumber ?? ""
        cell.streetNumberLabel.accessibilityLabel = NSLocalizedString("Street number, \(accountLookup.streetNumber ?? "None")", comment: "")
        cell.unitNumberLabel.text = accountLookup.getUnit()
        cell.unitNumberLabel.accessibilityLabel = NSLocalizedString("Unit number, \(accountLookup.unitNumber ?? "None")", comment: "")

        cell.accountNumberLabelWidthConstraint.constant = col1HeaderLabel.frame.size.width

        cell.streetNumberLabelWidthConstraint.constant = col2HeaderLabel.frame.size.width
        cell.unitNumberLabelWidthConstraint.constant = col3HeaderLabel.frame.size.width

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.setSelectedAccount(account: viewModel.accountsList[indexPath.row])
        selectAccountButton.isEnabled = viewModel.canEnableContinue
    }
}
