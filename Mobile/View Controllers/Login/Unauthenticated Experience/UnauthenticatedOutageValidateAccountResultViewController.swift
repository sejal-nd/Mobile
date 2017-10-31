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
    @IBOutlet weak var col1HeaderLabel: UILabel!
    @IBOutlet weak var col2HeaderLabel: UILabel!
    @IBOutlet weak var col3HeaderLabel: UILabel!
    @IBOutlet weak var firstSeparatorView: UIView!
    
    var analyticsSource: AnalyticsOutageSource!
    var viewModel: UnauthenticatedOutageViewModel! // Passed from UnauthenticatedOutageValidateAccountViewController
    
    var singleMultipremiseAccount = false

    override func viewDidLoad() {
        super.viewDidLoad()
    
        if viewModel.outageStatusArray!.count == viewModel.outageStatusArray!.filter({ $0.multipremiseAccount }).count {
            singleMultipremiseAccount = true
        }
        
        title = singleMultipremiseAccount ? NSLocalizedString("Select an Address", comment: "") : NSLocalizedString("Select an Account", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        navigationItem.leftBarButtonItem = cancelButton
        
        instructionLabel.textColor = .blackText
        instructionLabel.text = singleMultipremiseAccount ? NSLocalizedString("Please select your address:", comment: "") : NSLocalizedString("Please select your account:", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        col1HeaderLabel.textColor = .middleGray
        col1HeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        col1HeaderLabel.text = NSLocalizedString("Account Number", comment: "")
        if singleMultipremiseAccount {
            col1HeaderLabel.text = nil
        }
        
        col2HeaderLabel.textColor = .middleGray
        col2HeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        col2HeaderLabel.text = singleMultipremiseAccount ? NSLocalizedString("Street Address", comment: "") : NSLocalizedString("Street Number", comment: "")
        
        col3HeaderLabel.textColor = .middleGray
        col3HeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        col3HeaderLabel.text = NSLocalizedString("Unit Number", comment: "")
        
        firstSeparatorView.backgroundColor = tableView.separatorColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.reportedOutage = nil // Clear reported outage when user leaves UnauthenticatedOutageStatusViewController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO: Discovered an iOS 11 only bug where the table view cells would initially
        // be blank until they were scrolled off screen and reused. This reloadData() is the
        // workaround. We should remove it if/when this gets fixed.
        if #available(iOS 11, *) {
            viewDidLayoutSubviews()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData() // To properly set the width constraints
        
        // Dynamic sizing for the table header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }

            tableView.tableHeaderView = tableView.tableHeaderView;
        }

        
    
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UnauthenticatedOutageStatusViewController {
            vc.viewModel = viewModel
            vc.analyticsSource = analyticsSource
            
            switch analyticsSource {
            case .Report:
                Analytics().logScreenView(AnalyticsPageView.ReportAnOutageUnAuthSubmitAcctSelection.rawValue)
            case .Status:
                Analytics().logScreenView(AnalyticsPageView.OutageStatusUnAuthAcctSelect.rawValue)
            default:
                break
            }
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

        var a11yLabel = ""
        if singleMultipremiseAccount {
            if cell.accountNumberLabel != nil { // Prevents crash if already removed
                cell.accountNumberLabel.removeFromSuperview()
            }
            cell.streetNumberLabel.text = outageStatus.maskedAddress
            cell.unitNumberLabel.text = outageStatus.unitNumber
            
            if let maskedAddress = outageStatus.maskedAddress, !maskedAddress.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Street address: %@,", comment: ""), maskedAddress)
            }
            if let unitNumber = outageStatus.unitNumber, !unitNumber.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Unit number: %@", comment: ""), unitNumber)
            }
        } else {
            cell.accountNumberLabel.text = outageStatus.maskedAccountNumber
            cell.streetNumberLabel.text = outageStatus.addressNumber
            cell.unitNumberLabel.text = outageStatus.unitNumber
            
            cell.accountNumberLabelWidthConstraint.constant = col1HeaderLabel.frame.size.width
            
            if let accountNumber = outageStatus.maskedAccountNumber, !accountNumber.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Account number ending in %@,", comment: ""), accountNumber.replacingOccurrences(of: "*", with: ""))
            }
            if let addressNumber = outageStatus.addressNumber, !addressNumber.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Street number: %@,", comment: ""), addressNumber)
            }
            if let unitNumber = outageStatus.unitNumber, !unitNumber.isEmpty {
                a11yLabel += String(format: NSLocalizedString("Unit number: %@", comment: ""), unitNumber)
            }
        }
        
        cell.streetNumberLabelWidthConstraint.constant = col2HeaderLabel.frame.size.width
        cell.unitNumberLabelWidthConstraint.constant = col3HeaderLabel.frame.size.width
        cell.accessibilityLabel = a11yLabel
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOutageStatus = viewModel.outageStatusArray![indexPath.row]
        if selectedOutageStatus.multipremiseAccount {
            // No need to query again for a multipremise account because it would just return us an array of the status info we already have
            if selectedOutageStatus.flagGasOnly {
                let alertVc = UIAlertController(title: NSLocalizedString("Outage status unavailable", comment: ""), message: NSLocalizedString("This account receives gas service only. We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo report a gas emergency or a downed or sparking power line, please call 1-800-685-0123.", comment: ""), preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default, handler: { _ in
                    if let url = URL(string: "tel://1-800-685-0123"), UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }))
                self.present(alertVc, animated: true, completion: nil)
            } else {
                viewModel.selectedOutageStatus = selectedOutageStatus
                self.performSegue(withIdentifier: "outageStatusSegue", sender: self)
            }
        } else if let accountNumber = selectedOutageStatus.accountNumber {
            LoadingView.show()
            viewModel.fetchOutageStatus(overrideAccountNumber: accountNumber, onSuccess: { [weak self] in
                guard let `self` = self else { return }
                LoadingView.hide()
                if self.viewModel.selectedOutageStatus != nil {
                    self.performSegue(withIdentifier: "outageStatusSegue", sender: self)
                }
            }, onError: { [weak self] errTitle, errMessage in
                guard let `self` = self else { return }
                LoadingView.hide()
                
                let alertVc = UIAlertController(title: errTitle, message: errMessage, preferredStyle: .alert)
                
                if errTitle == NSLocalizedString("Cut for non pay", comment: "") {
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Pay Bill", comment: ""), style: .default, handler: { [weak self] _ in
                        let storyboard = UIStoryboard(name: "Login", bundle: nil)
                        let landingVC = storyboard.instantiateViewController(withIdentifier: "landingViewController")
                        let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController")
                        self?.navigationController?.setViewControllers([landingVC, loginVC], animated: false)
                    }))
                } else if let phoneRange = errMessage.range(of:"1-\\d{3}-\\d{3}-\\d{4}", options: .regularExpression) {
                    // use regular expression to check the US phone number format: start with 1, then -, then 3 3 4 digits grouped together that separated by dash
                    // e.g: 1-111-111-1111 is valid while 1-1111111111 and 111-111-1111 are not
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default, handler: { _ in
                        if let url = URL(string: "tel://\(errMessage.substring(with: phoneRange))"), UIApplication.shared.canOpenURL(url) {
                            if #available(iOS 10, *) {
                                UIApplication.shared.open(url)
                            } else {
                                UIApplication.shared.openURL(url)
                            }
                        }
                    }))
                } else {
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                }
                
                self.present(alertVc, animated: true, completion: nil)
            })
        }
    }
}

