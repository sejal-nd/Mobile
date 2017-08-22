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

    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl? {
        didSet {
            refreshDisposable?.dispose()
            refreshDisposable = refreshControl?.rx.controlEvent(.valueChanged).asObservable()
				.map { FetchingAccountState.refresh }
				.bind(to: viewModel.fetchAccountDetail)
        }
    }

    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())

    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }

    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                // Sam, do your custom loading here
                break
            case .readyToFetchData:
                if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                    self.viewModel.fetchAccountDetail(isRefresh: false)
                } else if self.viewModel.currentAccountDetail.value == nil {
                    self.viewModel.fetchAccountDetail(isRefresh: false)
                }
            }
        }).disposed(by: bag)

        styleViews()
        bindViews()
        bindButtonTaps()
        configureAccessibility()
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: NSNotification.Name.DidMaintenanceModeTurnOn, object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func killRefresh() -> Void {
        self.refreshControl?.endRefreshing()
        self.scrollView.alwaysBounceVertical = false
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
    }

    func bindViews() {
		bindLoadingStates()
		bindViewHiding()
		bindViewContent()
    }

	func bindLoadingStates() {
        topLoadingIndicatorView.isHidden = true
        viewModel.isFetchingAccountDetail.filter(!).drive(onNext: { [weak self] refresh in
            if refresh {
                self?.refreshControl?.beginRefreshing()
            } else {
                self?.refreshControl?.endRefreshing()
            }
        }).disposed(by: bag)

        viewModel.isFetchingDifferentAccount.not().drive(onNext: { [weak self] refresh in
            guard let `self` = self else { return }
            if refresh {
                guard self.refreshControl == nil else { return }
                let refreshControl = UIRefreshControl()
                self.refreshControl = refreshControl
                refreshControl.tintColor = .white
                self.scrollView.insertSubview(refreshControl, at: 0)
                self.scrollView.alwaysBounceVertical = true
            } else {
                self.refreshControl?.endRefreshing()
                self.refreshControl?.removeFromSuperview()
                self.refreshControl = nil
                self.scrollView.alwaysBounceVertical = false
            }
        }).disposed(by: bag)
        
        viewModel.isFetchingDifferentAccount.drive(billLoadingIndicator.rx.isAnimating).disposed(by: bag)
        viewModel.isFetchingDifferentAccount.not().drive(loadingIndicatorView.rx.isHidden).disposed(by: bag)
        viewModel.isFetchingDifferentAccount.drive(bottomStackContainerView.rx.isHidden).disposed(by: bag)
	}

	func bindViewHiding() {
        viewModel.shouldShowAlertBanner.not().drive(alertBannerView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowAlertBanner.filter { $0 }.toVoid()
            .drive(alertBannerView.rx.resetAnimation)
            .disposed(by: bag)

		questionMarkButton.isHidden = !viewModel.shouldShowAmountDueTooltip
        
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

		viewModel.autoPayButtonText.drive(autoPayEnrollmentLabel.rx.attributedText).disposed(by: bag)
		viewModel.paperlessButtonText.drive(paperlessEnrollmentLabel.rx.attributedText).disposed(by: bag)
		viewModel.budgetButtonText.drive(budgetBillingEnrollmentLabel.rx.attributedText).disposed(by: bag)

        viewModel.accountDetailErrorMessage
            .drive(onNext: { [weak self] errorMessage in
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: bag)
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
            .drive(onNext: {
                dLog("need help tapped")
            })
            .disposed(by: bag)

        viewBillButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                if Environment.sharedInstance.opco == .comEd &&
                    self.viewModel.currentAccountDetail.value!.hasElectricSupplier &&
                    self.viewModel.currentAccountDetail.value!.isSingleBillOption {
                    let alertVC = UIAlertController(title: NSLocalizedString("You are enrolled with a Supplier who provides you with your electricity bill, including your ComEd delivery charges. Please reach out to your Supplier for your bill image.", comment: ""), message: nil, preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                } else {
                    self.performSegue(withIdentifier: "viewBillSegue", sender: self)
                }
                
                if(self.pastDueView.isHidden) {
                    Analytics().logScreenView(AnalyticsPageView.BillViewCurrentOfferComplete.rawValue)
                } else {
                    Analytics().logScreenView(AnalyticsPageView.BillViewPastOfferComplete.rawValue)
                }
            })
			.disposed(by: bag)

		autoPayButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetailUnwrapped)
			.drive(onNext: { [weak self] in
                self?.navigateToAutoPay(accountDetail: $0)
			})
			.disposed(by: bag)
        
        activityButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "billingHistorySegue", sender: self)
            })
            .disposed(by: bag)
        
        walletButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                let walletVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateInitialViewController() as! WalletViewController
                walletVc.viewModel.accountDetail = self.viewModel.currentAccountDetail.value!
                self.navigationController?.pushViewController(walletVc, animated: true)
            })
            .disposed(by: bag)

		paperlessButton.rx.touchUpInside.asDriver()
			.withLatestFrom(viewModel.currentAccountDetailUnwrapped)
			.drive(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                if !accountDetail.isResidential && Environment.sharedInstance.opco != .bge {
					self.performSegue(withIdentifier: "paperlessEBillCommercialSegue", sender: self)
				} else {
					self.performSegue(withIdentifier: "paperlessEBillSegue", sender: self)
				}
			})
			.disposed(by: bag)

        budgetButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetailUnwrapped)
            .drive(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                if accountDetail.isBudgetBillEligible || accountDetail.isBudgetBillEnrollment {
                    self.performSegue(withIdentifier: "budgetBillingSegue", sender: self)
                } else {
                    var message = NSLocalizedString("Sorry, you are ineligible for Budget Billing", comment: "")
                    if let budgetBillMessage = accountDetail.budgetBillMessage {
                        if budgetBillMessage.contains("Your account has not yet been open for a year") {
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
            .withLatestFrom(viewModel.makePaymentScheduledPaymentAlertInfo)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] titleOpt, messageOpt in
                guard let `self` = self else { return }
                let goToMakePayment = { [weak self] in
                    guard let `self` = self else { return }
                    let paymentVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "makeAPayment") as! MakePaymentViewController
                    paymentVc.accountDetail = self.viewModel.currentAccountDetail.value!
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
            .withLatestFrom(Driver.combineLatest(viewModel.makePaymentStatusTextTapRouting, viewModel.currentAccountDetailUnwrapped))
            .drive(onNext: { [weak self] route, accountDetail in
                guard let `self` = self else { return }
                if route == .activity {
                    self.performSegue(withIdentifier: "billingHistorySegue", sender: self)
                } else if route == .autoPay {
                    self.navigateToAutoPay(accountDetail: accountDetail)
                }
            })
            .disposed(by: bag)
    }
    
    func navigateToAutoPay(accountDetail: AccountDetail) {
        if Environment.sharedInstance.opco == .bge {
            if accountDetail.isBGEasy {
                self.performSegue(withIdentifier: "viewBGEasySegue", sender: self)
            } else {
                self.performSegue(withIdentifier: "bgeAutoPaySegue", sender: self)
            }
        } else {
            self.performSegue(withIdentifier: "autoPaySegue", sender: self)
        }
    }

    func configureAccessibility() {
        questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        needHelpUnderstandingButton.accessibilityLabel = NSLocalizedString("Need help understanding your bill?", comment: "")
        viewBillButton.accessibilityLabel = NSLocalizedString("PDF, View bill", comment: "")
        activityButton.accessibilityLabel = NSLocalizedString("Activity", comment: "")
        walletButton.accessibilityLabel = NSLocalizedString("My Wallet", comment: "")
        
        viewModel.autoPayButtonText.map { $0?.string }.drive(autoPayButton.rx.accessibilityLabel).disposed(by: bag)
        
        viewModel.paperlessButtonText
            .map { $0?.string.replacingOccurrences(of: "eBill", with: "e-bill") }
            .drive(paperlessButton.rx.accessibilityLabel)
            .disposed(by: bag)
        
        viewModel.budgetButtonText.map { $0?.string }.drive(budgetButton.rx.accessibilityLabel).disposed(by: bag)
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
            vc.viewModel.isCurrent = true
        } else if let vc = segue.destination as? BGEAutoPayViewController {
            vc.delegate = self
            vc.accountDetail = viewModel.currentAccountDetail.value!
        } else if let vc = segue.destination as? AutoPayViewController {
            vc.delegate = self
            vc.accountDetail = viewModel.currentAccountDetail.value!
        } else if let vc = segue.destination as? BillingHistoryViewController {
            vc.accountDetail = viewModel.currentAccountDetail.value!
        }
    }

    func showDelayedToast(withMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
    }
    
    deinit {
        dLog()
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
        Analytics().logScreenView(AnalyticsPageView.BudgetBillEnrollComplete.rawValue)
    }

    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController) {
        viewModel.fetchAccountDetail(isRefresh: false)
        showDelayedToast(withMessage: NSLocalizedString("Unenrolled from Budget Billing", comment: ""))
        Analytics().logScreenView(AnalyticsPageView.BudgetBillUnEnrollOffer.rawValue)
    }
}

extension BillViewController: PaperlessEBillViewControllerDelegate {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus) {
        viewModel.fetchAccountDetail(isRefresh: false)
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
        viewModel.fetchAccountDetail(isRefresh: false)
        let message = enrolled ? NSLocalizedString("Enrolled in AutoPay", comment: ""): NSLocalizedString("Unenrolled from AutoPay", comment: "")
        showDelayedToast(withMessage: message)
        
        if(enrolled) {
            Analytics().logScreenView(AnalyticsPageView.AutoPayEnrollComplete.rawValue)
        } else {
            Analytics().logScreenView(AnalyticsPageView.AutoPayUnenrollComplete.rawValue)
        }
    }

}

extension BillViewController: BGEAutoPayViewControllerDelegate {
    
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String) {
        viewModel.fetchAccountDetail(isRefresh: false)
        showDelayedToast(withMessage: message)
    }
}
