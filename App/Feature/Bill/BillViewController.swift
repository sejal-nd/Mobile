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
import SafariServices

class BillViewController: AccountPickerViewController {
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet weak var maintenanceModeView: MaintenanceModeView!
    
    @IBOutlet weak var mainLoadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var topView: UIView!

    @IBOutlet weak var prepaidBannerButton: ButtonControl!
    @IBOutlet weak var prepaidHeaderLabel: UILabel!
    @IBOutlet weak var prepaidDetailLabel: UILabel!
    
    @IBOutlet weak var alertBannerView: BillAlertBannerView!
    
    @IBOutlet weak var billCardView: UIView!
    
    @IBOutlet weak var multipremiseHeaderView: UIView!
    @IBOutlet weak var multipremiseHeaderLabel: UILabel!
    
    @IBOutlet weak var totalAmountView: UIView!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var totalAmountDescriptionLabel: UILabel!
    @IBOutlet weak var totalAmountTooltipButton: UIButton!
    
    @IBOutlet weak var billLedgerView: UIView!
    
    @IBOutlet weak var pastDueCurrentBillBox: UIView!
	// Past Due
    @IBOutlet weak var pastDueView: UIView!
    @IBOutlet weak var pastDueLabel: UILabel!
    @IBOutlet weak var pastDueDateLabel: UILabel!
    @IBOutlet weak var pastDueAmountLabel: UILabel!
    @IBOutlet weak var pastDueDividerLine: UIView!
    // Current Bill
    @IBOutlet weak var currentBillView: UIView!
    @IBOutlet weak var currentBillLabel: UILabel!
    @IBOutlet weak var currentBillDateLabel: UILabel!
    @IBOutlet weak var currentBillAmountLabel: UILabel!

    // Payment Received
    @IBOutlet weak var paymentReceivedView: UIView!
    @IBOutlet weak var paymentReceivedLabel: UILabel!
    @IBOutlet weak var paymentReceivedDateLabel: UILabel!
    @IBOutlet weak var paymentReceivedAmountLabel: UILabel!

    @IBOutlet weak var pendingPaymentRemainingBalanceBox: UIView!
	// Payments
	@IBOutlet weak var pendingPaymentView: UIView!
    @IBOutlet weak var pendingPaymentLabel: UILabel!
    @IBOutlet weak var pendingPaymentAmountLabel: UILabel!
    @IBOutlet weak var pendingPaymentDividerLine: UIView!
	// Remaining Balance Due
	@IBOutlet weak var remainingBalanceDueView: UIView!
	@IBOutlet weak var remainingBalanceDueLabel: UILabel!
	@IBOutlet weak var remainingBalanceDueAmountLabel: UILabel!
    
    // Catch Up Disclaimer
    @IBOutlet weak var catchUpDisclaimerView: UIView!
    @IBOutlet weak var catchUpDisclaimerLabel: UILabel!
    
    @IBOutlet weak var creditScenarioView: UIView!
    @IBOutlet weak var creditScenarioTitleLabel: UILabel!
    @IBOutlet weak var creditScenarioAmountLabel: UILabel!
    
    @IBOutlet weak var billNotReadyView: UIView!
    @IBOutlet weak var billNotReadyLabel: UILabel!
    
    @IBOutlet weak var viewBillButton: ButtonControl!
    @IBOutlet weak var viewBillLabel: UILabel!

    @IBOutlet weak var makeAPaymentButton: PrimaryButton!
    
	@IBOutlet weak var billPaidFakeButtonView: UIView!
    @IBOutlet weak var billPaidLabel: UILabel!
    
    @IBOutlet weak var makeAPaymentStatusLabel: UILabel!
    @IBOutlet weak var makeAPaymentStatusButton: ButtonControl!
    
    @IBOutlet weak var billBreakdownButton: ButtonControl!
    @IBOutlet weak var billBreakdownLabel: UILabel!

    @IBOutlet weak var activityButton: ButtonControl!
    @IBOutlet weak var activityButtonLabel: UILabel!
    
    @IBOutlet weak var walletButton: ButtonControl!
    @IBOutlet weak var walletButtonLabel: UILabel!
    
    // Usage Trends
    @IBOutlet weak var usageBillImpactView: UIView!
    @IBOutlet weak var usageBillImpactCardView: UIView!
    @IBOutlet weak var usageBillImpactLoadingView: UIView!
    @IBOutlet weak var usageBillImpactErrorView: UIView!
    @IBOutlet weak var usageBillImpactErrorLabel: UILabel!
    @IBOutlet weak var usageBillImpactEmptyStateView: UIView!
    @IBOutlet weak var usageBillImpactEmptyStateLabel: UILabel!
    @IBOutlet weak var usageBillImpactContentView: BillImpactView!
    
    // Billing Options
    @IBOutlet weak var billingOptionsView: UIView!
    @IBOutlet weak var billingOptionsLabel: UILabel!
    
    @IBOutlet weak var paperlessButton: ButtonControl!
    @IBOutlet weak var paperlessEnrolledView: UIView!
    @IBOutlet weak var paperlessTitleLabel: UILabel!
    @IBOutlet weak var paperlessDetailLabel: UILabel!

    @IBOutlet weak var autoPayButton: ButtonControl!
    @IBOutlet weak var autoPayEnrolledView: UIView!
    @IBOutlet weak var autoPayTitleLabel: UILabel!
    @IBOutlet weak var autoPayDetailLabel: UILabel!
    
    @IBOutlet weak var budgetButton: ButtonControl!
    @IBOutlet weak var budgetEnrolledView: UIView!
    @IBOutlet weak var budgetTitleLabel: UILabel!
    @IBOutlet weak var budgetDetailLabel: UILabel!
    
    @IBOutlet weak var prepaidView: UIView!
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var genericErrorView: UIView!
    @IBOutlet weak var genericErrorLabel: UILabel!
    @IBOutlet weak var accountDisallowView: UIView!
    
    @IBOutlet weak var assistanceView: UIView!
    @IBOutlet weak var assistanceViewSeparator: UIView!
    @IBOutlet weak var titleAssistanceProgram: UILabel!
    @IBOutlet weak var descriptionAssistanceProgram: UILabel!
    @IBOutlet weak var assistanceCTA: UIButton!
    
    @IBOutlet var assistanceViewSepartors: [UIView]!
    private let cornerRadius: CGFloat = 4.0
    
    var refreshControl: UIRefreshControl?
    
    let viewModel = BillViewModel()

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
        
        NotificationCenter.default.rx.notification(.didRecievePaymentConfirmation, object: nil)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self else { return }
                self.viewModel.fetchAccountDetail(isRefresh: true)
            }).disposed(by: bag)
        
        usageBillImpactContentView.configure(withViewModel: viewModel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseUtility.logScreenView(.BillView(className: self.className))
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AppRating.present()
        
        // Bug was found when initially loading the Bill tab with no network. You could pull the scrollView down
        // to begin the refresh process, but would not be able to pull it down all the way to trigger the refresh.
        refreshControl?.removeFromSuperview()
        refreshControl = nil
        scrollView!.alwaysBounceVertical = false
        
        // only enable refresh if the accounts list has loaded
        if !accountPicker.accounts.isEmpty {
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
        self.scrollView!.insertSubview(refreshControl, at: 0)
        self.scrollView!.alwaysBounceVertical = true
    }
    
    @objc func onPullToRefresh() {
        viewModel.fetchAccountDetail(isRefresh: true)
    }
        
    func styleViews() {
        view.backgroundColor = .softGray
        assistanceViewSepartors.map{($0.backgroundColor = UIColor.accentGray)}
        titleAssistanceProgram.font = SystemFont.bold.of(textStyle: .caption1)
        titleAssistanceProgram.textColor = .deepGray
        if assistanceCTA.titleLabel?.text == "Reinstate Payment Arrangement" {
            self.titleAssistanceProgram.font = SystemFont.regular.of(textStyle: .caption1)
            
        } else {

        descriptionAssistanceProgram.font = SystemFont.regular.of(textStyle: .caption1)
        }
        descriptionAssistanceProgram.textColor = .deepGray
        assistanceCTA.setTitleColor(.actionBlue, for: .normal)
        assistanceCTA.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        prepaidHeaderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        prepaidDetailLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        prepaidBannerButton.layer.cornerRadius = 10
        if let header = prepaidHeaderLabel.text, let detail = prepaidDetailLabel.text {
            prepaidBannerButton.accessibilityLabel = "\(header). \(detail)"
        }
        
        billCardView.layer.cornerRadius = 10
        billCardView.layer.borderColor = UIColor.accentGray.cgColor
        billCardView.layer.borderWidth = 1
        
        multipremiseHeaderView.layer.borderColor = UIColor.accentGray.cgColor
        multipremiseHeaderView.layer.borderWidth = 1
        multipremiseHeaderLabel.textColor = .deepGray
        multipremiseHeaderLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        multipremiseHeaderLabel.text = NSLocalizedString("Multi-Premise Bill", comment: "")
        
        totalAmountLabel.textColor = .deepGray
        totalAmountLabel.font = OpenSans.semibold.of(textStyle: .largeTitle)

        totalAmountDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        pastDueCurrentBillBox.layer.borderColor = UIColor.accentGray.cgColor
        pastDueCurrentBillBox.layer.borderWidth = 1
        
        pastDueLabel.textColor = .deepGray
        pastDueLabel.font = SystemFont.regular.of(textStyle: .footnote)
        pastDueDateLabel.font = SystemFont.regular.of(textStyle: .caption1)
        pastDueAmountLabel.textColor = .deepGray
        pastDueAmountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        pastDueDividerLine.backgroundColor = .accentGray
        
        currentBillLabel.textColor = .deepGray
        currentBillLabel.font = SystemFont.regular.of(textStyle: .footnote)
        currentBillDateLabel.textColor = .middleGray
        currentBillDateLabel.font = SystemFont.regular.of(textStyle: .caption1)
        currentBillAmountLabel.textColor = .deepGray
        currentBillAmountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        paymentReceivedView.layer.borderColor = UIColor.accentGray.cgColor
        paymentReceivedView.layer.borderWidth = 1
        
        paymentReceivedLabel.textColor = .deepGray
        paymentReceivedLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentReceivedDateLabel.textColor = .middleGray
        paymentReceivedDateLabel.font = SystemFont.regular.of(textStyle: .caption1)
        paymentReceivedAmountLabel.textColor = .successGreenText
        paymentReceivedAmountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        pendingPaymentRemainingBalanceBox.layer.borderColor = UIColor.accentGray.cgColor
        pendingPaymentRemainingBalanceBox.layer.borderWidth = 1
        
        pendingPaymentLabel.textColor = .deepGray
        pendingPaymentLabel.font = SystemFont.italic.of(textStyle: .footnote)
        pendingPaymentAmountLabel.textColor = .middleGray
        pendingPaymentAmountLabel.font = OpenSans.semiboldItalic.of(textStyle: .footnote)
        pendingPaymentDividerLine.backgroundColor = .accentGray
        
        remainingBalanceDueLabel.textColor = .deepGray
        remainingBalanceDueLabel.font = SystemFont.regular.of(textStyle: .footnote)
        remainingBalanceDueAmountLabel.textColor = .deepGray
        remainingBalanceDueAmountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        catchUpDisclaimerLabel.textColor = .deepGray
        catchUpDisclaimerLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        creditScenarioTitleLabel.textColor = .deepGray
        creditScenarioTitleLabel.font = OpenSans.regular.of(textStyle: .callout)
        creditScenarioTitleLabel.text = NSLocalizedString("No Amount Due - Credit Balance", comment: "")
        creditScenarioAmountLabel.textColor = .deepGray
        creditScenarioAmountLabel.font = OpenSans.semibold.of(textStyle: .largeTitle)
        
        billNotReadyLabel.textColor = .deepGray
        billNotReadyLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        billNotReadyLabel.text = NSLocalizedString("Once you receive your bill, details about your charges will appear here.", comment: "")
        
        viewBillButton.layer.cornerRadius = viewBillButton.frame.size.height / 2
        viewBillButton.layer.borderColor = UIColor.accentGray.cgColor
        viewBillButton.layer.borderWidth = 1
        viewBillButton.backgroundColorOnPress = .softGray
        viewBillLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        
        billPaidFakeButtonView.backgroundColor = .accentGray
        billPaidFakeButtonView.layer.cornerRadius = 27.5
        billPaidFakeButtonView.isAccessibilityElement = true
        billPaidFakeButtonView.accessibilityLabel = NSLocalizedString("Bill Paid, dimmed, button", comment: "")
        
        billPaidLabel.textColor = UIColor.deepGray.withAlphaComponent(0.5)
        billPaidLabel.font = SystemFont.semibold.of(textStyle: .headline)
                
        billBreakdownButton.backgroundColorOnPress = .softGray
        billBreakdownLabel.textColor = .deepGray
        billBreakdownLabel.font = SystemFont.medium.of(textStyle: .callout)
        
        activityButton.backgroundColorOnPress = .softGray
        activityButtonLabel.textColor = .deepGray
        activityButtonLabel.font = SystemFont.medium.of(textStyle: .callout)
        
        walletButton.backgroundColorOnPress = .softGray
        walletButtonLabel.textColor = .deepGray
        walletButtonLabel.font = SystemFont.medium.of(textStyle: .callout)
        
        usageBillImpactCardView.layer.cornerRadius = 10
        usageBillImpactCardView.layer.borderColor = UIColor.accentGray.cgColor
        usageBillImpactCardView.layer.borderWidth = 1
        
        usageBillImpactEmptyStateLabel.textColor = .deepGray
        usageBillImpactEmptyStateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        usageBillImpactEmptyStateLabel.text = NSLocalizedString("After a few bill cycles, insights about your bill will be available here.", comment: "")
        
        usageBillImpactErrorLabel.textColor = .deepGray
        usageBillImpactErrorLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        usageBillImpactErrorLabel.text = NSLocalizedString("Bill trends could not be retrieved at this time. Please try again later.", comment: "")
        
        billingOptionsLabel.textColor = .deepGray
        billingOptionsLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        paperlessButton.layer.cornerRadius = 10
        paperlessButton.layer.borderColor = UIColor.accentGray.cgColor
        paperlessButton.layer.borderWidth = 1
        paperlessTitleLabel.textColor = .deepGray
        paperlessTitleLabel.font = OpenSans.regular.of(textStyle: .callout)
        paperlessDetailLabel.textColor = .deepGray
        paperlessDetailLabel.font = SystemFont.regular.of(textStyle: .caption1)
        paperlessEnrolledView.layer.cornerRadius = 7.5
        paperlessEnrolledView.layer.borderColor = UIColor.successGreenText.cgColor
        paperlessEnrolledView.layer.borderWidth = 1
        
        autoPayButton.layer.cornerRadius = 10
        autoPayButton.layer.borderColor = UIColor.accentGray.cgColor
        autoPayButton.layer.borderWidth = 1
        autoPayTitleLabel.textColor = .deepGray
        autoPayTitleLabel.font = OpenSans.regular.of(textStyle: .callout)
        autoPayDetailLabel.textColor = .deepGray
        autoPayDetailLabel.font = SystemFont.regular.of(textStyle: .caption1)
        autoPayEnrolledView.layer.cornerRadius = 7.5
        autoPayEnrolledView.layer.borderColor = UIColor.successGreenText.cgColor
        autoPayEnrolledView.layer.borderWidth = 1
        
        budgetButton.layer.cornerRadius = 10
        budgetButton.layer.borderColor = UIColor.accentGray.cgColor
        budgetButton.layer.borderWidth = 1
        budgetTitleLabel.textColor = .deepGray
        budgetTitleLabel.font = OpenSans.regular.of(textStyle: .callout)
        budgetDetailLabel.textColor = .deepGray
        budgetDetailLabel.font = SystemFont.regular.of(textStyle: .caption1)
        budgetEnrolledView.layer.cornerRadius = 7.5
        budgetEnrolledView.layer.borderColor = UIColor.successGreenText.cgColor
        budgetEnrolledView.layer.borderWidth = 1
        
        genericErrorLabel.textColor = .deepGray
        genericErrorLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        genericErrorLabel.text = NSLocalizedString("Billing data could not be retrieved at this time. Please try again later.", comment: "")
    }
    
    func bindViews() {
		bindLoadingStates()
		bindViewHiding()
		bindViewContent()
    }
    
    func showLoadedState() {
        mainLoadingIndicator.isHidden = true
        topView.isHidden = false
        errorView.isHidden = true
        prepaidView.isHidden = true
        scrollView?.isHidden = false
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        
        // Hide the entire billingOptionsView if none of buttons will be shown
        Driver.combineLatest(viewModel.showAutoPay, viewModel.showBudget, viewModel.showPaperless)
            .asObservable().single()
            .subscribe(onNext: { [weak self] in
                self?.billingOptionsView.isHidden = !$0 && !$1 && !$2
            }).disposed(by: bag)
        enableRefresh()
    }
    
    func showUsageBillImpactLoading() {
        usageBillImpactView.isHidden = false
        usageBillImpactLoadingView.isHidden = false
        usageBillImpactErrorView.isHidden = true
        usageBillImpactEmptyStateView.isHidden = true
        usageBillImpactContentView.isHidden = true
    }
    
    func showUsageBillImpactError() {
        usageBillImpactView.isHidden = false
        usageBillImpactLoadingView.isHidden = true
        usageBillImpactErrorView.isHidden = false
        usageBillImpactEmptyStateView.isHidden = true
        usageBillImpactContentView.isHidden = true
    }
    
    func showUsageBillImpactEmptyState() {
        usageBillImpactView.isHidden = false
        usageBillImpactLoadingView.isHidden = true
        usageBillImpactErrorView.isHidden = true
        usageBillImpactEmptyStateView.isHidden = false
        usageBillImpactContentView.isHidden = true
    }
    
    func showUsageBillImpactContent() {
        usageBillImpactView.isHidden = false
        usageBillImpactLoadingView.isHidden = true
        usageBillImpactErrorView.isHidden = true
        usageBillImpactEmptyStateView.isHidden = true
        usageBillImpactContentView.isHidden = false
        usageBillImpactContentView.setInnerLoadingState(false)
    }
    
    func showErrorState(error: NetworkingError?) {
        if error == .noNetwork {
            scrollView?.isHidden = true
            noNetworkConnectionView.isHidden = false
        } else {
            scrollView?.isHidden = false
            noNetworkConnectionView.isHidden = true
        }
        
        mainLoadingIndicator.isHidden = true
        topView.isHidden = true
        billingOptionsView.isHidden = true
        errorView.isHidden = false
        prepaidView.isHidden = true
        maintenanceModeView.isHidden = true
        
        if error == .blockAccount {
            genericErrorView.isHidden = true
            accountDisallowView.isHidden = false
        } else {
            genericErrorView.isHidden = false
            accountDisallowView.isHidden = true
        }
        
        enableRefresh()
    }
    
    func showPrepaidState() {
        mainLoadingIndicator.isHidden = true
        topView.isHidden = true
        billingOptionsView.isHidden = true
        errorView.isHidden = true
        prepaidView.isHidden = false
        scrollView?.isHidden = false
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        enableRefresh()
    }
    
    func showMaintenanceModeState() {
        maintenanceModeView.isHidden = false
        scrollView?.isHidden = true
        noNetworkConnectionView.isHidden = true
        mainLoadingIndicator.isHidden = true
        topView.isHidden = true
        billingOptionsView.isHidden = true
        errorView.isHidden = true
        prepaidView.isHidden = true
        enableRefresh()
    }
    
    func showSwitchingAccountState() {
        scrollView?.isHidden = false
        noNetworkConnectionView.isHidden = true
        mainLoadingIndicator.isHidden = false
        topView.isHidden = true
        usageBillImpactView.isHidden = true
        billingOptionsView.isHidden = true
        errorView.isHidden = true
        prepaidView.isHidden = true

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
        viewModel.showUsageBillImpactFullLoading.drive(onNext: { [weak self] in self?.showUsageBillImpactLoading() }).disposed(by: bag)
        viewModel.showUsageBillImpactFullError.drive(onNext: { [weak self] in self?.showUsageBillImpactError() }).disposed(by: bag)
        viewModel.showUsageBillImpactEmptyState.drive(onNext: { [weak self] in self?.showUsageBillImpactEmptyState() }).disposed(by: bag)
        viewModel.showUsageBillImpactContent.drive(onNext: { [weak self] in self?.showUsageBillImpactContent() }).disposed(by: bag)
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
        
        viewModel.showMultipremiseHeader.not().drive(multipremiseHeaderView.rx.isHidden).disposed(by: bag)

        totalAmountTooltipButton.isHidden = !viewModel.showAmountDueTooltip
        
        viewModel.showTotalAmountAndLedger.not().drive(totalAmountView.rx.isHidden).disposed(by: bag)
        viewModel.showTotalAmountAndLedger.not().drive(billLedgerView.rx.isHidden).disposed(by: bag)
        
        viewModel.showPastDue.not().drive(pastDueView.rx.isHidden).disposed(by: bag)
        viewModel.showCurrentBill.not().drive(currentBillView.rx.isHidden).disposed(by: bag)
        Driver.combineLatest(viewModel.showPastDue, viewModel.showCurrentBill).drive(onNext: { [weak self] in
            self?.pastDueCurrentBillBox.isHidden = !$0 && !$1
            self?.pastDueDividerLine.isHidden = !$0 || !$1
        }).disposed(by: bag)
        
        viewModel.showPaymentReceived.not().drive(paymentReceivedView.rx.isHidden).disposed(by: bag)
        
		viewModel.showPendingPayment.not().drive(pendingPaymentView.rx.isHidden).disposed(by: bag)
		viewModel.showRemainingBalanceDue.not().drive(remainingBalanceDueView.rx.isHidden).disposed(by: bag)
        Driver.combineLatest(viewModel.showPendingPayment, viewModel.showRemainingBalanceDue).drive(onNext: { [weak self] in
            self?.pendingPaymentRemainingBalanceBox.isHidden = !$0 && !$1
            self?.pendingPaymentDividerLine.isHidden = !$0 || !$1
        }).disposed(by: bag)
        
        viewModel.showCatchUpDisclaimer.not().drive(catchUpDisclaimerView.rx.isHidden).disposed(by: bag)
        
        viewModel.showCreditScenario.not().drive(creditScenarioView.rx.isHidden).disposed(by: bag)
        
        viewModel.showBillNotReady.not().drive(billNotReadyView.rx.isHidden).disposed(by: bag)
        viewModel.showBillNotReady.drive(viewBillButton.rx.isHidden).disposed(by: bag)

		viewModel.showMakeAPaymentButton.not().drive(makeAPaymentButton.rx.isHidden).disposed(by: bag)
		viewModel.showBillPaidFakeButton.not().drive(billPaidFakeButtonView.rx.isHidden).disposed(by: bag)
        viewModel.showPaymentStatusText.not().drive(makeAPaymentStatusButton.rx.isHidden).disposed(by: bag)
        viewModel.hasBillBreakdownData.not().drive(billBreakdownButton.rx.isHidden).disposed(by: bag)

        viewModel.showAutoPay.not().drive(autoPayButton.rx.isHidden).disposed(by: bag)
		viewModel.showPaperless.not().drive(paperlessButton.rx.isHidden).disposed(by: bag)
		viewModel.showBudget.not().drive(budgetButton.rx.isHidden).disposed(by: bag)
	}

    func bindViewContent() {
        viewModel.alertBannerText.drive(alertBannerView.label.rx.text).disposed(by: bag)
        viewModel.alertBannerA11yText.drive(alertBannerView.label.rx.accessibilityLabel).disposed(by: bag)

		viewModel.totalAmountText.drive(totalAmountLabel.rx.text).disposed(by: bag)
        viewModel.totalAmountText.drive(creditScenarioAmountLabel.rx.text).disposed(by: bag)
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
        viewModel.makePaymentStatusTextTapRouting.drive(onNext: { [weak self] route in
            if route == .nowhere {
                self?.makeAPaymentStatusLabel.textColor = .deepGray
                self?.makeAPaymentStatusLabel.font = OpenSans.italic.of(textStyle: .caption1)
            } else {
                self?.makeAPaymentStatusLabel.textColor = .actionBlue
                self?.makeAPaymentStatusLabel.font = OpenSans.semibold.of(textStyle: .caption1)
            }
        }).disposed(by: bag)

        viewModel.showPaperlessEnrolledView.not().drive(paperlessEnrolledView.rx.isHidden).disposed(by: bag)
        viewModel.showAutoPayEnrolledView.not().drive(autoPayEnrolledView.rx.isHidden).disposed(by: bag)
        viewModel.autoPayDetailLabelText.drive(autoPayDetailLabel.rx.attributedText).disposed(by: bag)
        viewModel.showBudgetEnrolledView.not().drive(budgetEnrolledView.rx.isHidden).disposed(by: bag)
        
        viewModel.paymentAssistanceValues.drive(onNext: { [weak self] description in
            guard let self = self else { return }
            if description == nil {
                self.assistanceView.isHidden = true
            }
            DispatchQueue.main.async {
                if description?.ctaType == "Reinstate Payment Arrangement" {
                    self.titleAssistanceProgram.font = SystemFont.regular.of(textStyle: .caption1)
                }

            }
            self.titleAssistanceProgram.text = description?.title
            self.descriptionAssistanceProgram.text = description?.description
            self.assistanceCTA.setTitle(description?.ctaType, for: .normal)
        }).disposed(by: bag)
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
                GoogleAnalytics.log(event: .prePaidPending)
                UIApplication.shared.openUrlIfCan(self?.viewModel.prepaidUrl)
            })
            .disposed(by: bag)
        
        totalAmountTooltipButton.rx.tap.asDriver()
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
                if Configuration.shared.opco == .comEd &&
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
                    
                    FirebaseUtility.logEvent(.bill(parameters: [.bill_view_pdf]))
                    
                    self.performSegue(withIdentifier: "viewBillSegue", sender: accountDetail)
                }
                
                GoogleAnalytics.log(event: .billViewCurrentOfferComplete)
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
        
        usageBillImpactContentView.tooltipButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] _ in
                let alert = InfoAlertController(title: NSLocalizedString("What are these amounts  based on?", comment: ""),
                                                message: NSLocalizedString("The amounts shown are usage-related charges and may not include credits and other adjustments. Amounts for Budget Billing customers are based on actual usage in the period, not on your monthly budget payment.", comment: ""))
                self?.tabBarController?.present(alert, animated: true)
            }).disposed(by: bag)

		paperlessButton.rx.touchUpInside.asDriver()
			.withLatestFrom(viewModel.currentAccountDetail)
			.drive(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                if Configuration.shared.opco.isPHI {
                    self.performSegue(withIdentifier: "paperlessEBillSegue", sender: accountDetail)
                } else {
                    if !accountDetail.isResidential && Configuration.shared.opco != .bge {
                        self.performSegue(withIdentifier: "paperlessEBillCommercialSegue", sender: accountDetail)
                    } else {
                        self.performSegue(withIdentifier: "paperlessEBillSegue", sender: accountDetail)
                    }
                }
			})
			.disposed(by: bag)

        budgetButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.currentAccountDetail)
            .drive(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                if accountDetail.isBudgetBillEligible || accountDetail.isBudgetBill {
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
                                           viewModel.showMakeAPaymentButton.asObservable())
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
                    let storyboard = UIStoryboard(name: "TapToPay", bundle: nil)
                    guard let vc = storyboard.instantiateViewController(withIdentifier: "TapToPayReviewPaymentViewController") as? TapToPayReviewPaymentViewController else { return }
                    vc.accountDetail = accountDetail
                    let newNavController = LargeTitleNavigationController(rootViewController: vc)
                    newNavController.modalPresentationStyle = .fullScreen
                    
                    FirebaseUtility.logEvent(.makePaymentStart)
                    self.present(newNavController, animated: true, completion: nil)
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
        
        assistanceCTA.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] _ in
                guard let assistanceType = self?.viewModel.mobileAssistanceType else { return }
                switch assistanceType {
                case .dde:
                    FirebaseUtility.logEvent(.bill(parameters: [.extension_cta]))
                case .dpa:
                    FirebaseUtility.logEvent(.bill(parameters: [.dpa_cta]))
                case .dpaReintate:
                    FirebaseUtility.logEvent(.bill(parameters: [.reinstate_cta]))
                case .none:
                    FirebaseUtility.logEvent(.bill(parameters: [.assistance_cta]))
                }
                let safariVc = SFSafariViewController.createWithCustomStyle(url: URL(string: self?.viewModel.mobileAssistanceURL.value ?? "")!)
                self?.present(safariVc, animated: true, completion: nil)
                
            }).disposed(by: bag)
    }
    
    func navigateToAutoPay(accountDetail: AccountDetail) {
        if Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI  {
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
        pastDueView.accessibilityElements = [pastDueLabel, pastDueDateLabel, pastDueAmountLabel] as [UIView]
        currentBillView.accessibilityElements = [currentBillLabel, currentBillDateLabel, currentBillAmountLabel] as [UIView]
        paymentReceivedView.accessibilityElements = [paymentReceivedLabel, paymentReceivedDateLabel, paymentReceivedAmountLabel] as [UIView]
        
        viewModel.showPaperlessEnrolledView.drive(onNext: { [weak self] show in
            self?.paperlessButton.accessibilityLabel = String.localizedStringWithFormat("Paperless e-bill. Eliminate your paper bill and receive it online.%@", show ? "Enrolled" : "")
        }).disposed(by: bag)
        
        viewModel.autoPayAccessibilityLabel.drive(autoPayButton.rx.accessibilityLabel).disposed(by: bag)
        
        viewModel.showBudgetEnrolledView.drive(onNext: { [weak self] show in
            self?.budgetButton.accessibilityLabel = String.localizedStringWithFormat("Budget Billing. Enjoy predictable bills by spreading costs evenly month to month.%@", show ? "Enrolled" : "")
        }).disposed(by: bag)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case let (vc as BudgetBillingViewController, accountDetail as AccountDetail):
            vc.delegate = self
            vc.accountDetail = accountDetail
        case let (vc as PaperlessEBillViewController, accountDetail as AccountDetail):
            vc.delegate = self
            vc.accountDetail = accountDetail
        case let (vc as ViewBillViewController, accountDetail as AccountDetail):
            vc.viewModel.billDate = accountDetail.billingInfo.billDate
            vc.viewModel.documentID = accountDetail.billingInfo.documentID
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

    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: UIViewController, averageMonthlyBill: String?) {
        switch Configuration.shared.opco {
        case .bge:
            let textFormat = NSLocalizedString("Enrolled in Budget Billing - your monthly rate is %@", comment: "")
            showDelayedToast(withMessage: String(format: textFormat, averageMonthlyBill ?? "--"))
        case .comEd, .peco:
            showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
        case .pepco:
            showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
        case .ace:
            showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
        case .delmarva:
            showDelayedToast(withMessage: NSLocalizedString("Enrolled in Budget Billing", comment: ""))
        }
        GoogleAnalytics.log(event: .budgetBillEnrollComplete)
        viewModel.fetchAccountDetail(isRefresh: true)
    }

    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: UIViewController) {
        showDelayedToast(withMessage: NSLocalizedString("Unenrolled from Budget Billing", comment: ""))
        GoogleAnalytics.log(event: .budgetBillUnEnrollComplete)
        viewModel.fetchAccountDetail(isRefresh: true)
    }
}

extension BillViewController: PaperlessEBillViewControllerDelegate {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus) {
        var toastMessage: String
        switch didChangeStatus {
        case .enroll:
            toastMessage = Configuration.shared.opco.isPHI ? NSLocalizedString("Paperless eBill changes saved", comment: "") : NSLocalizedString("Enrolled in Paperless eBill", comment: "")
            showDelayedToast(withMessage: toastMessage)
        case .unenroll:
            toastMessage = Configuration.shared.opco.isPHI ? NSLocalizedString("Paperless eBill changes saved", comment: "") : NSLocalizedString("Unenrolled from Paperless eBill", comment: "")
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

    func autoPayViewController(_ autoPayViewController: UIViewController, enrolled: Bool) {
        let message = enrolled ? NSLocalizedString("Enrolled in AutoPay", comment: ""): NSLocalizedString("Unenrolled from AutoPay", comment: "")
        showDelayedToast(withMessage: message)
        
        if enrolled {
            GoogleAnalytics.log(event: .autoPayEnrollComplete)
        } else {
            GoogleAnalytics.log(event: .autoPayUnenrollComplete)
        }
    }

}

extension BillViewController: BGEAutoPayViewControllerDelegate {
    
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String) {
        showDelayedToast(withMessage: message)
    }
}
