//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

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
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl? {
        didSet {
            refreshDisposable?.dispose()
            refreshDisposable = refreshControl?.rx.controlEvent(.valueChanged).asDriver()
                .drive(viewModel.fetchAccountDetailSubject)
        }
    }
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())
    
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
                self.viewModel.fetchAccountDetail()
            } else if self.viewModel.currentAccountDetail.value == nil {
                self.viewModel.fetchAccountDetail()
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
                if self.viewModel.currentAccountDetail.value!.isBudgetBillEligible {
                    self.performSegue(withIdentifier: "budgetBillingSegue", sender: self)
                } else {
                    let alertVC = UIAlertController(title: NSLocalizedString("Budget Billing", comment: ""), message: NSLocalizedString("Sorry, you are ineligible for Budget Billing", comment: ""), preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                }
            })
            .addDisposableTo(disposeBag)
        
        viewModel.fetchingAccountDetail
            .drive(billLoadingIndicator.rx.isAnimating)
            .addDisposableTo(disposeBag)
        
        viewModel.fetchingAccountDetail.asDriver()
            .filter { !$0 && self.refreshControl?.isRefreshing ?? false }
            .drive(rx.isRefreshing)
            .addDisposableTo(disposeBag)
        
        viewModel.fetchingAccountDetail.asDriver()
            .filter { !$0 || ($0 && !(self.refreshControl?.isRefreshing ?? false)) }
            .map(!)
            .distinctUntilChanged()
            .drive(rx.isPullToRefreshEnabled)
            .addDisposableTo(disposeBag)
        
        viewModel.fetchingAccountDetail
            .filter(!)
            .drive(onNext: { _ in
                self.refreshControl?.endRefreshing()
            })
            .addDisposableTo(disposeBag)
        
        viewModel.currentAccountDetail.asDriver()
            .drive(onNext: {
                if let accountDetail = $0 {
                    self.updateContent(with: accountDetail)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func updateContent(with accountDetail: AccountDetail) {
        paperlessButton.isHidden = accountDetail.isEBillEligible == false
        budgetButton.isHidden = accountDetail.isBudgetBillEligible == false && Environment.sharedInstance.opco != .bge
        
        if accountDetail.isEBillEnrollment {
            paperlessEnrollmentLabel.text = "enrolled"
            paperlessEnrollmentLabel.textColor = .successGreenText
        } else {
            paperlessEnrollmentLabel.text = "not enrolled"
            paperlessEnrollmentLabel.textColor = .deepGray
        }
        
        if accountDetail.isBudgetBillEnrollment {
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
            vc.initialEnrollment = viewModel.currentAccountDetail.value!.isBudgetBillEnrollment
        } else if let vc = segue.destination as? PaperlessEBillViewController {
            vc.delegate = self
            vc.initialAccountDetail = viewModel.currentAccountDetail.value!
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
        viewModel.fetchAccountDetail()
    }
    
}

extension BillViewController: BudgetBillingViewControllerDelegate {
    
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController) {
        viewModel.fetchAccountDetail()
        showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
    }
    
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController) {
        viewModel.fetchAccountDetail()
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

extension Reactive where Base: BillViewController {
    
    var isPullToRefreshEnabled: UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: self.base) { vc, refresh in
            if refresh {
                guard vc.refreshControl == nil else { return }
                let refreshControl = UIRefreshControl()
                vc.refreshControl = refreshControl
                refreshControl.tintColor = .white
                vc.scrollView.insertSubview(refreshControl, at: 0)
                vc.scrollView.alwaysBounceVertical = true
            } else {
                vc.refreshControl?.endRefreshing()
                vc.refreshControl?.removeFromSuperview()
                vc.refreshControl = nil
                vc.scrollView.alwaysBounceVertical = false
            }
        }
    }
    
    var isRefreshing: UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: self.base) { vc, refresh in
            if refresh {
                vc.refreshControl?.beginRefreshing()
            } else {
                vc.refreshControl?.endRefreshing()
            }
        }
    }
    
}

