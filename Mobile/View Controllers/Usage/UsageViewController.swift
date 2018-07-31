//
//  UsageViewController.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SafariServices

class UsageViewController: AccountPickerViewController {
    
    @IBOutlet private weak var backgroundScrollConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var switchAccountsLoadingIndicator: LoadingIndicator!
    @IBOutlet private weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var unavailableView: UnavailableView!
    @IBOutlet private weak var mainErrorView: UIView!
    @IBOutlet private weak var mainErrorLabel: UILabel! {
        didSet {
            mainErrorLabel.font = SystemFont.regular.of(textStyle: .headline)
            mainErrorLabel.textColor = .blackText
        }
    }
    
    @IBOutlet private weak var segmentControl: BillAnalysisSegmentedControl! {
        didSet {
            segmentControl.leftLabel.text = "Electric"
            segmentControl.rightLabel.text = "Gas"
        }
    }
    
    @IBOutlet private weak var compareBillTitlelabel: UILabel! {
        didSet {
            compareBillTitlelabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    @IBOutlet private weak var myUsageToolsLabel: UILabel! {
        didSet {
            myUsageToolsLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    @IBOutlet private weak var usageToolsStack: UIStackView!
    
    // Bill Graph
    @IBOutlet private weak var billGraphDetailContainer: UIView!
    @IBOutlet private weak var billGraphDetailView: UIView! {
        didSet {
            billGraphDetailView.layer.cornerRadius = 10
            billGraphDetailView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0.0, height: 2.0), radius: 4)
        }
    }
    
    @IBOutlet private weak var barGraphStackView: UIStackView!
    @IBOutlet private weak var barDescriptionTriangleImageView: UIImageView!
    @IBOutlet private weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var noDataContainerButton: ButtonControl!
    @IBOutlet private weak var noDataBarView: UIView!
    @IBOutlet private weak var noDataLabel: UILabel!
    @IBOutlet private weak var noDataDateLabel: UILabel!
    
    
    @IBOutlet private weak var previousContainerButton: ButtonControl!
    @IBOutlet private weak var previousBarView: UIView! {
        didSet {
            previousBarView.backgroundColor = .primaryColor
            previousBarView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet private weak var previousBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var previousDollarLabel: UILabel!
    
    @IBOutlet private weak var previousDateLabel: UILabel!
    
    @IBOutlet private weak var currentContainerButton: ButtonControl!
    @IBOutlet private weak var currentBarView: UIView! {
        didSet {
            currentBarView.backgroundColor = .primaryColor
            currentBarView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet private weak var currentBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var currentDollarLabel: UILabel!
    @IBOutlet private weak var currentDateLabel: UILabel!
    
    @IBOutlet private weak var projectedContainerButton: ButtonControl!
    @IBOutlet private weak var projectedBarImageView: UIImageView! {
        didSet {
            projectedBarImageView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet private weak var projectedBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var projectedDollarLabel: UILabel!
    @IBOutlet private weak var projectedDateLabel: UILabel!
    
    @IBOutlet private weak var projectionNotAvailableContainerButton: ButtonControl!
    @IBOutlet private weak var projectionNotAvailableBarView: UIView!
    @IBOutlet private weak var projectionNotAvailableUntilNextForecastLabel: UILabel!
    @IBOutlet private weak var projectedNotAvailableDateLabel: UILabel!
    @IBOutlet private weak var projectedNotAvailableDaysRemainingLabel: UILabel!
    
    @IBOutlet private weak var graphDetailDateLabel: UILabel! {
        didSet {
            graphDetailDateLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
            graphDetailDateLabel.textColor = .blackText
        }
    }
    
    @IBOutlet private weak var graphDetailTemperatureLabel: UILabel! {
        didSet {
            graphDetailTemperatureLabel.font = OpenSans.regular.of(textStyle: .footnote)
            graphDetailTemperatureLabel.textColor = .blackText
        }
    }
    
    @IBOutlet private weak var graphDetailDescriptionLabel: UILabel! {
        didSet {
            graphDetailDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
            graphDetailDescriptionLabel.textColor = .black
        }
    }
    
    @IBOutlet private weak var lastYearButton: UIButton! {
        didSet {
            lastYearButton.layer.cornerRadius = 16
            lastYearButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    
    @IBOutlet private weak var previousBillButton: UIButton! {
        didSet {
            previousBillButton.layer.cornerRadius = 16
            previousBillButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    
    @IBOutlet private weak var dropdownView: BillImpactDropdownView!
    
    @IBOutlet private weak var billComparisonLoadingIndicator: LoadingIndicator!
    @IBOutlet private weak var graphErrorLabel: UILabel! {
        didSet {
            graphErrorLabel.font = SystemFont.regular.of(textStyle: .headline)
            graphErrorLabel.textColor = .blackText
        }
    }
    
    var refreshControl: UIRefreshControl?
    
    let disposeBag = DisposeBag()
    
    let viewModel = UsageViewModel(accountService: ServiceFactory.createAccountService(), usageService: ServiceFactory.createUsageService())
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Account Picker
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        scrollView?.rx.contentOffset.asDriver()
            .map { min(0, $0.y) }
            .distinctUntilChanged()
            .drive(backgroundScrollConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        showSwitchAccountsLoadingState()
        barGraphPress(currentContainerButton)
        styleBarGraph()
        bindViewModel()
        dropdownView.configure(withViewModel: viewModel)
        
        accountPickerViewControllerWillAppear
            .subscribe(onNext: { [weak self] state in
                guard let this = self else { return }
                switch(state) {
                case .loadingAccounts:
                    this.setRefreshControlEnabled(enabled: false)
                case .readyToFetchData:
                    if AccountsStore.shared.currentAccount != this.accountPicker.currentAccount {
                        this.viewModel.fetchAllData()
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let dashedBorderColor = UIColor(red: 0, green: 80/255, blue: 125/255, alpha: 0.24)
        noDataBarView.addDashedBorder(color: dashedBorderColor)
        projectionNotAvailableBarView.addDashedBorder(color: dashedBorderColor)
        projectionNotAvailableBarView.layer.cornerRadius = 10
    }
    
    // MARK: - Actions
    
    @objc private func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            guard refreshControl == nil else { return }
            
            let rc = UIRefreshControl()
            
            rc.rx.controlEvent(.valueChanged)
                .subscribe(onNext: { [weak self] in self?.viewModel.fetchAllData() })
                .disposed(by: disposeBag)
            
            scrollView?.insertSubview(rc, at: 0)
            scrollView?.alwaysBounceVertical = true
            refreshControl = rc
        } else {
            refreshControl?.endRefreshing()
            refreshControl?.removeFromSuperview()
            refreshControl = nil
            scrollView?.alwaysBounceVertical = false
        }
    }
    
    @IBAction private func barGraphPress(_ sender: ButtonControl) {
        barDescriptionTriangleCenterXConstraint.isActive = false
        barDescriptionTriangleCenterXConstraint = barDescriptionTriangleImageView.centerXAnchor
            .constraint(equalTo: sender.centerXAnchor)
        barDescriptionTriangleCenterXConstraint.isActive = true
        
        viewModel.setBarSelected(tag: sender.tag)
    }
    
    // MARK: - Style Views
    
    private func styleBarGraph() {
        switch Environment.shared.opco {
        case .bge:
            projectedBarImageView.tintColor = UIColor(red: 0, green: 110/255, blue: 187/255, alpha: 1)
        case .comEd:
            projectedBarImageView.tintColor = UIColor(red: 0, green: 145/255, blue: 182/255, alpha: 1)
        case .peco:
            projectedBarImageView.tintColor = UIColor(red: 114/255, green: 184/255, blue: 101/255, alpha: 1)
        }
        
        // Bar Graph Text Colors
        noDataLabel.textColor = .deepGray
        noDataDateLabel.textColor = .deepGray
        previousDollarLabel.textColor = .deepGray
        previousDateLabel.textColor = .deepGray
        currentDollarLabel.textColor = .deepGray
        currentDateLabel.textColor = .deepGray
        projectedDollarLabel.textColor = .deepGray
        projectedDateLabel.textColor = .deepGray
        projectedNotAvailableDaysRemainingLabel.textColor = .actionBlue
        projectionNotAvailableUntilNextForecastLabel.textColor = .deepGray
        projectedNotAvailableDateLabel.textColor = .deepGray
        
        // Bar Graph Text Fonts
        noDataLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        viewModel.noDataLabelFont.drive(noDataDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousLabelFont.drive(previousDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousLabelFont.drive(previousDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousDollarLabelTextColor.drive(previousDollarLabel.rx.textColor).disposed(by: disposeBag)
        viewModel.currentLabelFont.drive(currentDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.currentLabelFont.drive(currentDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.currentDollarLabelTextColor.drive(currentDollarLabel.rx.textColor).disposed(by: disposeBag)
        viewModel.projectedLabelFont.drive(projectedDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.projectedLabelFont.drive(projectedDateLabel.rx.font).disposed(by: disposeBag)
        
        projectedNotAvailableDaysRemainingLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        projectionNotAvailableUntilNextForecastLabel.font = SystemFont.regular.of(textStyle: .footnote)
        viewModel.projectionNotAvailableLabelFont.drive(projectedNotAvailableDateLabel.rx.font).disposed(by: disposeBag)
    }
    
    
    // MARK: - Bind View Model
    
    private func bindViewModel() {
        bindDataFetching()
        bindViewStates()
        bindBillComparisonData()
        viewModel.usageTools
            .drive(onNext: { [weak self] in self?.updateUsageToolCards($0) })
            .disposed(by: disposeBag)
    }
    
    private func bindDataFetching() {
        Driver.merge(lastYearButton.rx.tap.asDriver().map(to: 0),
                     previousBillButton.rx.tap.asDriver().map(to: 1))
            .drive(onNext: { [weak self] index in
                guard let this = self else { return }
                this.showBillComparisonLoadingState()
                this.previousBillButton.isEnabled = index == 0
                this.lastYearButton.isEnabled = index == 1
                this.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = index
                Analytics.log(event: index == 0 ? .billLastYearToggle : .billPreviousToggle)
            })
            .disposed(by: disposeBag)
        
        RxNotifications.shared.accountDetailUpdated
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                self?.showSwitchAccountsLoadingState()
                self?.viewModel.fetchAllData()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindViewStates() {
        viewModel.endRefreshIng
            .drive(onNext: { [weak self] in
                self?.refreshControl?.endRefreshing()
                self?.setRefreshControlEnabled(enabled: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.showMainContents
            .drive(onNext: { [weak self] in self?.showMainContents() })
            .disposed(by: disposeBag)
        
        viewModel.showNoUsageDataState
            .drive(onNext: { [weak self] in self?.showNoUsageDataState() })
            .disposed(by: disposeBag)
        
        viewModel.showMainErrorState
            .drive(onNext: { [weak self] in self?.showMainErrorState() })
            .disposed(by: disposeBag)
        
        viewModel.showNoNetworkState
            .drive(onNext: { [weak self] in self?.showNoNetworkState() })
            .disposed(by: disposeBag)
        
        viewModel.showBillComparisonContents
            .drive(onNext: { [weak self] in self?.showBillComparisonContents()})
            .disposed(by: disposeBag)
        
        viewModel.showBillComparisonErrorState
            .drive(onNext: { [weak self] in self?.showBillComparisonErrorState() })
            .disposed(by: disposeBag)
        
        noNetworkConnectionView.reload.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                self?.showSwitchAccountsLoadingState()
                self?.viewModel.fetchAllData()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.didMaintenanceModeTurnOn)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.refreshControl?.endRefreshing()
                self?.scrollView!.alwaysBounceVertical = true
            })
            .disposed(by: disposeBag)
    }
    
    private func bindBillComparisonData() {
        // Segmented Control
        segmentControl.selectedIndex.asDriver()
            .do(onNext: { [weak self] _ in self?.showBillComparisonLoadingState() })
            .drive(viewModel.electricGasSelectedSegmentIndex)
            .disposed(by: disposeBag)
        
        viewModel.electricGasSelectedSegmentIndex.asObservable()
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { index in
                if index == 0 {
                    Analytics.log(event: .billElectricityToggle)
                } else {
                    Analytics.log(event: .billGasToggle)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.showElectricGasSegmentedControl.not().drive(segmentControl.rx.isHidden).disposed(by: disposeBag)
        viewModel.compareBillTitle.drive(compareBillTitlelabel.rx.text).disposed(by: disposeBag)
        
        // Update bar graph selection when the current selection is no longer available.
        Driver.combineLatest(viewModel.barGraphSelection.asDriver().distinctUntilChanged(),
                             viewModel.showProjectedBar.distinctUntilChanged(),
                             viewModel.noPreviousData.distinctUntilChanged(),
                             viewModel.showProjectionNotAvailableBar.distinctUntilChanged())
            .drive(onNext: { [weak self] barGraphSelection, showProjected, noPreviousData, showProjectionNotAvailableBar in
                guard let this = self else { return }
                
                switch barGraphSelection {
                case .noData:
                    if !noPreviousData {
                        this.barGraphPress(this.previousContainerButton)
                    }
                case .previous:
                    if noPreviousData {
                        this.barGraphPress(this.noDataContainerButton)
                    }
                case .current:
                    return // Current should always be available
                case .projected:
                    if !showProjected {
                        this.barGraphPress(this.currentContainerButton)
                    }
                case .projectionNotAvailable:
                    if !showProjectionNotAvailableBar {
                        if showProjected {
                            this.barGraphPress(this.projectedContainerButton)
                        } else {
                            this.barGraphPress(this.currentContainerButton)
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // Bar graph height constraints
        viewModel.previousBarHeightConstraintValue
            .drive(previousBarHeightConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        viewModel.currentBarHeightConstraintValue
            .drive(currentBarHeightConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        viewModel.projectedBarHeightConstraintValue
            .drive(projectedBarHeightConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        // Bar graph corner radius
        viewModel.previousBarHeightConstraintValue
            .map { min(10, $0/2) }
            .drive(previousBarView.rx.cornerRadius)
            .disposed(by: disposeBag)
        
        viewModel.currentBarHeightConstraintValue
            .map { min(10, $0/2) }
            .drive(currentBarView.rx.cornerRadius)
            .disposed(by: disposeBag)
        
        viewModel.projectedBarHeightConstraintValue
            .map { min(10, $0/2) }
            .drive(projectedBarImageView.rx.cornerRadius)
            .disposed(by: disposeBag)
        
        // Bar show/hide
        viewModel.noPreviousData.not().drive(noDataContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.drive(previousContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.showProjectedBar.not().drive(projectedContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.showProjectionNotAvailableBar.not().drive(projectionNotAvailableContainerButton.rx.isHidden).disposed(by: disposeBag)
        
        // Bar labels
        viewModel.noDataBarDateLabelText.drive(noDataDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.previousBarDollarLabelText.drive(previousDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.previousBarDateLabelText.drive(previousDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.currentBarDollarLabelText.drive(currentDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.currentBarDateLabelText.drive(currentDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDollarLabelText.drive(projectedDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDateLabelText.drive(projectedDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDateLabelText.drive(projectedNotAvailableDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionNotAvailableDaysRemainingText.drive(projectedNotAvailableDaysRemainingLabel.rx.text).disposed(by: disposeBag)
        
        // Bar accessibility
        viewModel.noDataBarA11yLabel.drive(noDataContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.previousBarA11yLabel.drive(previousContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.currentBarA11yLabel.drive(currentContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.projectedBarA11yLabel.drive(projectedContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.projectionNotAvailableA11yLabel.drive(projectionNotAvailableContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        Driver.combineLatest(viewModel.noPreviousData.asDriver(),
                             viewModel.showProjectedBar.asDriver(),
                             viewModel.showProjectionNotAvailableBar.asDriver())
            .drive(onNext: { [weak self] noPreviousData, showProjectedBar, showProjectionNotAvailableBar in
                guard let this = self else { return }
                
                var a11yElementArray: [ButtonControl] = []
                if noPreviousData {
                    a11yElementArray.append(this.noDataContainerButton)
                } else {
                    a11yElementArray.append(this.previousContainerButton)
                }
                a11yElementArray.append(this.currentContainerButton)
                if showProjectedBar {
                    a11yElementArray.append(this.projectedContainerButton)
                }
                if showProjectionNotAvailableBar {
                    a11yElementArray.append(this.projectionNotAvailableContainerButton)
                }
                
                this.barGraphStackView.accessibilityElements = a11yElementArray
            })
            .disposed(by: disposeBag)
        
        // Bar description labels
        viewModel.barDescriptionDateLabelText.drive(graphDetailDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionAvgTempLabelText.drive(graphDetailTemperatureLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionDetailLabelText.drive(graphDetailDescriptionLabel.rx.text).disposed(by: disposeBag)
    }
    
    // MARK: - Screen States
    
    private func showSwitchAccountsLoadingState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = false
        unavailableView.isHidden = true
        contentStack.isHidden = true
        mainErrorView.isHidden = true
        noNetworkConnectionView.isHidden = true
        showBillComparisonLoadingState()
    }
    
    private func showMainContents() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        contentStack.isHidden = false
        mainErrorView.isHidden = true
        noNetworkConnectionView.isHidden = true
    }
    
    private func showNoUsageDataState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = false
        contentStack.isHidden = true
        mainErrorView.isHidden = true
        noNetworkConnectionView.isHidden = true
    }
    
    private func showMainErrorState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        contentStack.isHidden = true
        mainErrorView.isHidden = false
        noNetworkConnectionView.isHidden = true
    }
    
    private func showNoNetworkState() {
        scrollView?.isHidden = true
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        contentStack.isHidden = true
        mainErrorView.isHidden = true
        noNetworkConnectionView.isHidden = false
    }
    
    private func showBillComparisonLoadingState() {
        billComparisonLoadingIndicator.isHidden = false
        barGraphStackView.isHidden = true
        billGraphDetailContainer.isHidden = true
        dropdownView.isHidden = true
        graphErrorLabel.isHidden = true
    }
    
    private func showBillComparisonContents() {
        billComparisonLoadingIndicator.isHidden = true
        barGraphStackView.isHidden = false
        billGraphDetailContainer.isHidden = false
        dropdownView.isHidden = false
        graphErrorLabel.isHidden = true
    }
    
    private func showBillComparisonErrorState() {
        billComparisonLoadingIndicator.isHidden = true
        barGraphStackView.isHidden = true
        billGraphDetailContainer.isHidden = true
        dropdownView.isHidden = true
        graphErrorLabel.isHidden = false
    }
    
    // MARK: - Usage Tool Cards
    
    func updateUsageToolCards(_ usageTools: [UsageTool]) {
        // Remove Existing Views
        usageToolsStack.arrangedSubviews.forEach {
            usageToolsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        // create the top card and add it to the grid
        guard let firstTool = usageTools.first else { return }
        let firstCard = UsageToolTopCardView().usingAutoLayout()
        firstCard.configureView(withUsageTool: firstTool)
        
        // sets the height for *every* row. the stack view distribution is set to .fillEqually
        firstCard.heightAnchor.constraint(equalToConstant: 110).isActive = true
        
        firstCard.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.accountDetail)
            .drive(onNext: { [weak self] in
                self?.usageToolCardTapped(firstTool, accountDetail: $0)
            })
            .disposed(by: firstCard.bag)
        
        usageToolsStack.addArrangedSubview(firstCard)
        
        let rowCount = 2
        
        // create rest of the cards
        var gridCardViews: [UIView] = usageTools.suffix(usageTools.count - 1)
            .map { usageTool in
                let cardView = UsageToolCardView().usingAutoLayout()
                cardView.configureView(withUsageTool: usageTool)
                cardView.rx.touchUpInside.asDriver()
                    .withLatestFrom(viewModel.accountDetail)
                    .drive(onNext: { [weak self] in
                        self?.usageToolCardTapped(usageTool, accountDetail: $0)
                    })
                    .disposed(by: cardView.bag)
                
                return cardView
        }
        
        // add spacer views if necessary to fill the last row
        while gridCardViews.count % rowCount != 0 {
            gridCardViews.append(UIView())
        }
        
        // create card rows and add them to the grid
        stride(from: 0, to: usageTools.count - 1, by: rowCount)
            .map { Array(gridCardViews[$0..<min($0 + rowCount, gridCardViews.count)]) }
            .map(UIStackView.init)
            .forEach { rowStack in
                rowStack.axis = .horizontal
                rowStack.alignment = .fill
                rowStack.distribution = .fillEqually
                rowStack.spacing = 10
                usageToolsStack.addArrangedSubview(rowStack)
        }
    }
    
    func usageToolCardTapped(_ usageTool: UsageTool, accountDetail: AccountDetail) {
        switch usageTool {
        case .usageData:
            performSegue(withIdentifier: "usageWebViewSegue", sender: accountDetail)
        case .energyTips:
            performSegue(withIdentifier: "top5EnergyTipsSegue", sender: accountDetail)
        case .homeProfile:
            performSegue(withIdentifier: "updateYourHomeProfileSegue", sender: accountDetail)
        case .peakRewards:
            Analytics.log(event: .viewUsagePeakRewards)
            performSegue(withIdentifier: "peakRewardsSegue", sender: accountDetail)
        case .smartEnergyRewards:
            performSegue(withIdentifier: "smartEnergyRewardsSegue", sender: accountDetail)
        case .hourlyPricing:
            if accountDetail.isHourlyPricing {
                Analytics.log(event: .hourlyPricing,
                              dimensions: [.hourlyPricingEnrollment: "enrolled"])
                performSegue(withIdentifier: "hourlyPricingSegue", sender: nil)
            } else {
                Analytics.log(event: .hourlyPricing,
                              dimensions: [.hourlyPricingEnrollment: "unenrolled"])
                let safariVc = SFSafariViewController
                    .createWithCustomStyle(url: URL(string: "https://hourlypricing.comed.com")!)
                present(safariVc, animated: true, completion: nil)
            }
        case .peakTimeSavings:
            performSegue(withIdentifier: "smartEnergyRewardsSegue", sender: accountDetail)
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let accountDetail = sender as? AccountDetail else { return }
        
        switch segue.destination {
        case let vc as SmartEnergyRewardsViewController:
            vc.accountDetail = accountDetail
        case let vc as UsageWebViewController:
            vc.accountDetail = accountDetail
        case let vc as Top5EnergyTipsViewController:
            vc.accountDetail = accountDetail
        case let vc as MyHomeProfileViewController:
            vc.accountDetail = accountDetail
            vc.didSaveHomeProfile
                .delay(0.5)
                .drive(onNext: { [weak self] in
                    self?.view.showToast(NSLocalizedString("Home profile updated", comment: ""))
                })
                .disposed(by: vc.disposeBag)
        case let vc as HourlyPricingViewController:
            vc.accountDetail = accountDetail
        case let vc as TotalSavingsViewController:
            vc.eventResults = accountDetail.serInfo.eventResults
        case let vc as PeakRewardsViewController:
            vc.accountDetail = accountDetail
        default:
            break
        }
    }
}

extension UsageViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        showSwitchAccountsLoadingState()
        viewModel.fetchAllData()
        setRefreshControlEnabled(enabled: false)
    }
    
}
