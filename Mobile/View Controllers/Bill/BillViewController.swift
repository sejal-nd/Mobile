//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountScroller: AccountScroller!
    @IBOutlet weak var accountScrollerActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var paperlessButtonView: UIView!
    @IBOutlet weak var budgetButtonView: UIView!
    @IBOutlet weak var paperlessEnrollmentLabel: UILabel!
    @IBOutlet weak var budgetBillingEnrollmentLabel: UILabel!
    @IBOutlet weak var billActivityIndicator: UIActivityIndicatorView!
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Bill", comment: "")
        
        accountScroller.delegate = self
        accountScroller.parentViewController = self
        accountScroller.isHidden = true
        
        accountScrollerActivityIndicator.color = .mediumPersianBlue
        billActivityIndicator.color = .mediumPersianBlue
        
        paperlessButtonView.layer.cornerRadius = 2
        paperlessButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        paperlessButtonView.layer.shadowOpacity = 0.3
        paperlessButtonView.layer.shadowColor = UIColor.black.cgColor
        paperlessButtonView.layer.shadowRadius = 3
        paperlessButtonView.layer.masksToBounds = false
        paperlessButtonView.isHidden = true
        
        budgetButtonView.layer.cornerRadius = 2
        budgetButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        budgetButtonView.layer.shadowOpacity = 0.2
        budgetButtonView.layer.shadowColor = UIColor.black.cgColor
        budgetButtonView.layer.shadowRadius = 3
        budgetButtonView.layer.masksToBounds = false
        budgetButtonView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = .mediumPersianBlue
    
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.darkJungleGreen,
            NSFontAttributeName: OpenSans.bold.ofSize(18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        if viewModel.currentAccount == nil {
            getAccounts()
        }
    }
    
    func getAccounts() {
        accountScrollerActivityIndicator.isHidden = false
        viewModel.getAccounts(onSuccess: { accounts in
            self.accountScrollerActivityIndicator.isHidden = true
            self.accountScroller.setAccounts(accounts)
            self.accountScroller.isHidden = false
            self.getAccountDetails()
        }, onError: { message in
            self.accountScrollerActivityIndicator.isHidden = true
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    func getAccountDetails() {
        self.paperlessButtonView.isHidden = true
        self.budgetButtonView.isHidden = true
        self.billActivityIndicator.isHidden = false
        
        viewModel.getAccountDetails(onSuccess: {
            self.billActivityIndicator.isHidden = true
            
            self.paperlessButtonView.isHidden = self.viewModel.currentAccountDetail!.isEBillEligible == false
            self.budgetButtonView.isHidden = self.viewModel.currentAccountDetail!.isBudgetBillEligible == false && Environment.sharedInstance.opco != .bge
            
            if self.viewModel.currentAccountDetail!.isEBillEnrollment {
                self.paperlessEnrollmentLabel.text = "enrolled"
                self.paperlessEnrollmentLabel.textColor = .successGreenText
            } else {
                self.paperlessEnrollmentLabel.text = "not enrolled"
                self.paperlessEnrollmentLabel.textColor = .outerSpace
            }
            
            if self.viewModel.currentAccountDetail!.isBudgetBillEnrollment {
                self.budgetBillingEnrollmentLabel.text = "enrolled"
                self.budgetBillingEnrollmentLabel.textColor = .successGreenText
            } else {
                self.budgetBillingEnrollmentLabel.text = "not enrolled"
                self.budgetBillingEnrollmentLabel.textColor = .outerSpace
            }
            
        }, onError: { errorMessage in
            dLog(message: errorMessage)
        })
    }
    
    @IBAction func onButtonTouchDown(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .whiteButtonHighlight
    }
    
    @IBAction func onButtonTouchCancel(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .white
    }
    
    @IBAction func onBudgetBillingButtonPress() {
        if self.viewModel.currentAccountDetail!.isBudgetBillEligible {
            performSegue(withIdentifier: "budgetBillingSegue", sender: self)
        } else {
            let alertVC = UIAlertController(title: NSLocalizedString("Budget Billing", comment: ""), message: NSLocalizedString("Sorry, you are ineligible for Budget Billing", comment: ""), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alertVC, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? BudgetBillingViewController {
            vc.delegate = self
            vc.initialEnrollment = viewModel.currentAccountDetail!.isBudgetBillEnrollment
        } else if let vc = segue.destination as? PaperlessEBillViewController {
            vc.delegate = self
            vc.accounts = accountScroller.accounts
            vc.initialAccountDetail = viewModel.currentAccountDetail!
        }
    }
    
    func showDelayedToast(withMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.makeToast(message, duration: 3.5, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
        })
    }
}

extension BillViewController: AccountScrollerDelegate {
    
    func accountScroller(_ accountScroller: AccountScroller, didChangeAccount account: Account) {
        viewModel.currentAccount = account
        accountScroller.updateAdvancedPicker(account: account)
        getAccountDetails()
    }
    
}

extension BillViewController: BudgetBillingViewControllerDelegate {
    
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController) {
        showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
    }
    
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController) {
        showDelayedToast(withMessage: NSLocalizedString("Unenrolled from Budget Billing", comment: ""))
    }
}

extension BillViewController: PaperlessEBillViewControllerDelegate {
    
    func paperlessEBillViewControllerDidEnroll(_ paperlessEBillViewController: PaperlessEBillViewController) {
        let message: String
        switch Environment.sharedInstance.opco {
        case .bge:
            message = NSLocalizedString("Enrolled in Paperless eBill.", comment: "")
        case .peco, .comEd:
            message = NSLocalizedString("Paperless eBill changes saved.", comment: "")
        }
        showDelayedToast(withMessage: message)
    }
    
    func paperlessEBillViewControllerDidUnenroll(_ paperlessEBillViewController: PaperlessEBillViewController) {
        let message: String
        switch Environment.sharedInstance.opco {
        case .bge:
            message = NSLocalizedString("Unenrolled from Paperless eBill.", comment: "")
        case .peco, .comEd:
            message = NSLocalizedString("Paperless eBill changes saved.", comment: "")
        }
        showDelayedToast(withMessage: message)
    }
    
    func paperlessEBillViewControllerDidChangeStatus(_ paperlessEBillViewController: PaperlessEBillViewController) {
        showDelayedToast(withMessage: NSLocalizedString("Paperless eBill changes saved.", comment: ""))
    }
}


