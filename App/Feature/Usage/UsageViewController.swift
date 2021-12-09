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
import RxSwiftExt
import SafariServices

class UsageViewController: AccountPickerViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var switchAccountsLoadingIndicator: LoadingIndicator!
    @IBOutlet private weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet private weak var maintenanceModeView: MaintenanceModeView!
    
    @IBOutlet private weak var mainStack: UIStackView!
    @IBOutlet private weak var accountPickerSpacerView: UIView!
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var unavailableView: UnavailableView!
    @IBOutlet private weak var prepaidView: UIView!
    @IBOutlet private weak var mainErrorView: UIView!
    @IBOutlet private weak var mainErrorLabel: UILabel! {
        didSet {
            mainErrorLabel.font = SystemFont.regular.of(textStyle: .headline)
            mainErrorLabel.textColor = .blackText
        }
    }
    @IBOutlet weak var accountDisallowView: UIView!
    
    @IBOutlet private weak var segmentedControl: SegmentedControl! {
        didSet {
            segmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        }
    }
    
    @IBOutlet private weak var compareBillTitlelabel: UILabel! {
        didSet {
            compareBillTitlelabel.textColor = .deepGray
            compareBillTitlelabel.font = OpenSans.regular.of(textStyle: .headline)
        }
    }
    
    @IBOutlet private weak var myUsageToolsLabel: UILabel! {
        didSet {
            myUsageToolsLabel.textColor = .deepGray
            myUsageToolsLabel.font = OpenSans.regular.of(textStyle: .headline)
        }
    }
    
    @IBOutlet private weak var usageToolsStack: UIStackView!
    
    // Bill Graph
    @IBOutlet private weak var billComparisonTitleContainer: UIView!
    @IBOutlet private weak var billComparisonDataContainer: UIView!
    @IBOutlet private weak var billGraphDetailContainer: UIView!
    @IBOutlet private weak var billGraphDetailView: UIView! {
        didSet {
            billGraphDetailView.layer.cornerRadius = 10
            billGraphDetailView.layer.borderColor = UIColor.accentGray.cgColor
            billGraphDetailView.layer.borderWidth = 1
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
        }
    }
    
    @IBOutlet private weak var previousBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var previousDollarLabel: UILabel!
    
    @IBOutlet private weak var previousDateLabel: UILabel!
    
    @IBOutlet private weak var currentContainerButton: ButtonControl!
    @IBOutlet private weak var currentBarView: UIView! {
        didSet {
            currentBarView.backgroundColor = .primaryColor
        }
    }
    
    @IBOutlet private weak var currentBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var currentDollarLabel: UILabel!
    @IBOutlet private weak var currentDateLabel: UILabel!
    
    @IBOutlet private weak var projectedContainerButton: ButtonControl!
    @IBOutlet private weak var projectedBarView: UIView! {
        didSet {
            projectedBarView.layer.borderWidth = 1
            projectedBarView.clipsToBounds = true
        }
    }
    @IBOutlet private weak var projectedBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var projectedBarSoFarImageView: UIImageView!
    @IBOutlet private weak var projectedBarSoFarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var projectedDollarLabel: UILabel!
    @IBOutlet private weak var projectedDateLabel: UILabel!
    
    @IBOutlet private weak var projectionNotAvailableContainerButton: ButtonControl!
    @IBOutlet private weak var projectionNotAvailableBarView: UIView!
    @IBOutlet private weak var projectionNotAvailableUntilNextForecastLabel: UILabel!
    @IBOutlet private weak var projectedNotAvailableDateLabel: UILabel!
    @IBOutlet private weak var projectedNotAvailableDaysRemainingLabel: UILabel!
    
    @IBOutlet private weak var graphDetailDateLabel: UILabel! {
        didSet {
            graphDetailDateLabel.textColor = .deepGray
            graphDetailDateLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet private weak var graphDetailTemperatureLabel: UILabel! {
        didSet {
            graphDetailTemperatureLabel.textColor = .deepGray
            graphDetailTemperatureLabel.font = OpenSans.regular.of(textStyle: .caption1)
        }
    }
    
    @IBOutlet private weak var graphDetailDescriptionLabel: UILabel! {
        didSet {
            graphDetailDescriptionLabel.textColor = .deepGray
            graphDetailDescriptionLabel.font = OpenSans.regular.of(textStyle: .caption1)
        }
    }
    
    @IBOutlet private weak var lastYearButton: UIButton! {
        didSet {
            lastYearButton.layer.cornerRadius = 16
            lastYearButton.layer.borderColor = UIColor.accentGray.cgColor
            lastYearButton.layer.borderWidth = 1
            lastYearButton.accessibilityLabel = NSLocalizedString("Compare to last year", comment: "")
        }
    }
    
    @IBOutlet private weak var previousBillButton: UIButton! {
        didSet {
            previousBillButton.layer.cornerRadius = 16
            previousBillButton.layer.borderColor = UIColor.accentGray.cgColor
            previousBillButton.layer.borderWidth = 1
            previousBillButton.accessibilityLabel = NSLocalizedString("Compare to previous bill", comment: "")
        }
    }
    
    @IBOutlet private weak var billComparisonLoadingIndicator: LoadingIndicator!
    @IBOutlet private weak var billComparisonErrorView: UIView!
    @IBOutlet private weak var billComparisonErrorLabel: UILabel! {
        didSet {
            // todo this has a title and detail label on sympli, is this the unavailalbe for your account label too?
            billComparisonErrorLabel.textColor = .deepGray
            billComparisonErrorLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            billComparisonErrorLabel.textAlignment = .center
        }
    }
    
    // MARK: - Other Properties
    
    private var commercialViewController: CommercialUsageViewController?
    
    var refreshControl: UIRefreshControl?
    
    let disposeBag = DisposeBag()
    
    let viewModel = UsageViewModel()
    
    var initialSelection: (barSelection: UsageViewModel.BarGraphSelection, isGas: Bool, isPreviousBill: Bool)?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Account Picker
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        setRefreshControlEnabled(enabled: false)
        
        showSwitchAccountsLoadingState()
        barGraphPress(currentContainerButton)
        
        if let (barSelection, isGas, isPreviousBill) = initialSelection {
            viewModel.electricGasSelectedSegmentIndex.accept(isGas ? 1 : 0)
            selectLastYearPreviousBill(isPreviousBill: isPreviousBill)
            selectBar(barSelection, gas: isGas)
        }
        
        styleBarGraph()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseUtility.logScreenView(.usageView(className: self.className))

        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let dashedBorderColor = UIColor.accentGray
        let backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.03)
        noDataBarView.addDashedBorder(color: dashedBorderColor)
        noDataBarView.backgroundColor = backgroundColor
        projectionNotAvailableBarView.addDashedBorder(color: dashedBorderColor)
        projectionNotAvailableBarView.backgroundColor = backgroundColor
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
        switch sender.tag {
        case 1:
            FirebaseUtility.logEvent(.usage(parameters: [.previous_bar_press]))
        case 2:
            FirebaseUtility.logEvent(.usage(parameters: [.current_bar_press]))
        case 3:
            FirebaseUtility.logEvent(.usage(parameters: [.projected_bar_press]))
        default:
            break
        }
        
        viewModel.setBarSelected(tag: sender.tag)
    }
    
    func selectBar(_ selectedBar: UsageViewModel.BarGraphSelection, gas: Bool) {
        
        if gas {
            FirebaseUtility.logEvent(.usage(parameters: [.gas_segment_press]))
        } else {
            FirebaseUtility.logEvent(.usage(parameters: [.electric_segment_press]))
        }
        
        viewModel.electricGasSelectedSegmentIndex.accept(gas ? 1 : 0)
        viewModel.setBarSelected(tag: selectedBar.rawValue)
    }
    
    // MARK: - Style Views
    
    private func styleBarGraph() {
        switch Configuration.shared.opco {
        case .bge:
            projectedBarView.backgroundColor = UIColor(red: 0, green: 110/255, blue: 187/255, alpha: 0.2)
            projectedBarView.layer.borderColor = UIColor(red: 0, green: 110/255, blue: 187/255, alpha: 0.4).cgColor
            projectedBarSoFarImageView.tintColor = UIColor(red: 0, green: 110/255, blue: 187/255, alpha: 1)
        case .comEd:
            projectedBarView.backgroundColor = UIColor(red: 0, green: 159/255, blue: 194/255, alpha: 0.2)
            projectedBarView.layer.borderColor = UIColor(red: 0, green: 159/255, blue: 194/255, alpha: 0.4).cgColor
            projectedBarSoFarImageView.tintColor = UIColor(red: 0, green: 159/255, blue: 194/255, alpha: 1)
        case .peco:
            projectedBarView.backgroundColor = UIColor(red: 114/255, green: 184/255, blue: 101/255, alpha: 0.2)
            projectedBarView.layer.borderColor = UIColor(red: 114/255, green: 184/255, blue: 101/255, alpha: 0.4).cgColor
            projectedBarSoFarImageView.tintColor = UIColor(red: 114/255, green: 184/255, blue: 101/255, alpha: 1)
        case .ace, .delmarva, .pepco:
            projectedBarView.backgroundColor = UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 0.2)
            projectedBarView.layer.borderColor = UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 0.4).cgColor
            projectedBarSoFarImageView.tintColor = UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 1)
        }
        
        // Bar Graph Styling
        noDataLabel.textColor = .deepGray
        noDataLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        
        noDataDateLabel.textColor = .deepGray
        noDataDateLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        previousDollarLabel.textColor = .deepGray
        previousDateLabel.textColor = .deepGray
        currentDollarLabel.textColor = .deepGray
        currentDateLabel.textColor = .deepGray
        projectedDollarLabel.textColor = .deepGray
        projectedDateLabel.textColor = .deepGray
        
        projectedNotAvailableDaysRemainingLabel.textColor = .actionBlue
        projectedNotAvailableDaysRemainingLabel.font = SystemFont.semibold.of(textStyle: .caption1)

        projectionNotAvailableUntilNextForecastLabel.textColor = .deepGray
        projectionNotAvailableUntilNextForecastLabel.font = SystemFont.regular.of(textStyle: .caption2)

        projectedNotAvailableDateLabel.textColor = .deepGray
        viewModel.projectionNotAvailableLabelFont.drive(projectedNotAvailableDateLabel.rx.font).disposed(by: disposeBag)
        
        viewModel.noDataLabelFont.drive(noDataDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousLabelFont.drive(previousDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousLabelFont.drive(previousDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousDollarLabelTextColor.drive(previousDollarLabel.rx.textColor).disposed(by: disposeBag)
        viewModel.currentLabelFont.drive(currentDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.currentLabelFont.drive(currentDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.currentDollarLabelTextColor.drive(currentDollarLabel.rx.textColor).disposed(by: disposeBag)
        viewModel.projectedLabelFont.drive(projectedDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.projectedLabelFont.drive(projectedDateLabel.rx.font).disposed(by: disposeBag)
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
        Driver.merge(lastYearButton.rx.tap.asDriver().mapTo(false),
                     previousBillButton.rx.tap.asDriver().mapTo(true))
            .drive(onNext: { [weak self] isPreviousBill in
                if self?.viewModel.barGraphSelection.value == .projected {
                    self?.viewModel.barGraphSelection.accept(.current)
                }
                self?.selectLastYearPreviousBill(isPreviousBill: isPreviousBill)
                
                if isPreviousBill {
                    FirebaseUtility.logEvent(.usage(parameters: [.last_year_graph_press]))
                } else {
                    FirebaseUtility.logEvent(.usage(parameters: [.last_bill_graph_press]))
                }
                
                GoogleAnalytics.log(event: isPreviousBill ? .billPreviousToggle : .billLastYearToggle)
            })
            .disposed(by: disposeBag)
        
        Observable.merge(RxNotifications.shared.accountDetailUpdated,
                         maintenanceModeView.reload)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                self?.showSwitchAccountsLoadingState()
                self?.viewModel.fetchAllData()
            })
            .disposed(by: disposeBag)
    }
    
    func selectLastYearPreviousBill(isPreviousBill: Bool) {
        if billComparisonLoadingIndicator != nil {
            showBillComparisonLoadingState()
        }

        viewModel.lastYearPreviousBillSelectedSegmentIndex.accept(isPreviousBill ? 1 : 0)
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
        
        viewModel.showCommercialState
            .drive(onNext: { [weak self] in self?.showCommercialState() })
            .disposed(by: disposeBag)
        
        viewModel.showPrepaidState
            .drive(onNext: { [weak self] in self?.showPrepaidState() })
            .disposed(by: disposeBag)
        
        viewModel.showMainErrorState
            .drive(onNext: { [weak self] in self?.showMainErrorState() })
            .disposed(by: disposeBag)
        
        viewModel.showAccountDisallowState
            .drive(onNext: { [weak self] in self?.showAccountDisallowState() })
            .disposed(by: disposeBag)
        
        viewModel.showNoNetworkState
            .drive(onNext: { [weak self] in self?.showNoNetworkState() })
            .disposed(by: disposeBag)
        
        viewModel.showMaintenanceModeState
            .drive(onNext: { [weak self] in self?.showMaintenanceModeState() })
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
        viewModel.electricGasSelectedSegmentIndex.asDriver()
            .distinctUntilChanged()
            .drive(segmentedControl.selectedIndex)
            .disposed(by: disposeBag)
        
        segmentedControl.selectedIndex.asDriver()
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in self?.showBillComparisonLoadingState() })
            .drive(viewModel.electricGasSelectedSegmentIndex)
            .disposed(by: disposeBag)
        
        viewModel.electricGasSelectedSegmentIndex.asObservable()
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { index in
                if index == 0 {
                    GoogleAnalytics.log(event: .billElectricityToggle)
                } else {
                    GoogleAnalytics.log(event: .billGasToggle)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.lastYearPreviousBillSelectedSegmentIndex.asDriver()
            .map { $0 == 0 }
            .drive(previousBillButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.lastYearPreviousBillSelectedSegmentIndex.asDriver()
            .map { $0 == 1 }
            .drive(lastYearButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.showElectricGasSegmentedControl.not().drive(segmentedControl.rx.isHidden).disposed(by: disposeBag)
        viewModel.compareBillTitle.drive(compareBillTitlelabel.rx.text).disposed(by: disposeBag)
        
        // Update bar graph selection when the current selection is no longer available.
        Driver.combineLatest(viewModel.barGraphSelection.asDriver().distinctUntilChanged(),
                             viewModel.showProjectedBar.distinctUntilChanged(),
                             viewModel.noPreviousData.distinctUntilChanged(),
                             viewModel.showProjectionNotAvailableBar.distinctUntilChanged())
            .drive(onNext: { [weak self] barGraphSelection, showProjected, noPreviousData, showProjectionNotAvailableBar in
                guard let self = self else { return }
                
                let barView: UIView
                switch barGraphSelection {
                case .noData, .previous:
                    if noPreviousData {
                        barView = self.noDataContainerButton
                    } else {
                        barView = self.previousContainerButton
                    }
                case .current:
                    barView = self.currentContainerButton
                case .projected:
                    if showProjected {
                        barView = self.projectedContainerButton
                    } else {
                        barView = self.currentContainerButton
                    }
                case .projectionNotAvailable:
                    if showProjectionNotAvailableBar {
                        barView = self.projectionNotAvailableContainerButton
                    } else if showProjected {
                        barView = self.projectedContainerButton
                    } else {
                        barView = self.currentContainerButton
                    }
                }
                
                self.barDescriptionTriangleCenterXConstraint.isActive = false
                self.barDescriptionTriangleCenterXConstraint = self.barDescriptionTriangleImageView.centerXAnchor
                    .constraint(equalTo: barView.centerXAnchor)
                self.barDescriptionTriangleCenterXConstraint.isActive = true
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
        
        viewModel.projectedBarSoFarHeightConstraintValue
            .drive(projectedBarSoFarHeightConstraint.rx.constant)
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
            .drive(projectedBarView.rx.cornerRadius)
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
        
        // Empty State
        viewModel.billComparisonEmptyStateText
            .map { $0.attributedString(textAlignment: .center, lineHeight: 26) }
            .drive(billComparisonErrorLabel.rx.attributedText)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Screen States
    
    private func showSwitchAccountsLoadingState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = false
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = true
        prepaidView.isHidden = true
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        showBillComparisonLoadingState()
        removeCommercialView()
    }
    
    private func showMainContents() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = false
        prepaidView.isHidden = true
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        removeCommercialView()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showNoUsageDataState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = false
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = true
        prepaidView.isHidden = true
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        removeCommercialView()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showCommercialState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = true
        contentStack.isHidden = true
        prepaidView.isHidden = true
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        
        guard let _ = commercialViewController else {
            addCommercialView()
            return
        }
    }
    
    private func showPrepaidState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = true
        prepaidView.isHidden = false
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        removeCommercialView()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showMainErrorState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = true
        prepaidView.isHidden = true
        mainErrorView.isHidden = false
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        removeCommercialView()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showAccountDisallowState() {
        scrollView?.isHidden = false
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = true
        prepaidView.isHidden = true
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = false
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = true
        removeCommercialView()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showNoNetworkState() {
        scrollView?.isHidden = true
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = true
        prepaidView.isHidden = true
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = false
        maintenanceModeView.isHidden = true
        removeCommercialView()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showMaintenanceModeState() {
        scrollView?.isHidden = true
        switchAccountsLoadingIndicator.isHidden = true
        unavailableView.isHidden = true
        accountPickerSpacerView.isHidden = false
        contentStack.isHidden = true
        prepaidView.isHidden = true
        mainErrorView.isHidden = true
        accountDisallowView.isHidden = true
        noNetworkConnectionView.isHidden = true
        maintenanceModeView.isHidden = false
        removeCommercialView()
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showBillComparisonLoadingState() {
        billComparisonLoadingIndicator.isHidden = false
        barGraphStackView.isHidden = true
        billGraphDetailContainer.isHidden = true
        billComparisonErrorView.isHidden = true
        billComparisonDataContainer.isHidden = false
        billComparisonTitleContainer.isHidden = false
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showBillComparisonContents() {
        billComparisonLoadingIndicator.isHidden = true
        barGraphStackView.isHidden = false
        billGraphDetailContainer.isHidden = false
        billComparisonErrorView.isHidden = true
        billComparisonDataContainer.isHidden = false
        billComparisonTitleContainer.isHidden = false
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func showBillComparisonErrorState() {
        billComparisonLoadingIndicator.isHidden = true
        barGraphStackView.isHidden = true
        billGraphDetailContainer.isHidden = true
        billComparisonErrorView.isHidden = false
        billComparisonDataContainer.isHidden = true
        billComparisonTitleContainer.isHidden = true
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    private func removeCommercialView() {
        commercialViewController?.willMove(toParent: nil)
        commercialViewController?.view.removeFromSuperview()
        commercialViewController?.removeFromParent()
        commercialViewController = nil
        view.backgroundColor = .softGray
    }
    
    private func addCommercialView() {
        let commercialVC = CommercialUsageViewController(with: viewModel.commercialViewModel)
        addChild(commercialVC)
        mainStack.addArrangedSubview(commercialVC.view)
        commercialVC.didMove(toParent: self)
        NSLayoutConstraint.activate([
            commercialVC.view.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            commercialVC.view.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor)
        ])
        commercialViewController = commercialVC
        view.backgroundColor = .white
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
            let segueIdentifier = "usageWebViewB2cSegue"
            performSegue(withIdentifier: segueIdentifier, sender: accountDetail)
        case .energyTips:
            performSegue(withIdentifier: "top5EnergyTipsSegue", sender: accountDetail)
        case .homeProfile:
            performSegue(withIdentifier: "updateYourHomeProfileSegue", sender: accountDetail)
        case .peakRewards:
            GoogleAnalytics.log(event: .viewUsagePeakRewards)
            performSegue(withIdentifier: "peakRewardsSegue", sender: accountDetail)
        case .smartEnergyRewards:
            GoogleAnalytics.log(event: .viewSmartEnergyRewards)
            let segueIdentifier = "serWebViewB2cSegue"
            performSegue(withIdentifier: segueIdentifier, sender: accountDetail)
        case .hourlyPricing:
            if accountDetail.isHourlyPricing {
                GoogleAnalytics.log(event: .hourlyPricing,
                                    dimensions: [.hourlyPricingEnrollment: "enrolled"])
                performSegue(withIdentifier: "hourlyPricingSegue", sender: accountDetail)
            } else {
                GoogleAnalytics.log(event: .hourlyPricing,
                                    dimensions: [.hourlyPricingEnrollment: "unenrolled"])
                let safariVc = SFSafariViewController
                    .createWithCustomStyle(url: URL(string: "https://hourlypricing.comed.com")!)
                present(safariVc, animated: true, completion: nil)
            }
        case .peakTimeSavings:
            if accountDetail.isAMIAccount && !accountDetail.isPTSAccount {
                GoogleAnalytics.log(event: .peakTimePromo)
                let safariVc = SFSafariViewController.createWithCustomStyle(url: URL(string: "http://comed.com/PTS")!)
                present(safariVc, animated: true, completion: nil)
            } else {
                GoogleAnalytics.log(event: .viewPeakTimeSavings)
                performSegue(withIdentifier: "smartEnergyRewardsSegue", sender: accountDetail)
            }
        case .energyWiseRewards:
            performSegue(withIdentifier: "energyWiseRewardsSegue", sender: accountDetail)
        case .peakEnergySavings:
            performSegue(withIdentifier: "peakEnergySavingsSegue", sender: accountDetail)
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let accountDetail = sender as? AccountDetail else { return }
        switch segue.destination {
        case let vc as SERWebViewController:
            vc.accountDetail = accountDetail
        case let vc as SERPTSViewController:
            vc.accountDetail = accountDetail
        case let vc as UsageWebViewController:
            vc.accountDetail = accountDetail
        case let vc as B2CUsageWebViewController:
            vc.accountDetail = accountDetail
            if segue.identifier == "serWebViewB2cSegue" {
                vc.widget = .ser
            } else {
                vc.widget = .usage
            }
        case let vc as Top5EnergyTipsViewController:
            vc.accountDetail = accountDetail
        case let vc as MyHomeProfileViewController:
            vc.accountDetail = accountDetail
            vc.didSaveHomeProfile
                .delay(.milliseconds(500))
                .drive(onNext: { [weak self] in
                    self?.view.showToast(NSLocalizedString("Home profile updated", comment: ""))
                })
                .disposed(by: vc.disposeBag)
        case let vc as HourlyPricingViewController:
            vc.accountDetail = accountDetail
        case let vc as PeakRewardsViewController:
            vc.accountDetail = accountDetail
        case let vc as EnergyWiseRewardsViewController:
            vc.accountDetail = accountDetail
        case let vc as PeakEnergySavingsViewController:
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
        viewModel.commercialViewModel.selectedIndex.accept(0) // reset commercial tab selection
        setRefreshControlEnabled(enabled: false)
    }
    
}
