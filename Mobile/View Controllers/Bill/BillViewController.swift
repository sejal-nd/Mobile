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
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var topLoadingIndicatorView: UIView!
    @IBOutlet weak var topLoadingIndicator: LoadingIndicator!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
	@IBOutlet weak var bottomStackContainerView: UIView!

    @IBOutlet weak var alertBannerView: BillAlertBannerView!

    @IBOutlet weak var totalAmountView: UIView!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var totalAmountDescriptionLabel: UILabel!
    @IBOutlet weak var questionMarkButton: UIButton!

	@IBOutlet weak var paymentDetailsView: UIView!

	// Restore Service
	@IBOutlet weak var restoreServiceView: UIView!
    @IBOutlet weak var restoreServiceLabel: UILabel!
	@IBOutlet weak var restoreServiceAmountLabel: UILabel!
    @IBOutlet weak var restoreServiceDateLabel: UILabel!

	// Catch Up
    @IBOutlet weak var catchUpView: UIView!
    @IBOutlet weak var catchUpLabel: UILabel!
    @IBOutlet weak var catchUpAmountLabel: UILabel!
	@IBOutlet weak var catchUpDateLabel: UILabel!

	// Catch Up Disclaimer
	@IBOutlet weak var catchUpDisclaimerView: UIView!
	@IBOutlet weak var catchUpDisclaimerLabel: UILabel!

	// Avoid Shut-off
	@IBOutlet weak var avoidShutoffView: UIView!
	@IBOutlet weak var avoidShutoffLabel: UILabel!
	@IBOutlet weak var avoidShutoffAmountLabel: UILabel!
	@IBOutlet weak var avoidShutoffDateLabel: UILabel!

	// Past Due
    @IBOutlet weak var pastDueView: UIView!
    @IBOutlet weak var pastDueLabel: UILabel!
    @IBOutlet weak var pastDueAmountLabel: UILabel!
    @IBOutlet weak var pastDueDateLabel: UILabel!

	// Payments
	@IBOutlet weak var paymentStackView: UIStackView!

	// Remaining Balance Due
	@IBOutlet weak var remainingBalanceDueView: UIView!
	@IBOutlet weak var remainingBalanceDueLabel: UILabel!
	@IBOutlet weak var remainingBalanceDueAmountLabel: UILabel!
	@IBOutlet weak var remainingBalanceDueDateLabel: UILabel!

	// Remaining Balance Past Due
	@IBOutlet weak var remainingBalancePastDueView: UIView!
    @IBOutlet weak var remainingBalancePastDueLabel: UILabel!
    @IBOutlet weak var remainingBalancePastDueAmountLabel: UILabel!
    @IBOutlet weak var remainingBalancePastDueDateLabel: UILabel!

	// Bill Issued
    @IBOutlet weak var billIssuedView: UIView!
    @IBOutlet weak var billIssuedLabel: UILabel!
    @IBOutlet weak var billIssuedAmountLabel: UILabel!
	@IBOutlet weak var billIssuedDateLabel: UILabel!

    // Payment Received
    @IBOutlet weak var paymentReceivedView: UIView!
    @IBOutlet weak var paymentReceivedLabel: UILabel!
	@IBOutlet weak var paymentReceivedAmountLabel: UILabel!
	@IBOutlet weak var paymentReceivedDateLabel: UILabel!

	// Credit
	@IBOutlet weak var creditView: UIView!
    @IBOutlet weak var creditLabel: UILabel!
	@IBOutlet weak var creditAmountLabel: UILabel!

    @IBOutlet weak var needHelpUnderstandingButton: ButtonControl!
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

    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var genericErrorView: UIView!
    @IBOutlet weak var genericErrorLabel: UILabel!
    @IBOutlet weak var customErrorView: UIView!
    @IBOutlet weak var customErrorTitleLabel: UILabel!
    @IBOutlet weak var customErrorDetailLabel: UILabel!
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl?
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())

    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }

    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        Observable.combineLatest(accountPickerViewControllerWillAppear.asObservable(),
                                 viewModel.currentAccountDetail.asObservable().map { $0 }.startWith(nil))
            .sample(accountPickerViewControllerWillAppear)
            .subscribe(onNext: { [weak self] state, accountDetail in
                guard let `self` = self else { return }
                switch(state) {
                case .loadingAccounts:
                    // Sam, do your custom loading here
                    break
                case .readyToFetchData:
                    if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                        self.viewModel.fetchAccountDetail(isRefresh: false)
                    } else if accountDetail == nil {
                        self.viewModel.fetchAccountDetail(isRefresh: false)
                    }
                }
            })
            .disposed(by: bag)

        styleViews()
        bindViews()
        bindButtonTaps()
        configureAccessibility()
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: NSNotification.Name.DidMaintenanceModeTurnOn, object: nil)

        NotificationCenter.default.rx.notification(.DidSelectEnrollInAutoPay, object: nil)
        .subscribe(onNext: { [weak self] notification in
            guard let `self` = self else { return }
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
        enableRefresh()
        // -------------------------------------------------------------------------------------------------------
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
    
    @objc func killRefresh() -> Void {
        self.refreshControl?.endRefreshing()
        self.scrollView!.alwaysBounceVertical = false
    }
    
    func styleViews() {
        view.backgroundColor = .primaryColor
        contentView.backgroundColor = .primaryColor

        topView.backgroundColor = .primaryColor
        bottomView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -3), radius: 2)
        
        totalAmountView.superview?.bringSubview(toFront: totalAmountView)
        totalAmountView.addShadow(color: .black, opacity: 0.05, offset: CGSize(width: 0, height: 1), radius: 1)

        needHelpUnderstandingButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 1.5)

        billPaidView.layer.cornerRadius = 2

        autoPayButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        autoPayButton.layer.cornerRadius = 2

        paperlessButton.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        paperlessButton.layer.cornerRadius = 2

        budgetButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        budgetButton.layer.cornerRadius = 2

        // Set Fonts
        totalAmountDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)

        restoreServiceLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        restoreServiceAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        restoreServiceDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        catchUpLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        catchUpAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        catchUpDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        catchUpDisclaimerLabel.font = OpenSans.regular.of(textStyle: .footnote)

        avoidShutoffLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        avoidShutoffAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        avoidShutoffDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        pastDueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        pastDueAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        pastDueDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        remainingBalanceDueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        remainingBalanceDueAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        remainingBalanceDueDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        remainingBalancePastDueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        remainingBalancePastDueAmountLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        remainingBalancePastDueDateLabel.font = OpenSans.regular.of(textStyle: .caption2)

        billIssuedLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        billIssuedAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        billIssuedDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        paymentReceivedLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        paymentReceivedAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        paymentReceivedDateLabel.font = OpenSans.regular.of(textStyle: .footnote)

        creditLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        creditAmountLabel.font = OpenSans.semibold.of(textStyle: .headline)

        viewBillLabel.font = SystemFont.semibold.of(textStyle: .footnote)

        billPaidLabel.font = SystemFont.bold.of(textStyle: .title1)
        makeAPaymentStatusLabel.font = OpenSans.italic.of(textStyle: .subheadline)
        
        billPaidView.isAccessibilityElement = true
        billPaidView.accessibilityLabel = NSLocalizedString("Bill Paid, dimmed, button", comment: "")
    
        genericErrorLabel.font = SystemFont.regular.of(textStyle: .headline)
        genericErrorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        customErrorTitleLabel.text = NSLocalizedString("Account Ineligible", comment: "")
        customErrorDetailLabel.text = NSLocalizedString("This profile type does not have access to the mobile app. " +
            "Access your account on our responsive website.", comment: "")
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
        bottomStackContainerView.isHidden = false
        enableRefresh()
    }
    
    func showErrorState(error: ServiceError?) {
        billLoadingIndicator.isHidden = true
        loadingIndicatorView.isHidden = true
        topView.isHidden = true
        bottomView.isHidden = true
        errorView.isHidden = false
        bottomStackContainerView.isHidden = true
        
        if let serviceError = error, serviceError.serviceCode == ServiceErrorCode.FnAccountDisallow.rawValue {
            genericErrorView.isHidden = true
            customErrorView.isHidden = false
        } else {
            genericErrorView.isHidden = false
            customErrorView.isHidden = true
        }
        enableRefresh()
    }
    
    func showSwitchingAccountState() {
        billLoadingIndicator.isHidden = false
        loadingIndicatorView.isHidden = false
        topView.isHidden = false
        bottomView.isHidden = false
        errorView.isHidden = true
        bottomStackContainerView.isHidden = true
        
        refreshControl?.endRefreshing()
        refreshControl?.removeFromSuperview()
        refreshControl = nil
        scrollView!.alwaysBounceVertical = false
    }

	func bindLoadingStates() {
        topLoadingIndicatorView.isHidden = true
        viewModel.refreshTracker.asDriver().filter(!).drive(onNext: { [weak self] refresh in
            self?.refreshControl?.endRefreshing()
        }).disposed(by: bag)
        
        viewModel.switchAccountsTracker.asDriver()
            .filter { $0 }
            .map(to: ())
            .drive(onNext: { [weak self] in self?.showSwitchingAccountState() })
            .disposed(by: bag)
        viewModel.showLoadedState.drive(onNext: { [weak self] in self?.showLoadedState() }).disposed(by: bag)
        viewModel.accountDetailError.drive(onNext: { [weak self] in self?.showErrorState(error: $0) }).disposed(by: bag)
	}

	func bindViewHiding() {
        viewModel.shouldShowAlertBanner.not().drive(alertBannerView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowAlertBanner.filter { $0 }.map(to: ())
            .drive(alertBannerView.rx.resetAnimation)
            .disposed(by: bag)

        viewModel.shouldShowAmountDueTooltip.not().drive(questionMarkButton.rx.isHidden).disposed(by: bag)
        
        viewModel.shouldShowTopContent.not().drive(totalAmountView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowTopContent.not().drive(paymentDetailsView.rx.isHidden).disposed(by: bag)
        
		viewModel.shouldShowRestoreService.not().drive(restoreServiceView.rx.isHidden).disposed(by: bag)
        viewModel.pendingPaymentAmountDueBoxesAlpha.drive(restoreServiceView.rx.alpha).disposed(by: bag)
        viewModel.shouldShowCatchUpAmount.not().drive(catchUpView.rx.isHidden).disposed(by: bag)
        viewModel.pendingPaymentAmountDueBoxesAlpha.drive(catchUpView.rx.alpha).disposed(by: bag)
		viewModel.shouldShowCatchUpDisclaimer.not().drive(catchUpDisclaimerView.rx.isHidden).disposed(by: bag)
        viewModel.pendingPaymentAmountDueBoxesAlpha.drive(catchUpDisclaimerView.rx.alpha).disposed(by: bag)
		viewModel.shouldShowAvoidShutoff.not().drive(avoidShutoffView.rx.isHidden).disposed(by: bag)
        viewModel.pendingPaymentAmountDueBoxesAlpha.drive(avoidShutoffView.rx.alpha).disposed(by: bag)
        viewModel.shouldShowPastDue.not().drive(pastDueView.rx.isHidden).disposed(by: bag)
        
        viewModel.pendingPaymentAmountDueBoxesAlpha.drive(pastDueView.rx.alpha).disposed(by: bag)

		viewModel.shouldShowPendingPayment.not().drive(paymentStackView.rx.isHidden).disposed(by: bag)
		viewModel.shouldShowRemainingBalanceDue.not().drive(remainingBalanceDueView.rx.isHidden).disposed(by: bag)
		viewModel.shouldShowRemainingBalancePastDue.not().drive(remainingBalancePastDueView.rx.isHidden).disposed(by: bag)
		viewModel.shouldShowBillIssued.not().drive(billIssuedView.rx.isHidden).disposed(by: bag)
		viewModel.shouldShowPaymentReceived.not().drive(paymentReceivedView.rx.isHidden).disposed(by: bag)
		viewModel.shouldShowCredit.not().drive(creditView.rx.isHidden).disposed(by: bag)

		viewModel.shouldShowNeedHelpUnderstanding.not().drive(needHelpUnderstandingButton.rx.isHidden).disposed(by: bag)

		viewModel.shouldEnableMakeAPaymentButton.not().drive(makeAPaymentButton.rx.isHidden).disposed(by: bag)
		viewModel.shouldEnableMakeAPaymentButton.drive(billPaidView.rx.isHidden).disposed(by: bag)
        viewModel.paymentStatusText.map { $0 == nil }.drive(makeAPaymentStatusButton.rx.isHidden).disposed(by: bag)

        viewModel.shouldShowAutoPay.not().drive(autoPayButton.rx.isHidden).disposed(by: bag)
		viewModel.shouldShowPaperless.not().drive(paperlessButton.rx.isHidden).disposed(by: bag)
		viewModel.shouldShowBudget.not().drive(budgetButton.rx.isHidden).disposed(by: bag)
	}

    func bindViewContent() {
        viewModel.alertBannerText.drive(alertBannerView.label.rx.text).disposed(by: bag)
        viewModel.alertBannerA11yText.drive(alertBannerView.label.rx.accessibilityLabel).disposed(by: bag)

		viewModel.totalAmountText.drive(totalAmountLabel.rx.text).disposed(by: bag)
        viewModel.totalAmountDescriptionText.drive(totalAmountDescriptionLabel.rx.text).disposed(by: bag)

		viewModel.restoreServiceAmountText.drive(restoreServiceAmountLabel.rx.text).disposed(by: bag)
		viewModel.catchUpAmountText.drive(catchUpAmountLabel.rx.text).disposed(by: bag)
		viewModel.catchUpDateText.drive(catchUpDateLabel.rx.text).disposed(by: bag)
        viewModel.catchUpDisclaimerText.drive(catchUpDisclaimerLabel.rx.text).disposed(by: bag)
        avoidShutoffLabel.text = viewModel.avoidShutoffText
        avoidShutoffLabel.accessibilityLabel = viewModel.avoidShutoffA11yText
		viewModel.avoidShutoffAmountText.drive(avoidShutoffAmountLabel.rx.text).disposed(by: bag)
		viewModel.avoidShutoffDueDateText.drive(avoidShutoffDateLabel.rx.text).disposed(by: bag)
		viewModel.pastDueAmountText.drive(pastDueAmountLabel.rx.text).disposed(by: bag)

		viewModel.pendingPaymentAmounts
			.map { $0.map { PendingPaymentView.create(withAmount: $0) } }
			.drive(onNext: { [weak self] pendingPaymentViews in
                guard let `self` = self else { return }
                
				self.paymentStackView.arrangedSubviews.forEach {
					self.paymentStackView.removeArrangedSubview($0)
					$0.removeFromSuperview()
				}

				pendingPaymentViews.forEach { self.paymentStackView.addArrangedSubview($0) }
			})
			.disposed(by: bag)

		remainingBalanceDueLabel.text = viewModel.remainingBalanceDueText
		viewModel.remainingBalanceDueAmountText.drive(remainingBalanceDueAmountLabel.rx.text).disposed(by: bag)
		viewModel.remainingBalanceDueDateText.drive(remainingBalanceDueDateLabel.rx.text).disposed(by: bag)
		remainingBalancePastDueLabel.text = viewModel.remainingBalancePastDueText
		viewModel.remainingBalancePastDueAmountText.drive(remainingBalancePastDueAmountLabel.rx.text).disposed(by: bag)
		viewModel.billIssuedAmountText.drive(billIssuedAmountLabel.rx.text).disposed(by: bag)
		viewModel.billIssuedDateText.drive(billIssuedDateLabel.rx.text).disposed(by: bag)
		viewModel.paymentReceivedAmountText.drive(paymentReceivedAmountLabel.rx.text).disposed(by: bag)
		viewModel.paymentReceivedDateText.drive(paymentReceivedDateLabel.rx.text).disposed(by: bag)
		viewModel.creditAmountText.drive(creditAmountLabel.rx.text).disposed(by: bag)

        viewModel.paymentStatusText.drive(makeAPaymentStatusLabel.rx.text).disposed(by: bag)
        viewModel.paymentStatusText.drive(makeAPaymentStatusButton.rx.accessibilityLabel).disposed(by: bag)

		viewModel.autoPayButtonText.drive(autoPayEnrollmentLabel.rx.attributedText).disposed(by: bag)
		viewModel.paperlessButtonText.drive(paperlessEnrollmentLabel.rx.attributedText).disposed(by: bag)
		viewModel.budgetButtonText.drive(budgetBillingEnrollmentLabel.rx.attributedText).disposed(by: bag)
	}

    func bindButtonTaps() {
        questionMarkButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                let alertController = UIAlertController(title: NSLocalizedString("Your Due Date", comment: ""),
                                                        message: NSLocalizedString("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.", comment: ""), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: bag)

        needHelpUnderstandingButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] in
                let billAnalysis = BillAnalysisViewController()
                billAnalysis.hidesBottomBarWhenPushed = true
                billAnalysis.viewModel.accountDetail = $0
                self?.navigationController?.pushViewController(billAnalysis, animated: true)
            })
            .disposed(by: bag)

        viewBillButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                if Environment.sharedInstance.opco == .comEd &&
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
                
                if(self.pastDueView.isHidden) {
                    Analytics().logScreenView(AnalyticsPageView.BillViewCurrentOfferComplete.rawValue)
                } else {
                    Analytics().logScreenView(AnalyticsPageView.BillViewPastOfferComplete.rawValue)
                }
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
                guard let `self` = self else { return }
                let walletVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateInitialViewController() as! WalletViewController
                walletVc.viewModel.accountDetail = $0
                self.navigationController?.pushViewController(walletVc, animated: true)
            })
            .disposed(by: bag)

		paperlessButton.rx.touchUpInside.asDriver()
			.withLatestFrom(viewModel.currentAccountDetail)
			.drive(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                if !accountDetail.isResidential && Environment.sharedInstance.opco != .bge {
					self.performSegue(withIdentifier: "paperlessEBillCommercialSegue", sender: accountDetail)
				} else {
					self.performSegue(withIdentifier: "paperlessEBillSegue", sender: accountDetail)
				}
			})
			.disposed(by: bag)

        budgetButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
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
        
        makeAPaymentButton.rx.touchUpInside.asObservable()
            .withLatestFrom(Observable.combineLatest(viewModel.makePaymentScheduledPaymentAlertInfo,
                                                     viewModel.currentAccountDetail.asObservable()))
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] alertInfo, accountDetail in
                guard let `self` = self else { return }
                let (titleOpt, messageOpt) = alertInfo
                let goToMakePayment = { [weak self] in
                    guard let `self` = self else { return }
                    let paymentVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "makeAPayment") as! MakePaymentViewController
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
                guard let `self` = self else { return }
                if route == .activity {
                    self.performSegue(withIdentifier: "billingHistorySegue", sender: accountDetail)
                } else if route == .autoPay {
                    self.navigateToAutoPay(accountDetail: accountDetail)
                }
            })
            .disposed(by: bag)
    }
    
    func navigateToAutoPay(accountDetail: AccountDetail) {
        if Environment.sharedInstance.opco == .bge {
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
        needHelpUnderstandingButton.accessibilityLabel = NSLocalizedString("Need help understanding your bill?", comment: "")
        viewBillButton.accessibilityLabel = NSLocalizedString("PDF, View bill", comment: "")
        activityButton.accessibilityLabel = NSLocalizedString("Activity", comment: "")
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
            vc.accountDetail = accountDetail
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

    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController) {
        showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
        Analytics().logScreenView(AnalyticsPageView.BudgetBillEnrollComplete.rawValue)
    }

    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController) {
        showDelayedToast(withMessage: NSLocalizedString("Unenrolled from Budget Billing", comment: ""))
        Analytics().logScreenView(AnalyticsPageView.BudgetBillUnEnrollComplete.rawValue)
    }
}

extension BillViewController: PaperlessEBillViewControllerDelegate {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus) {
        var toastMessage: String
        switch didChangeStatus {
        case .Enroll:
            toastMessage = NSLocalizedString("Enrolled in Paperless eBill", comment: "")
            Analytics().logScreenView(AnalyticsPageView.EBillEnrollComplete.rawValue)
        case .Unenroll:
            toastMessage = NSLocalizedString("Unenrolled from Paperless eBill", comment: "")
            Analytics().logScreenView(AnalyticsPageView.EBillUnEnrollComplete.rawValue)
        case .Mixed:
            toastMessage = NSLocalizedString("Paperless eBill changes saved", comment: "")
        }
        showDelayedToast(withMessage: toastMessage)
    }
}

extension BillViewController: AutoPayViewControllerDelegate {

    func autoPayViewController(_ autoPayViewController: AutoPayViewController, enrolled: Bool) {
        let message = enrolled ? NSLocalizedString("Enrolled in AutoPay", comment: ""): NSLocalizedString("Unenrolled from AutoPay", comment: "")
        showDelayedToast(withMessage: message)
        
        if enrolled {
            Analytics().logScreenView(AnalyticsPageView.AutoPayEnrollComplete.rawValue)
        } else {
            Analytics().logScreenView(AnalyticsPageView.AutoPayUnenrollComplete.rawValue)
        }
    }

}

extension BillViewController: BGEAutoPayViewControllerDelegate {
    
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String) {
        showDelayedToast(withMessage: message)
    }
}
