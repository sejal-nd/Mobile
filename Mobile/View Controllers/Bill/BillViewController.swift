//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BillViewController: AccountPickerViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var topWarningView: UIView!
    @IBOutlet weak var topWarningIconView: UIView!
    @IBOutlet weak var topWarningLabel: UILabel!
    
    @IBOutlet weak var totalAmountView: UIView!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var totalAmountDescriptionLabel: UILabel!
    @IBOutlet weak var questionMarkButton: UIButton!
    
    @IBOutlet weak var paymentStackView: UIStackView!
    @IBOutlet weak var youAreEntitledLabel: UILabel!
    @IBOutlet weak var needHelpUnderstandingButton: ButtonControl!
    @IBOutlet weak var viewBillButton: ButtonControl!
    
    @IBOutlet weak var makeAPaymentButton: PrimaryButton!
    
    @IBOutlet weak var autoPayButton: ButtonControl!
    @IBOutlet weak var paperlessButton: ButtonControl!
    @IBOutlet weak var budgetButton: ButtonControl!
    @IBOutlet weak var autoPayEnrollmentLabel: UILabel!
    @IBOutlet weak var paperlessEnrollmentLabel: UILabel!
    @IBOutlet weak var budgetBillingEnrollmentLabel: UILabel!
    @IBOutlet weak var billLoadingIndicator: LoadingIndicator!
    
    var refreshControl: UIRefreshControl?
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())
    
    override var defaultStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
        set { }
    }

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        view.backgroundColor = .primaryColor
        scrollView.rx.contentOffset.asDriver()
            .map { $0.y <= 0 ? UIColor.primaryColor: UIColor.white }
            .drive(onNext: { self.scrollView.backgroundColor = $0 })
            .addDisposableTo(disposeBag)
        
        topView.backgroundColor = .primaryColor
        bottomView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -3), radius: 2)
        
        topWarningIconView.superview?.bringSubview(toFront: topWarningIconView)
        topWarningIconView.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        
        totalAmountView.superview?.bringSubview(toFront: totalAmountView)
        totalAmountView.addShadow(color: .black, opacity: 0.05, offset: CGSize(width: 0, height: 1), radius: 1)
        
        paymentStackView.isHidden = true
        needHelpUnderstandingButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 1.5)
        
        autoPayButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        autoPayButton.layer.cornerRadius = 2
        autoPayButton.layer.masksToBounds = false
//        autoPayButton.isHidden = true
        
        paperlessButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        paperlessButton.layer.cornerRadius = 2
        paperlessButton.layer.masksToBounds = false
        paperlessButton.isHidden = true
        
        budgetButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        budgetButton.layer.cornerRadius = 2
        budgetButton.layer.masksToBounds = false
        budgetButton.isHidden = true
        
        accountPickerViewControllerWillAppear.subscribe(onNext: {
            if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                self.getAccountDetails()
            } else if self.viewModel.currentAccountDetail == nil {
                self.getAccountDetails()
            }
        }).addDisposableTo(disposeBag)
        
        questionMarkButton.rx.tap.asDriver()
            .drive(onNext: {
                let alertController = UIAlertController(title: NSLocalizedString("Your Due Date", comment: ""),
                                                        message: NSLocalizedString("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.", comment: ""), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            })
            .addDisposableTo(disposeBag)
        
        needHelpUnderstandingButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                print("need help tapped")
            })
            .addDisposableTo(disposeBag)
        
        viewBillButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                print("view bill tapped")
            })
            .addDisposableTo(disposeBag)
        
        paperlessButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                if UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) {
                    self.performSegue(withIdentifier: "paperlessEBillCommercialSegue", sender: self)
                } else {
                    self.performSegue(withIdentifier: "paperlessEBillSegue", sender: self)
                }
            })
            .addDisposableTo(disposeBag)
        
        budgetButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                if self.viewModel.currentAccountDetail!.isBudgetBillEligible {
                    self.performSegue(withIdentifier: "budgetBillingSegue", sender: self)
                } else {
                    let alertVC = UIAlertController(title: NSLocalizedString("Budget Billing", comment: ""), message: NSLocalizedString("Sorry, you are ineligible for Budget Billing", comment: ""), preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl?.tintColor = .white
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
        paperlessButton.isHidden = true
        budgetButton.isHidden = true
        billLoadingIndicator.isHidden = false
        setRefreshControlEnabled(enabled: false)
        viewModel.getAccountDetails(onSuccess: {
            self.billLoadingIndicator.isHidden = true
            self.setRefreshControlEnabled(enabled: true)
            self.updateContent()
        }, onError: { errorMessage in
            self.billLoadingIndicator.isHidden = true
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
        paperlessButton.isHidden = viewModel.currentAccountDetail!.isEBillEligible == false
        budgetButton.isHidden = viewModel.currentAccountDetail!.isBudgetBillEligible == false && Environment.sharedInstance.opco != .bge
        
        if viewModel.currentAccountDetail!.isEBillEnrollment {
            paperlessEnrollmentLabel.text = "enrolled"
            paperlessEnrollmentLabel.textColor = .successGreenText
        } else {
            paperlessEnrollmentLabel.text = "not enrolled"
            paperlessEnrollmentLabel.textColor = .deepGray
        }
        
        if viewModel.currentAccountDetail!.isBudgetBillEnrollment {
            budgetBillingEnrollmentLabel.text = "enrolled"
            budgetBillingEnrollmentLabel.textColor = .successGreenText
        } else {
            budgetBillingEnrollmentLabel.text = "not enrolled"
            budgetBillingEnrollmentLabel.textColor = .deepGray
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
            self.view.makeToast(message, duration: 5.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
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


