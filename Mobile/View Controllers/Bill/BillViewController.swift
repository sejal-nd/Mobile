//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import Lottie

class BillViewController: AccountPickerViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var topLoadingIndicatorView: UIView!
    @IBOutlet weak var topLoadingIndicator: LoadingIndicator!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
	@IBOutlet weak var bottomStackContainerView: UIView!
    
    @IBOutlet weak var alertBannerView: UIView!
    @IBOutlet weak var alertBannerIconView: UIView!
    @IBOutlet weak var alertAnimationView: UIView!
    @IBOutlet weak var alertBannerLabel: UILabel!
    
    @IBOutlet weak var totalAmountView: UIView!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var totalAmountDescriptionLabel: UILabel!
    @IBOutlet weak var questionMarkButton: UIButton!
    
	@IBOutlet weak var paymentDetailsView: UIView!
	@IBOutlet weak var paymentStackView: UIStackView!
	@IBOutlet weak var youAreEntitledLabel: UILabel!
	@IBOutlet weak var catchUpDisclaimerView: UIView!
    @IBOutlet weak var needHelpUnderstandingButton: ButtonControl!
	@IBOutlet weak var viewBillButton: ButtonControl!
	
	@IBOutlet weak var loadingIndicatorView: UIView!
	@IBOutlet weak var billLoadingIndicator: LoadingIndicator!
	
    @IBOutlet weak var makeAPaymentButton: PrimaryButton!
    @IBOutlet weak var makeAPaymentStatusLabel: UILabel!
    
    @IBOutlet weak var autoPayButton: ButtonControl!
    @IBOutlet weak var paperlessButton: ButtonControl!
    @IBOutlet weak var budgetButton: ButtonControl!
    @IBOutlet weak var autoPayEnrollmentLabel: UILabel!
    @IBOutlet weak var paperlessEnrollmentLabel: UILabel!
	@IBOutlet weak var budgetBillingEnrollmentLabel: UILabel!
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl? {
        didSet {
            refreshDisposable?.dispose()
            refreshDisposable = refreshControl?.rx.controlEvent(.valueChanged).asObservable()
				.map { FetchingAccountState.refresh }
				.bind(to: viewModel.fetchAccountDetail)
        }
    }
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")!
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        accountPickerViewControllerWillAppear.subscribe(onNext: {
            if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                self.viewModel.fetchAccountDetail(isRefresh: false)
            } else if self.viewModel.currentAccountDetail.value == nil {
                self.viewModel.fetchAccountDetail(isRefresh: false)
            }
        }).addDisposableTo(disposeBag)
        
        styleViews()
        bindViews()
        bindButtonTaps()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        alertLottieAnimation.frame = CGRect(x: 0, y: 0, width: alertAnimationView.frame.size.width, height: alertAnimationView.frame.size.height)
        alertLottieAnimation.contentMode = .scaleAspectFill
        alertAnimationView.addSubview(alertLottieAnimation)
    }
    
    func styleViews() {
        
        view.backgroundColor = .primaryColor
        contentView.backgroundColor = .primaryColor
        
        scrollView.rx.contentOffset.asDriver()
            .map { $0.y < 0 ? UIColor.primaryColor: UIColor.white }
			.distinctUntilChanged()
            .drive(onNext: { self.scrollView.backgroundColor = $0 })
            .addDisposableTo(disposeBag)
        
        topView.backgroundColor = .primaryColor
        bottomView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -3), radius: 2)
        
        alertBannerIconView.superview?.bringSubview(toFront: alertBannerIconView)
        alertBannerIconView.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        
        totalAmountView.superview?.bringSubview(toFront: totalAmountView)
        totalAmountView.addShadow(color: .black, opacity: 0.05, offset: CGSize(width: 0, height: 1), radius: 1)
        
        needHelpUnderstandingButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 1.5)
        
        autoPayButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        autoPayButton.layer.cornerRadius = 2
        autoPayButton.layer.masksToBounds = false
        
        paperlessButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        paperlessButton.layer.cornerRadius = 2
        paperlessButton.layer.masksToBounds = false
        
        budgetButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        budgetButton.layer.cornerRadius = 2
        budgetButton.layer.masksToBounds = false
    }
    
    func bindViews() {
		bindLoadingStates()
		bindViewHiding()
		bindViewContent()
    }
	
	func bindLoadingStates() {
        topLoadingIndicatorView.isHidden = true
		viewModel.isFetchingAccountDetail.filter(!).drive(rx.isRefreshing).addDisposableTo(disposeBag)
		
		viewModel.isFetchingDifferentAccount.map(!).drive(rx.isPullToRefreshEnabled).addDisposableTo(disposeBag)
        viewModel.isFetchingDifferentAccount.drive(billLoadingIndicator.rx.isAnimating).addDisposableTo(disposeBag)
        
        viewModel.isFetchingDifferentAccount.map(!).drive(loadingIndicatorView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFetchingDifferentAccount.drive(totalAmountView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFetchingDifferentAccount.drive(paymentDetailsView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFetchingDifferentAccount.drive(bottomStackContainerView.rx.isHidden).addDisposableTo(disposeBag)
	}
	
	func bindViewHiding() {
        viewModel.alertBannerText.map { $0 == nil }.drive(alertBannerView.rx.isHidden).addDisposableTo(disposeBag)
		
		questionMarkButton.isHidden = viewModel.shouldHideAmountDueTooltip
        
        viewModel.shouldShowCatchUpAmount.map(!).drive(catchUpDisclaimerView.rx.isHidden).addDisposableTo(disposeBag)
        
        viewModel.paymentStatusText.map { $0 == nil }.drive(makeAPaymentStatusLabel.rx.isHidden).addDisposableTo(disposeBag)
		
		viewModel.shouldHideAutoPay.drive(autoPayButton.rx.isHidden).addDisposableTo(disposeBag)
		viewModel.shouldHidePaperless.drive(paperlessButton.rx.isHidden).addDisposableTo(disposeBag)
		viewModel.shouldHideBudget.drive(budgetButton.rx.isHidden).addDisposableTo(disposeBag)
	}
	
	func bindViewContent() {
		viewModel.alertBannerText.filter { $0 != nil }
			.drive(onNext: { _ in
				self.alertLottieAnimation.play()
			})
			.addDisposableTo(disposeBag)
        
        viewModel.alertBannerText.drive(alertBannerLabel.rx.text).addDisposableTo(disposeBag)
		
		viewModel.totalAmountText.drive(totalAmountLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.totalAmountDescriptionText.drive(totalAmountDescriptionLabel.rx.text).addDisposableTo(disposeBag)
        
        viewModel.catchUpDisclaimerText.drive(youAreEntitledLabel.rx.text).addDisposableTo(disposeBag)
        
        viewModel.paymentStatusText.drive(makeAPaymentStatusLabel.rx.text).addDisposableTo(disposeBag)
		
		viewModel.autoPayButtonText.drive(autoPayEnrollmentLabel.rx.attributedText).addDisposableTo(disposeBag)
		viewModel.paperlessButtonText.drive(paperlessEnrollmentLabel.rx.attributedText).addDisposableTo(disposeBag)
		viewModel.budgetButtonText.drive(budgetBillingEnrollmentLabel.rx.attributedText).addDisposableTo(disposeBag)
	}
	
    func bindButtonTaps() {
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
                self.performSegue(withIdentifier: "viewBillSegue", sender: self)
            })
			.addDisposableTo(disposeBag)
		
		autoPayButton.rx.touchUpInside.asDriver()
			.withLatestFrom(viewModel.currentAccountDetailUnwrapped)
			.drive(onNext: { accountDetail in
				if Environment.sharedInstance.opco == .bge && accountDetail.isBGEasy {
					self.performSegue(withIdentifier: "viewBGEasySegue", sender: self)
				}
			})
			.addDisposableTo(disposeBag)
		
		paperlessButton.rx.touchUpInside.asDriver()
			.withLatestFrom(viewModel.currentAccountDetailUnwrapped)
			.drive(onNext: { accountDetail in
				if UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) {
					self.performSegue(withIdentifier: "paperlessEBillCommercialSegue", sender: self)
				} else {
					self.performSegue(withIdentifier: "paperlessEBillSegue", sender: self)
				}
			})
			.addDisposableTo(disposeBag)
		
        budgetButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetailUnwrapped)
            .drive(onNext: { accountDetail in
                if accountDetail.isBudgetBillEligible {
                    self.performSegue(withIdentifier: "budgetBillingSegue", sender: self)
                } else {
                    let alertVC = UIAlertController(title: NSLocalizedString("Ineligible for Budget Billing", comment: ""), message: NSLocalizedString("Sorry, you are ineligible for Budget Billing", comment: ""), preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? BudgetBillingViewController {
            vc.delegate = self
            vc.accountDetail = viewModel.currentAccountDetail.value!
        } else if let vc = segue.destination as? PaperlessEBillViewController {
            vc.delegate = self
            vc.initialAccountDetail = viewModel.currentAccountDetail.value!
        } else if let vc = segue.destination as? ViewBillViewController {
            vc.viewModel.billDate = viewModel.currentAccountDetail.value!.billingInfo.billDate
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
        viewModel.fetchAccountDetail(isRefresh: false)
    }
    
}

extension BillViewController: BudgetBillingViewControllerDelegate {
    
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController) {
        viewModel.fetchAccountDetail(isRefresh: false)
        showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
    }
    
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController) {
        viewModel.fetchAccountDetail(isRefresh: false)
        showDelayedToast(withMessage: NSLocalizedString("Unenrolled from Budget Billing", comment: ""))
    }
}

extension BillViewController: PaperlessEBillViewControllerDelegate {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus) {
        viewModel.fetchAccountDetail(isRefresh: false)
        var toastMessage: String
        switch didChangeStatus {
        case .Enroll:
            toastMessage = NSLocalizedString("Enrolled in Paperless eBill", comment: "")
        case .Unenroll:
            toastMessage = NSLocalizedString("Unenrolled from Paperless eBill", comment: "")
        case .Mixed:
            toastMessage = NSLocalizedString("Paperless eBill changes saved", comment: "")
        }
        showDelayedToast(withMessage: toastMessage)
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

