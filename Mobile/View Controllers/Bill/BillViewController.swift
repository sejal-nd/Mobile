//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import Lottie
import StoreKit

class BillViewController: AccountPickerViewController {
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet weak var maintenanceModeView: MaintenanceModeView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
	@IBOutlet weak var bottomStackContainerView: UIView!
    
    @IBOutlet weak var prepaidBannerButton: ButtonControl!
    @IBOutlet weak var prepaidHeaderLabel: UILabel!
    @IBOutlet weak var prepaidDetailLabel: UILabel!
    
    @IBOutlet weak var alertBannerView: BillAlertBannerView!
    
    @IBOutlet weak var totalAmountView: UIView!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var totalAmountDescriptionLabel: UILabel!
    @IBOutlet weak var questionMarkButton: UIButton!

	@IBOutlet weak var paymentDetailsView: UIView!

	// Catch Up Disclaimer
	@IBOutlet weak var catchUpDisclaimerView: UIView!
	@IBOutlet weak var catchUpDisclaimerLabel: UILabel!
    
	// Past Due
    @IBOutlet weak var pastDueView: UIView!
    @IBOutlet weak var pastDueLabel: UILabel!
    @IBOutlet weak var pastDueAmountLabel: UILabel!
    @IBOutlet weak var pastDueDateLabel: UILabel!
    
    // Current Bill
    @IBOutlet weak var currentBillView: UIView!
    @IBOutlet weak var currentBillLabel: UILabel!
    @IBOutlet weak var currentBillAmountLabel: UILabel!
    @IBOutlet weak var currentBillDateLabel: UILabel!
    
    // Payment Received
    @IBOutlet weak var paymentReceivedView: UIView!
    @IBOutlet weak var paymentReceivedLabel: UILabel!
    @IBOutlet weak var paymentReceivedAmountLabel: UILabel!
    @IBOutlet weak var paymentReceivedDateLabel: UILabel!

	// Payments
	@IBOutlet weak var pendingPaymentView: UIView!
    @IBOutlet weak var pendingPaymentLabel: UILabel!
    @IBOutlet weak var pendingPaymentAmountLabel: UILabel!

	// Remaining Balance Due
	@IBOutlet weak var remainingBalanceDueView: UIView!
	@IBOutlet weak var remainingBalanceDueLabel: UILabel!
	@IBOutlet weak var remainingBalanceDueAmountLabel: UILabel!

    @IBOutlet weak var billBreakdownButton: ButtonControl!
    @IBOutlet weak var billBreakdownImageView: UIImageView!
    @IBOutlet weak var billBreakdownLabel: UILabel!
    @IBOutlet weak var viewBillButton: ButtonControl!
    @IBOutlet weak var viewBillLabel: UILabel!

	@IBOutlet weak var loadingIndicatorView: UIView!
	@IBOutlet weak var billLoadingIndicator: LoadingIndicator!

    @IBOutlet weak var makeAPaymentButton: PrimaryButton!
	@IBOutlet weak var billPaidView: UIView!
    @IBOutlet weak var billPaidLabel: UILabel!
    @IBOutlet weak var makeAPaymentStatusLabel: UILabel!
    @IBOutlet weak var makeAPaymentStatusButton: ButtonControl!

    @IBOutlet weak var activityButton: DisclosureButton!
    @IBOutlet weak var walletButton: DisclosureButton!

    @IBOutlet weak var autoPayButton: ButtonControl!
    @IBOutlet weak var paperlessButton: ButtonControl!
    @IBOutlet weak var budgetButton: ButtonControl!
    @IBOutlet weak var autoPayEnrollmentLabel: UILabel!
    @IBOutlet weak var paperlessEnrollmentLabel: UILabel!
	@IBOutlet weak var budgetBillingEnrollmentLabel: UILabel!

    @IBOutlet weak var prepaidView: UIView!
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var genericErrorView: UIView!
    @IBOutlet weak var genericErrorLabel: UILabel!
    @IBOutlet weak var accountDisallowView: UIView!
    
    private let cornerRadius: CGFloat = 4.0
    
    var refreshControl: UIRefreshControl?
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService(),
                                  authService: ServiceFactory.createAuthenticationService())

    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    var shortcutItem = ShortcutItem.none

    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        styleViews()
        bindViews()
        bindButtonTaps()
        configureAccessibility()
        
        NotificationCenter.default.rx.notification(.didMaintenanceModeTurnOn)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.refreshControl?.endRefreshing()
                self?.scrollView!.alwaysBounceVertical = true
            })
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(.didSelectEnrollInAutoPay, object: nil)
        .subscribe(onNext: { [weak self] notification in
            guard let self = self else { return }
            if let accountDetail = notification.object as? AccountDetail {
                self.navigateToAutoPay(accountDetail: accountDetail)
            }
        }).disposed(by: bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 10.3, *) , AppRating.shouldRequestRating() {
            SKStoreReviewController.requestReview()
        }
        
        // Bug was found when initially loading the Bill tab with no network. You could pull the scrollView down
        // to begin the refresh process, but would not be able to pull it down all the way to trigger the refresh.
        refreshControl?.removeFromSuperview()
        refreshControl = nil
        scrollView!.alwaysBounceVertical = false
        
        // only enable refresh if the accounts list has loaded
        if !(accountPicker.accounts ?? []).isEmpty {
            enableRefresh()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shortcutItem = .none
    }
    
    func enableRefresh() -> Void {
        guard self.refreshControl == nil else { return }
        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        refreshControl.tintColor = .white
        self.scrollView!.insertSubview(refreshControl, at: 0)
        self.scrollView!.alwaysBounceVertical = true
    }
    
    @objc func onPullToRefresh() {
        viewModel.fetchAccountDetail(isRefresh: true)
    }
        
    func styleViews() {
        view.backgroundColor = .primaryColorAccountPicker
        contentView.backgroundColor = .primaryColorAccountPicker

        topView.backgroundColor = .primaryColor
        bottomView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -3), radius: 2)
        
        prepaidHeaderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        prepaidDetailLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        prepaidBannerButton.layer.cornerRadius = 10
        if let header = prepaidHeaderLabel.text, let detail = prepaidDetailLabel.text {
            prepaidBannerButton.accessibilityLabel = "\(header). \(detail)"
        }

        alertBannerView.layer.cornerRadius = 10

        totalAmountView.superview?.bringSubviewToFront(totalAmountView)
        totalAmountView.addShadow(color: .black, opacity: 0.05, offset: CGSize(width: 0, height: 1), radius: 1)

        billBreakdownButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 1.5)
        billBreakdownButton.layer.cornerRadius = 10
        
        billPaidView.layer.cornerRadius = 10

        autoPayButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        autoPayButton.layer.cornerRadius = 2

        paperlessButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        paperlessButton.layer.cornerRadius = 2

        budgetButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        budgetButton.layer.cornerRadius = 2

        // Set Fonts
        totalAmountDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        catchUpDisclaimerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        pastDueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        pastDueAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        pastDueDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        remainingBalanceDueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        remainingBalanceDueLabel.textColor = .blackText
        remainingBalanceDueAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        remainingBalanceDueAmountLabel.textColor = .blackText
        
        currentBillLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        currentBillAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        currentBillDateLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        paymentReceivedLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        paymentReceivedAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        paymentReceivedDateLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        pendingPaymentLabel.font = OpenSans.italic.of(textStyle: .subheadline)
        pendingPaymentLabel.textColor = .blackText
        
        pendingPaymentAmountLabel.font = OpenSans.semiboldItalic.of(textStyle: .headline)
        pendingPaymentAmountLabel.textColor = .middleGray
        
        billBreakdownLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        viewBillLabel.font = SystemFont.semibold.of(textStyle: .footnote)

        billPaidLabel.font = SystemFont.bold.of(textStyle: .title1)
        makeAPaymentStatusLabel.font = OpenSans.italic.of(textStyle: .subheadline)
        
        billPaidView.isAccessibilityElement = true
        billPaidView.accessibilityLabel = NSLocalizedString("Bill Paid, dimmed, button", comment: "")
    
        genericErrorLabel.font = SystemFont.regular.of(textStyle: .headline)
        genericErrorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }
    
    func bindViews() {
		bindLoadingStates()
		bindViewHiding()
		bindViewContent()
    }
    
    func showLoadedState() {
        billLoadingIndicator.isHidden = true
        loadingIndicatorView.isHidden = true
        topView.isHidden = false
        bottomView.isHidden = false
        errorView.isHidden = true
        prepaidView.isHidden = true
        bottomStackContainerView.isHidden = false
        scrollView?.isHidden = false
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        enableRefresh()
    }
    
    func showErrorState(error: ServiceError?) {
        if error?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
            scrollView?.isHidden = true
            noNetworkConnectionView.isHidden = false
        } else {
            scrollView?.isHidden = false
            noNetworkConnectionView.isHidden = true
        }
        
        billLoadingIndicator.isHidden = true
        loadingIndicatorView.isHidden = true
        topView.isHidden = true
        bottomView.isHidden = true
        errorView.isHidden = false
        prepaidView.isHidden = true
        bottomStackContainerView.isHidden = true
        maintenanceModeView.isHidden = true
        
        if error?.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
            genericErrorView.isHidden = true
            accountDisallowView.isHidden = false
        } else {
            genericErrorView.isHidden = false
            accountDisallowView.isHidden = true
        }
        
        enableRefresh()
    }
    
    func showPrepaidState() {
        billLoadingIndicator.isHidden = true
        loadingIndicatorView.isHidden = true
        topView.isHidden = true
        bottomView.isHidden = true
        errorView.isHidden = true
        prepaidView.isHidden = false
        bottomStackContainerView.isHidden = true
        scrollView?.isHidden = false
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        enableRefresh()
    }
    
    func showMaintenanceModeState() {
        maintenanceModeView.isHidden = false
        
        scrollView?.isHidden = true
        noNetworkConnectionView.isHidden = true
        
        billLoadingIndicator.isHidden = true
        loadingIndicatorView.isHidden = true
        topView.isHidden = true
        bottomView.isHidden = true
        errorView.isHidden = true
        prepaidView.isHidden = true
        bottomStackContainerView.isHidden = true
        
        enableRefresh()
    }
    
    func showSwitchingAccountState() {
        scrollView?.isHidden = false
        noNetworkConnectionView.isHidden = true
        billLoadingIndicator.isHidden = false
        loadingIndicatorView.isHidden = false
        topView.isHidden = false
        bottomView.isHidden = false
        errorView.isHidden = true
        prepaidView.isHidden = true
        bottomStackContainerView.isHidden = true
        
        refreshControl?.endRefreshing()
        refreshControl?.removeFromSuperview()
        refreshControl = nil
        scrollView!.alwaysBounceVertical = false
        
        maintenanceModeView.isHidden = true
    }

	func bindLoadingStates() {
        viewModel.refreshTracker.asDriver().filter(!).drive(onNext: { [weak self] refresh in
            self?.refreshControl?.endRefreshing()
        }).disposed(by: bag)
        
        viewModel.switchAccountsTracker.asDriver()
            .filter { $0 }
            .mapTo(())
            .startWith(())
            .drive(onNext: { [weak self] in self?.showSwitchingAccountState() })
            .disposed(by: bag)
        viewModel.showLoadedState.drive(onNext: { [weak self] in self?.showLoadedState() }).disposed(by: bag)
        viewModel.accountDetailError.drive(onNext: { [weak self] in self?.showErrorState(error: $0) }).disposed(by: bag)
        viewModel.showPrepaidState.drive(onNext: { [weak self] in self?.showPrepaidState() }).disposed(by: bag)
        viewModel.showMaintenanceMode.drive(onNext: { [weak self] in self?.showMaintenanceModeState() }).disposed(by: bag)
        
        // Clear shortcut handling in the case of an error.
        viewModel.accountDetailError.asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.shortcutItem = .none
            })
            .disposed(by: bag)
	}

	func bindViewHiding() {
        viewModel.showPrepaidPending.not().drive(prepaidBannerButton.rx.isHidden).disposed(by: bag)
        
        viewModel.showAlertBanner.not().drive(alertBannerView.rx.isHidden).disposed(by: bag)
        viewModel.showAlertBanner.filter { $0 }.mapTo(())
            .drive(alertBannerView.rx.resetAnimation)
            .disposed(by: bag)

        questionMarkButton.isHidden = !viewModel.showAmountDueTooltip
        
        viewModel.showTopContent.not().drive(totalAmountView.rx.isHidden).disposed(by: bag)
        viewModel.showTopContent.not().drive(paymentDetailsView.rx.isHidden).disposed(by: bag)
        
		viewModel.showCatchUpDisclaimer.not().drive(catchUpDisclaimerView.rx.isHidden).disposed(by: bag)
        viewModel.showPastDue.not().drive(pastDueView.rx.isHidden).disposed(by: bag)
        viewModel.showCurrentBill.not().drive(currentBillView.rx.isHidden).disposed(by: bag)
        viewModel.showPaymentReceived.not().drive(paymentReceivedView.rx.isHidden).disposed(by: bag)
        
		viewModel.showPendingPayment.not().drive(pendingPaymentView.rx.isHidden).disposed(by: bag)
		viewModel.showRemainingBalanceDue.not().drive(remainingBalanceDueView.rx.isHidden).disposed(by: bag)

		viewModel.showBillBreakdownButton.not().drive(billBreakdownButton.rx.isHidden).disposed(by: bag)

		viewModel.enableMakeAPaymentButton.not().drive(makeAPaymentButton.rx.isHidden).disposed(by: bag)
		viewModel.enableMakeAPaymentButton.drive(billPaidView.rx.isHidden).disposed(by: bag)
        viewModel.showPaymentStatusText.not().drive(makeAPaymentStatusButton.rx.isHidden).disposed(by: bag)

        viewModel.showAutoPay.not().drive(autoPayButton.rx.isHidden).disposed(by: bag)
		viewModel.showPaperless.not().drive(paperlessButton.rx.isHidden).disposed(by: bag)
		viewModel.showBudget.not().drive(budgetButton.rx.isHidden).disposed(by: bag)
	}

    func bindViewContent() {
        viewModel.alertBannerText.drive(alertBannerView.label.rx.text).disposed(by: bag)
        viewModel.alertBannerA11yText.drive(alertBannerView.label.rx.accessibilityLabel).disposed(by: bag)

		viewModel.totalAmountText.drive(totalAmountLabel.rx.text).disposed(by: bag)
        viewModel.totalAmountDescriptionText.drive(totalAmountDescriptionLabel.rx.attributedText).disposed(by: bag)

        viewModel.catchUpDisclaimerText.drive(catchUpDisclaimerLabel.rx.text).disposed(by: bag)
        viewModel.pastDueText.drive(pastDueLabel.rx.text).disposed(by: bag)
		viewModel.pastDueAmountText.drive(pastDueAmountLabel.rx.text).disposed(by: bag)
        viewModel.pastDueDateText.drive(pastDueDateLabel.rx.attributedText).disposed(by: bag)
        viewModel.currentBillAmountText.drive(currentBillAmountLabel.rx.text).disposed(by: bag)
        viewModel.currentBillDateText.drive(currentBillDateLabel.rx.text).disposed(by: bag)
        viewModel.paymentReceivedAmountText.drive(paymentReceivedAmountLabel.rx.text).disposed(by: bag)
        viewModel.paymentReceivedDateText.drive(paymentReceivedDateLabel.rx.text).disposed(by: bag)

        pendingPaymentLabel.text = viewModel.pendingPaymentsText
        viewModel.pendingPaymentsTotalAmountText.drive(pendingPaymentAmountLabel.rx.text).disposed(by: bag)

        remainingBalanceDueLabel.text = viewModel.remainingBalanceDueText
        viewModel.remainingBalanceDueAmountText.drive(remainingBalanceDueAmountLabel.rx.text).disposed(by: bag)

        viewModel.paymentStatusText.drive(makeAPaymentStatusLabel.rx.text).disposed(by: bag)
        viewModel.paymentStatusText.drive(makeAPaymentStatusButton.rx.accessibilityLabel).disposed(by: bag)
        
        viewModel.billBreakdownButtonTitle.drive(billBreakdownLabel.rx.text).disposed(by: bag)
        viewModel.billBreakdownButtonTitle.drive(billBreakdownButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.hasBillBreakdownData
            .map { $0 ? #imageLiteral(resourceName: "ic_billbreakdown") : #imageLiteral(resourceName: "ic_usagemini") }
            .drive(billBreakdownImageView.rx.image)
            .disposed(by: bag)

		viewModel.autoPayButtonText.drive(autoPayEnrollmentLabel.rx.attributedText).disposed(by: bag)
		viewModel.paperlessButtonText.drive(paperlessEnrollmentLabel.rx.attributedText).disposed(by: bag)
		viewModel.budgetButtonText.drive(budgetBillingEnrollmentLabel.rx.attributedText).disposed(by: bag)
	}

    func bindButtonTaps() {
        maintenanceModeView.reload
            .mapTo(FetchingAccountState.switchAccount)
            .bind(to: viewModel.fetchAccountDetail)
            .disposed(by: maintenanceModeView.disposeBag)
        
        noNetworkConnectionView.reload
            .mapTo(FetchingAccountState.switchAccount)
            .bind(to: viewModel.fetchAccountDetail)
            .disposed(by: bag)
        
        prepaidBannerButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                Analytics.log(event: .prePaidPending)
                UIApplication.shared.openUrlIfCan(self?.viewModel.prepaidUrl)
            })
            .disposed(by: bag)
        
        questionMarkButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                let alertController = UIAlertController(title: NSLocalizedString("Your Due Date", comment: ""),
                                                        message: NSLocalizedString("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.", comment: ""), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        billBreakdownButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.hasBillBreakdownData)
            .filter(!)
            .drive(onNext: { [weak self] _ in
                self?.tabBarController?.selectedIndex = 3
            })
            .disposed(by: bag)

        billBreakdownButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.hasBillBreakdownData)
            .filter { $0 }
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] in
                let billBreakdownVC = BillBreakdownViewController(accountDetail: $0)
                billBreakdownVC.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(billBreakdownVC, animated: true)
            })
            .disposed(by: bag)

        viewBillButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                if Environment.shared.opco == .comEd &&
                    accountDetail.hasElectricSupplier &&
                    accountDetail.isSingleBillOption {
                    let alertVC = UIAlertController(title: NSLocalizedString("You are enrolled with a Supplier who provides you with your electricity bill, including your ComEd delivery charges. Please reach out to your Supplier for your bill image.", comment: ""), message: nil, preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                } else {
                    guard let _ = accountDetail.billingInfo.billDate else {
                        let alertVC = UIAlertController(title: NSLocalizedString("You will be able to view the PDF of your bill once its ready.", comment: ""), message: nil, preferredStyle: .alert)
                        alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self.present(alertVC, animated: true, completion: nil)
                        return
                    }
                    self.performSegue(withIdentifier: "viewBillSegue", sender: accountDetail)
                }
                
                Analytics.log(event: .billViewCurrentOfferComplete)
            })
			.disposed(by: bag)

		autoPayButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
			.drive(onNext: { [weak self] in
                self?.navigateToAutoPay(accountDetail: $0)
			})
			.disposed(by: bag)
        
        activityButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "billingHistorySegue", sender: $0)
            })
            .disposed(by: bag)
        
        walletButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let walletVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateInitialViewController() as! WalletViewController
                walletVc.viewModel.accountDetail = $0
                self.navigationController?.pushViewController(walletVc, animated: true)
            })
            .disposed(by: bag)

		paperlessButton.rx.touchUpInside.asDriver()
			.withLatestFrom(viewModel.currentAccountDetail)
			.drive(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                if !accountDetail.isResidential && Environment.shared.opco != .bge {
					self.performSegue(withIdentifier: "paperlessEBillCommercialSegue", sender: accountDetail)
				} else {
					self.performSegue(withIdentifier: "paperlessEBillSegue", sender: accountDetail)
				}
			})
			.disposed(by: bag)

        budgetButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                if accountDetail.isBudgetBillEligible || accountDetail.isBudgetBillEnrollment {
                    self.performSegue(withIdentifier: "budgetBillingSegue", sender: accountDetail)
                } else {
                    var message = NSLocalizedString("Sorry, you are ineligible for Budget Billing", comment: "")
                    if let budgetBillMessage = accountDetail.budgetBillMessage {
                        if budgetBillMessage.contains("not enough billing history") {
                            message = NSLocalizedString("There is insufficient billing history to calculate your Budget Billing amount at this location. If you would like your Budget Billing amount to be manually calculated, please contact BGE customer service at myhomerep@bge.com.", comment: "")
                        }
                    }
                    let alertVC = UIAlertController(title: NSLocalizedString("Ineligible for Budget Billing", comment: ""), message: message, preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                }
            })
            .disposed(by: bag)
        
        let shortcutReady = Observable.zip(viewModel.makePaymentScheduledPaymentAlertInfo,
                                           viewModel.enableMakeAPaymentButton.asObservable())
            .filter { [weak self] in $1 && self?.shortcutItem == .payBill }
            .map { $0.0 }
        
        let makeAPaymentButtonTapped = makeAPaymentButton.rx.touchUpInside.asObservable()
            .withLatestFrom(viewModel.makePaymentScheduledPaymentAlertInfo)
        
        Observable.merge(makeAPaymentButtonTapped, shortcutReady)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] alertInfo in
                guard let self = self else { return }
                self.shortcutItem = .none
                let (titleOpt, messageOpt, accountDetail) = alertInfo
                let goToMakePayment = { [weak self] in
                    guard let self = self else { return }
                    let paymentVc = UIStoryboard(name: "Payment", bundle: nil).instantiateInitialViewController() as! MakePaymentViewController
                    paymentVc.accountDetail = accountDetail
                    self.navigationController?.pushViewController(paymentVc, animated: true)
                }
                
                if let title = titleOpt, let message = messageOpt {
                    let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { _ in
                        goToMakePayment()
                    }))
                    self.present(alertVc, animated: true, completion: nil)
                } else {
                    goToMakePayment()
                }
            })
            .disposed(by: bag)
        
        makeAPaymentStatusButton.rx.touchUpInside.asDriver()
            .withLatestFrom(Driver.combineLatest(viewModel.makePaymentStatusTextTapRouting, viewModel.currentAccountDetail))
            .drive(onNext: { [weak self] route, accountDetail in
                guard let self = self else { return }
                if route == .activity {
                    self.performSegue(withIdentifier: "billingHistorySegue", sender: accountDetail)
                } else if route == .autoPay {
                    self.navigateToAutoPay(accountDetail: accountDetail)
                }
            })
            .disposed(by: bag)
    }
    
    func navigateToAutoPay(accountDetail: AccountDetail) {
        if Environment.shared.opco == .bge {
            if accountDetail.isBGEasy {
                self.performSegue(withIdentifier: "viewBGEasySegue", sender: accountDetail)
            } else {
                self.performSegue(withIdentifier: "bgeAutoPaySegue", sender: accountDetail)
            }
        } else {
            self.performSegue(withIdentifier: "autoPaySegue", sender: accountDetail)
        }
    }

    func configureAccessibility() {
        questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        viewBillButton.accessibilityLabel = NSLocalizedString("PDF, View bill", comment: "")
        activityButton.accessibilityLabel = NSLocalizedString("Bill & Payment Activity", comment: "")
        walletButton.accessibilityLabel = NSLocalizedString("My Wallet", comment: "")
        
        viewModel.autoPayButtonText.map { $0.string }.drive(autoPayButton.rx.accessibilityLabel).disposed(by: bag)
        
        viewModel.paperlessButtonText
            .map { $0?.string.replacingOccurrences(of: "eBill", with: "e-bill") }
            .drive(paperlessButton.rx.accessibilityLabel)
            .disposed(by: bag)
        
        viewModel.budgetButtonText.map { $0.string }.drive(budgetButton.rx.accessibilityLabel).disposed(by: bag)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case let (vc as BudgetBillingViewController, accountDetail as AccountDetail):
            vc.delegate = self
            vc.accountDetail = accountDetail
        case let (vc as PaperlessEBillViewController, accountDetail as AccountDetail):
            vc.delegate = self
            vc.initialAccountDetail = accountDetail
        case let (vc as ViewBillViewController, accountDetail as AccountDetail):
            vc.viewModel.billDate = accountDetail.billingInfo.billDate
            vc.viewModel.isCurrent = true
        case let (vc as BGEAutoPayViewController, accountDetail as AccountDetail):
            vc.delegate = self
            vc.accountDetail = accountDetail
        case let (vc as AutoPayViewController, accountDetail as AccountDetail):
            vc.delegate = self
            vc.accountDetail = accountDetail
        case let (vc as BillingHistoryViewController, accountDetail as AccountDetail):
            vc.viewModel.accountDetail = accountDetail
        default:
            break
        }
    }

    func showDelayedToast(withMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
    }
    
}

extension BillViewController: AccountPickerDelegate {

    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchAccountDetail(isRefresh: false)
    }

}

extension BillViewController: BudgetBillingViewControllerDelegate {

    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController, averageMonthlyBill: String?) {
        switch Environment.shared.opco {
        case .bge:
            let textFormat = NSLocalizedString("Enrolled in Budget Billing - your monthly rate is %@", comment: "")
            showDelayedToast(withMessage: String(format: textFormat, averageMonthlyBill ?? "--"))
        case .comEd, .peco:
            showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
        }
        Analytics.log(event: .budgetBillEnrollComplete)
    }

    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController) {
        showDelayedToast(withMessage: NSLocalizedString("Unenrolled from Budget Billing", comment: ""))
        Analytics.log(event: .budgetBillUnEnrollComplete)
    }
}

extension BillViewController: PaperlessEBillViewControllerDelegate {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus) {
        var toastMessage: String
        switch didChangeStatus {
        case .enroll:
            toastMessage = NSLocalizedString("Enrolled in Paperless eBill", comment: "")
            showDelayedToast(withMessage: toastMessage)
        case .unenroll:
            toastMessage = NSLocalizedString("Unenrolled from Paperless eBill", comment: "")
            showDelayedToast(withMessage: toastMessage)
        case .mixed: // ComEd/PECO only
            let action = InfoAlertAction(ctaText: NSLocalizedString("I understand", comment: ""))
            
            let alert = InfoAlertController(title: NSLocalizedString("Paperless eBill Changes Saved", comment: ""),
                                            message: NSLocalizedString("Your enrollment status may take up to 24 hours to update and may not be reflected immediately.", comment: ""),
                                            icon: #imageLiteral(resourceName: "ic_confirmation_mini"),
                                            action: action)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                self?.tabBarController?.present(alert, animated: true)
            }
        }
    }
}

extension BillViewController: AutoPayViewControllerDelegate {

    func autoPayViewController(_ autoPayViewController: AutoPayViewController, enrolled: Bool) {
        let message = enrolled ? NSLocalizedString("Enrolled in AutoPay", comment: ""): NSLocalizedString("Unenrolled from AutoPay", comment: "")
        showDelayedToast(withMessage: message)
        
        if enrolled {
            Analytics.log(event: .autoPayEnrollComplete)
        } else {
            Analytics.log(event: .autoPayUnenrollComplete)
        }
    }

}

extension BillViewController: BGEAutoPayViewControllerDelegate {
    
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String) {
        showDelayedToast(withMessage: message)
    }
}
