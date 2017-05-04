//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BillViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var paperlessButtonView: UIView!
    @IBOutlet weak var budgetButtonView: UIView!
    @IBOutlet weak var paperlessEnrollmentLabel: UILabel!
    @IBOutlet weak var budgetBillingEnrollmentLabel: UILabel!
    @IBOutlet weak var billActivityIndicator: UIActivityIndicatorView!
    
    var refreshControl: UIRefreshControl?
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Bill", comment: "")
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self

        billActivityIndicator.color = .mediumPersianBlue
        
        paperlessButtonView.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        paperlessButtonView.layer.cornerRadius = 2
        paperlessButtonView.layer.masksToBounds = false
        paperlessButtonView.isHidden = true
        
        budgetButtonView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        budgetButtonView.layer.cornerRadius = 2
        budgetButtonView.layer.masksToBounds = false
        budgetButtonView.isHidden = true
        
        accountPickerViewControllerWillAppear.subscribe(onNext: {
            if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                self.getAccountDetails()
            } else if self.viewModel.currentAccountDetail == nil {
                self.getAccountDetails()
            }
        }).addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            scrollView.insertSubview(refreshControl!, at: 0)
            scrollView.alwaysBounceVertical = true
        } else {
            if let rc = refreshControl {
                rc.endRefreshing()
                rc.removeFromSuperview()
                refreshControl = nil
            }
            scrollView.alwaysBounceVertical = false
        }
    }
    
    func getAccountDetails() {
        paperlessButtonView.isHidden = true
        budgetButtonView.isHidden = true
        billActivityIndicator.isHidden = false
        setRefreshControlEnabled(enabled: false)
        viewModel.getAccountDetails(onSuccess: {
            self.billActivityIndicator.isHidden = true
            self.setRefreshControlEnabled(enabled: true)
            self.updateContent()
        }, onError: { errorMessage in
            self.billActivityIndicator.isHidden = true
            self.setRefreshControlEnabled(enabled: true)
            dLog(message: errorMessage)
        })
    }
    
    func onPullToRefresh() {
        viewModel.getAccountDetails(onSuccess: {
            self.refreshControl?.endRefreshing()
            self.updateContent()
        }, onError: { errorMessage in
            self.refreshControl?.endRefreshing()
            dLog(message: errorMessage)
        })
    }
    
    func updateContent() {
        paperlessButtonView.isHidden = viewModel.currentAccountDetail!.isEBillEligible == false
        budgetButtonView.isHidden = viewModel.currentAccountDetail!.isBudgetBillEligible == false && Environment.sharedInstance.opco != .bge
        
        if viewModel.currentAccountDetail!.isEBillEnrollment {
            paperlessEnrollmentLabel.text = "enrolled"
            paperlessEnrollmentLabel.textColor = .successGreenText
        } else {
            paperlessEnrollmentLabel.text = "not enrolled"
            paperlessEnrollmentLabel.textColor = .outerSpace
        }
        
        if viewModel.currentAccountDetail!.isBudgetBillEnrollment {
            budgetBillingEnrollmentLabel.text = "enrolled"
            budgetBillingEnrollmentLabel.textColor = .successGreenText
        } else {
            budgetBillingEnrollmentLabel.text = "not enrolled"
            budgetBillingEnrollmentLabel.textColor = .outerSpace
        }
    }
    
    @IBAction func onButtonTouchDown(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .whiteButtonHighlight
    }
    
    @IBAction func onButtonTouchCancel(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .white
    }
    
    @IBAction func onPaperlessEBillPress(_ sender: Any) {
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) {
            performSegue(withIdentifier: "paperlessEBillCommercialSegue", sender: self)
        } else {
            performSegue(withIdentifier: "paperlessEBillSegue", sender: self)
        }
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
            vc.initialAccountDetail = viewModel.currentAccountDetail!
        }
    }
    
    func showDelayedToast(withMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.makeToast(message, duration: 3.5, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
        })
    }
}

extension BillViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        getAccountDetails()
    }
    
}

extension BillViewController: BudgetBillingViewControllerDelegate {
    
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController) {
        getAccountDetails()
        showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
    }
    
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController) {
        getAccountDetails()
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


