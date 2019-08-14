//
//  HomeUsageCardView.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeUsageCardView: UIView {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet private weak var clippingView: UIView!
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorTitleLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var maintenanceModeView: UIView!
    
    // Bill Comparison
    @IBOutlet private weak var billComparisonView: UIView!
    @IBOutlet private weak var usageOverviewLabel: UILabel!
    @IBOutlet private weak var billComparisonStackView: UIStackView!
    @IBOutlet private weak var segmentedControl: SegmentedControlNew!
    
    @IBOutlet private weak var billComparisonContentView: UIView!

    // Bill Comparison - Bar Graph
    @IBOutlet private weak var barGraphStackView: UIStackView!
    
    @IBOutlet private weak var noDataContainerButton: ButtonControl!
    @IBOutlet private weak var noDataBarView: UIView!
    @IBOutlet private weak var noDataLabel: UILabel!
    @IBOutlet private weak var noDataDateLabel: UILabel!
    
    @IBOutlet private weak var previousContainerButton: ButtonControl!
    @IBOutlet private weak var previousDollarLabel: UILabel!
    @IBOutlet private weak var previousBarView: UIView!
    @IBOutlet private weak var previousDateLabel: UILabel!
    @IBOutlet private weak var previousBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var currentContainerButton: ButtonControl!
    @IBOutlet private weak var currentDollarLabel: UILabel!
    @IBOutlet private weak var currentBarView: UIView!
    @IBOutlet private weak var currentDateLabel: UILabel!
    @IBOutlet private weak var currentBarHeightConstraint: NSLayoutConstraint!
    
    // Bill Comparison - Bar Graph Description View
    @IBOutlet private weak var barDescriptionView: UIView!
    @IBOutlet private weak var barDescriptionDateLabel: UILabel!
    @IBOutlet private weak var barDescriptionTotalBillTitleLabel: UILabel!
    @IBOutlet private weak var barDescriptionTotalBillValueLabel: UILabel!
    @IBOutlet private weak var barDescriptionUsageTitleLabel: UILabel!
    @IBOutlet private weak var barDescriptionUsageValueLabel: UILabel!
    @IBOutlet private weak var barDescriptionTriangleImageView: UIImageView!
    @IBOutlet private weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var viewUsageButton: UIButton!
    
    @IBOutlet private weak var comparisonLoadingView: UIView!
    
    @IBOutlet weak var maintenanceModeDescriptionLabel: UILabel!
    
    @IBOutlet private weak var unavailableView: UIStackView!
    @IBOutlet private weak var unavailableTitleLabel: UILabel!
    @IBOutlet private weak var unavailableDescriptionLabel: UILabel!
    
    @IBOutlet private weak var commercialView: UIStackView!
    @IBOutlet private weak var commercialTitleLabel: UILabel!
    @IBOutlet private weak var commercialDescriptionLabel: UILabel!
    
    @IBOutlet weak var viewCommercialUsageButton: UIButton!
    
    @IBOutlet private weak var billComparisonEmptyStateView: UIView!
    @IBOutlet private weak var billComparisonEmptyStateLabel: UILabel!
    @IBOutlet private weak var billComparisonEmptyStateTopSpace: UIView!
    
    @IBOutlet private weak var smartEnergyRewardsView: UIView!
    @IBOutlet private weak var smartEnergyRewardsTitleLabel: UILabel!
    @IBOutlet private weak var smartEnergyRewardsSeasonLabel: UILabel!
    
    @IBOutlet private weak var smartEnergyRewardsGrayBackgroundView: UIView!
    @IBOutlet private weak var smartEnergyRewardsGraphView: SmartEnergyRewardsView!
    
    @IBOutlet private weak var smartEnergyRewardsFooterLabel: UILabel!
    
    @IBOutlet weak var viewAllSavingsButton: UIButton!
    
    @IBOutlet private weak var smartEnergyRewardsEmptyStateView: UIView!
    @IBOutlet private weak var smartEnergyRewardsEmptyStateTitleLabel: UILabel!
    @IBOutlet private weak var smartEnergyRewardsEmptyStateDetailLabel: UILabel!
    
    var userTappedBarGraph = false
    
    fileprivate var viewModel: HomeUsageCardViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }

    static func create(withViewModel viewModel: HomeUsageCardViewModel) -> HomeUsageCardView {
        let view = Bundle.main.loadViewFromNib() as HomeUsageCardView
        view.viewModel = viewModel
        view.smartEnergyRewardsGraphView.viewModel = SmartEnergyRewardsViewModel(eventResults: viewModel.serResultEvents.elements())
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmentedControl.items = [NSLocalizedString("Electric", comment: ""),
                                  NSLocalizedString("Gas", comment: "")]
        segmentedControl.selectedIndex.value = 0

        billComparisonStackView.bringSubviewToFront(segmentedControl)
        
        clippingView.layer.cornerRadius = 10
        styleBillComparison()
        styleSmartEnergyRewards()
        
        // Unavailable
        unavailableTitleLabel.textColor = .deepGray
        unavailableTitleLabel.font = OpenSans.regular.of(textStyle: .body)
        
        unavailableDescriptionLabel.textColor = .deepGray
        unavailableDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        unavailableDescriptionLabel.attributedText = NSLocalizedString("Usage is not available for this account.", comment: "")
            .attributedString(textAlignment: .center)
        
        // Commercial Usage
        commercialTitleLabel.textColor = .deepGray
        commercialTitleLabel.font = OpenSans.regular.of(textStyle: .body)
        
        commercialDescriptionLabel.textColor = .deepGray
        commercialDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        commercialDescriptionLabel.attributedText = NSLocalizedString("View data to analyze trends in your energy consumption.", comment: "")
            .attributedString(textAlignment: .center)
        
        // Maintenance
        maintenanceModeDescriptionLabel.textColor = .deepGray
        maintenanceModeDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        // Error State
        errorTitleLabel.textColor = .deepGray
        errorTitleLabel.font = OpenSans.regular.of(textStyle: .body)
        
        errorLabel.textColor = .deepGray
        errorLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        errorLabel.textAlignment = .center
    }
    
    func superviewDidLayoutSubviews() {
        // We use this to appropriately position to initial selection triangle, and then to stop
        // receiving layout events after the user manually tapped a button, otherwise the
        // initial selection bar would never be able to be deselected
        if !userTappedBarGraph {
            moveTriangleTo(barView: currentContainerButton)
        }
        smartEnergyRewardsGraphView.superviewDidLayoutSubviews()
        
        // Fixes layout issues with segmented control
        segmentedControl.selectIndex(segmentedControl.selectedIndex.value, animated: false)
    }
    
    private func styleBillComparison() {
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 10
        
        usageOverviewLabel.textColor = .deepGray
        usageOverviewLabel.font = OpenSans.regular.of(textStyle: .body)
        
        billComparisonEmptyStateLabel.textColor = .deepGray
        billComparisonEmptyStateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        let dashedBorderColor = UIColor(red: 0, green: 80/255, blue: 125/255, alpha: 0.24)
        noDataBarView.addDashedBorder(color: dashedBorderColor)
        previousBarView.backgroundColor = .primaryColor
        currentBarView.backgroundColor = .primaryColor
        
        // Bar Graph Text Colors
        noDataLabel.textColor = .deepGray
        noDataLabel.font = SystemFont.regular.of(textStyle: .footnote)
        noDataDateLabel.textColor = .deepGray
        noDataDateLabel.font = SystemFont.regular.of(textStyle: .footnote)
        previousDollarLabel.textColor = .deepGray
        previousDollarLabel.font = SystemFont.regular.of(textStyle: .footnote)
        previousDateLabel.textColor = .deepGray
        previousDateLabel.font = SystemFont.regular.of(textStyle: .footnote)
        currentDollarLabel.textColor = .deepGray
        currentDollarLabel.font = SystemFont.regular.of(textStyle: .footnote)
        currentDateLabel.textColor = .deepGray
        currentDateLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        // Bar Graph Text Fonts
        noDataLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        
        barDescriptionView.layer.borderWidth = 1
        barDescriptionView.layer.borderColor = UIColor.accentGray.cgColor
        barDescriptionView.layer.cornerRadius = 10
        
        barDescriptionDateLabel.textColor = .deepGray
        barDescriptionDateLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        
        barDescriptionTotalBillTitleLabel.textColor = .deepGray
        barDescriptionTotalBillTitleLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        
        barDescriptionTotalBillValueLabel.textColor = .deepGray
        barDescriptionTotalBillValueLabel.font = SystemFont.regular.of(textStyle: .caption1)

        barDescriptionUsageTitleLabel.textColor = .deepGray
        barDescriptionUsageTitleLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        
        barDescriptionUsageValueLabel.textColor = .deepGray
        barDescriptionUsageValueLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        
        viewUsageButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .body)
        
        viewCommercialUsageButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .body)
    }
    
    private func styleSmartEnergyRewards() {
        smartEnergyRewardsTitleLabel.textColor = .deepGray
        smartEnergyRewardsTitleLabel.font = OpenSans.regular.of(textStyle: .body)
        smartEnergyRewardsTitleLabel.text = Environment.shared.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") :
            NSLocalizedString("Smart Energy Rewards", comment: "")
        
        smartEnergyRewardsSeasonLabel.textColor = .deepGray
        smartEnergyRewardsSeasonLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        smartEnergyRewardsFooterLabel.textColor = .deepGray
        smartEnergyRewardsFooterLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        smartEnergyRewardsFooterLabel.text = NSLocalizedString("You earn bill credits for every kWh you save. " +
            "We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use.", comment: "")
        
        viewAllSavingsButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .body)
        
        smartEnergyRewardsEmptyStateTitleLabel.textColor = .deepGray
        smartEnergyRewardsEmptyStateTitleLabel.font = OpenSans.regular.of(textStyle: .body)
        smartEnergyRewardsEmptyStateTitleLabel.text = Environment.shared.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") :
            NSLocalizedString("Smart Energy Rewards", comment: "")
        
        smartEnergyRewardsEmptyStateDetailLabel.textColor = .deepGray
        smartEnergyRewardsEmptyStateDetailLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        smartEnergyRewardsEmptyStateDetailLabel.text = NSLocalizedString("As a \(smartEnergyRewardsEmptyStateTitleLabel.text!) customer, you can earn bill credits for every kWh you save. " +
            "We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent " +
            "\(smartEnergyRewardsEmptyStateTitleLabel.text!) season will display here once available.", comment: "")
    }
    
    private func showContent() {
        billComparisonView.isHidden = false
        billComparisonContentView.isHidden = false
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
        commercialView.isHidden = true
        maintenanceModeView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showErrorState() {
        billComparisonView.isHidden = true
        billComparisonContentView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
        commercialView.isHidden = true
        maintenanceModeView.isHidden = true
        errorView.isHidden = false
    }
    
    private func showSmartEnergyRewards() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = false
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
        commercialView.isHidden = true
        maintenanceModeView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showSmartEnergyRewardsEmptyState() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = false
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
        commercialView.isHidden = true
        maintenanceModeView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showBillComparisonEmptyState() {
        billComparisonView.isHidden = false
        billComparisonContentView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = false
        unavailableView.isHidden = true
        commercialView.isHidden = true
        maintenanceModeView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showUnavailableState() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = false
        commercialView.isHidden = true
        maintenanceModeView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showCommercialState() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
        commercialView.isHidden = false
        maintenanceModeView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showMaintenanceModeState() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
        commercialView.isHidden = true
        maintenanceModeView.isHidden = false
        errorView.isHidden = true
    }
    
    private func bindViewModel() {
        viewModel.showLoadingState.drive(contentStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showLoadingState.not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showLoadingState
            .drive(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
            .disposed(by: disposeBag)
        
        // Bill Comparison vs. SER Show/Hide
        viewModel.showBillComparison
            .drive(onNext: { [weak self] in self?.showContent() })
            .disposed(by: disposeBag)
        
        viewModel.showErrorState
            .drive(onNext: { [weak self] in self?.showErrorState() })
            .disposed(by: disposeBag)
        
        viewModel.showSmartEnergyRewards
            .drive(onNext: { [weak self] in self?.showSmartEnergyRewards() })
            .disposed(by: disposeBag)
        
        viewModel.showSmartEnergyEmptyState
            .do(onNext: { GoogleAnalytics.log(event: .emptyStateSmartEnergyHome) })
            .drive(onNext: { [weak self] in self?.showSmartEnergyRewardsEmptyState() })
            .disposed(by: disposeBag)
        
        viewModel.showBillComparisonEmptyState
            .do(onNext: { GoogleAnalytics.log(event: .emptyStateUsageOverview) })
            .drive(onNext: { [weak self] in self?.showBillComparisonEmptyState() })
            .disposed(by: disposeBag)
        
        viewModel.showUnavailableState
            .drive(onNext: { [weak self] in self?.showUnavailableState() })
            .disposed(by: disposeBag)
        
        viewModel.showCommercialState
            .drive(onNext: { [weak self] in self?.showCommercialState() })
            .disposed(by: disposeBag)
        
        viewModel.showMaintenanceModeState
            .drive(onNext: { [weak self] in self?.showMaintenanceModeState() })
            .disposed(by: disposeBag)
        
        // --- Bill Comparison ---
        
        // Loading/Error/Content States
        viewModel.loadingTracker.asDriver().not()
            .drive(comparisonLoadingView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.loadingTracker.asDriver()
            .filter { $0 }
            .drive(onNext: { [weak self] _ in
                self?.billComparisonContentView.isHidden = true
                self?.billComparisonEmptyStateView.isHidden = true
            })
            .disposed(by: disposeBag)
        
        let attributedErrorText = viewModel.errorLabelText.attributedString(textAlignment: .center)
        errorLabel.attributedText = attributedErrorText
        let localizedAccessibililtyText = NSLocalizedString("Usage OverView, %@", comment: "")
        errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, attributedErrorText)
        
        // Segmented Controls
        viewModel.showElectricGasSegmentedControl.not()
            .drive(segmentedControl.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showElectricGasSegmentedControl.not()
            .drive(billComparisonEmptyStateTopSpace.rx.isHidden)
            .disposed(by: disposeBag)
        segmentedControl.selectedIndex.asDriver().skip(1).distinctUntilChanged().drive(viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)

        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().subscribe(onNext: { index in
            if index == 0 {
                GoogleAnalytics.log(event: .viewUsageElectricity)
            } else {
                GoogleAnalytics.log(event: .viewUsageGas)
            }
        }).disposed(by: disposeBag)
        
        viewModel.billComparisonEvents.subscribe({ [weak self] _ in
            guard let self = self else { return }
            self.moveTriangleTo(barView: self.currentContainerButton)
            
            self.viewModel.setBarSelected(tag: 2)
        }).disposed(by: disposeBag)
        
        // Bar graph height constraints
        viewModel.previousBarHeightConstraintValue.drive(previousBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.currentBarHeightConstraintValue.drive(currentBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        
        // Bar graph corner radius
        viewModel.previousBarHeightConstraintValue.map { min(10, $0/2) }.drive(previousBarView.rx.cornerRadius).disposed(by: disposeBag)
        viewModel.currentBarHeightConstraintValue.map { min(10, $0/2) }.drive(currentBarView.rx.cornerRadius).disposed(by: disposeBag)

        // Bar show/hide
        viewModel.noPreviousData.asDriver().not().drive(noDataContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().drive(previousContainerButton.rx.isHidden).disposed(by: disposeBag)
        
        // Bar labels
        viewModel.noDataBarDateLabelText.drive(noDataDateLabel.rx.text).disposed(by: disposeBag)
        noDataLabelFont.drive(noDataDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousBarDollarLabelText.drive(previousDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.previousBarDateLabelText.drive(previousDateLabel.rx.text).disposed(by: disposeBag)
        previousLabelFont.drive(previousDollarLabel.rx.font).disposed(by: disposeBag)
        previousLabelFont.drive(previousDateLabel.rx.font).disposed(by: disposeBag)
        previousDollarLabelTextColor.drive(previousDollarLabel.rx.textColor).disposed(by: disposeBag)
        viewModel.currentBarDollarLabelText.drive(currentDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.currentBarDateLabelText.drive(currentDateLabel.rx.text).disposed(by: disposeBag)
        currentLabelFont.drive(currentDollarLabel.rx.font).disposed(by: disposeBag)
        currentLabelFont.drive(currentDateLabel.rx.font).disposed(by: disposeBag)
        currentDollarLabelTextColor.drive(currentDollarLabel.rx.textColor).disposed(by: disposeBag)
        
        // Bar accessibility
        noDataContainerButton.accessibilityLabel = NSLocalizedString("Previous bill. Not enough data available.", comment: "")
        viewModel.previousBarA11yLabel.drive(previousContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.currentBarA11yLabel.drive(currentContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.noPreviousData.asObservable().subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            var a11yElementArray: [ButtonControl] = []
            if $0 {
                a11yElementArray.append(self.noDataContainerButton)
            } else {
                a11yElementArray.append(self.previousContainerButton)
            }
            a11yElementArray.append(self.currentContainerButton)
            self.barGraphStackView.accessibilityElements = a11yElementArray
        }).disposed(by: disposeBag)
        
        // Bar description
        viewModel.barDescriptionDateLabelText.drive(barDescriptionDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionTotalBillTitleLabelText.drive(barDescriptionTotalBillTitleLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionTotalBillValueLabelText.drive(barDescriptionTotalBillValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionUsageTitleLabelText.drive(barDescriptionUsageTitleLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionUsageValueLabelText.drive(barDescriptionUsageValueLabel.rx.text).disposed(by: disposeBag)
        
        // Smart Energy Rewards
        viewModel.smartEnergyRewardsSeasonLabelText.drive(smartEnergyRewardsSeasonLabel.rx.text).disposed(by: disposeBag)
        
        // Bill Comparison Empty State
        viewModel.billComparisonEmptyStateText
            .map { $0.attributedString(textAlignment: .center) }
            .drive(billComparisonEmptyStateLabel.rx.attributedText)
            .disposed(by: disposeBag)
    }
    
    @IBAction func onBarPress(sender: ButtonControl) {
        moveTriangleTo(barView: sender)
        viewModel.setBarSelected(tag: sender.tag)
        userTappedBarGraph = true
    }
    
    private func moveTriangleTo(barView: UIView) {
        barDescriptionTriangleCenterXConstraint.isActive = false
        barDescriptionTriangleCenterXConstraint = barDescriptionTriangleImageView.centerXAnchor
            .constraint(equalTo: barView.centerXAnchor)
        barDescriptionTriangleCenterXConstraint.isActive = true
    }
    
    // MARK: Bill Comparison Bar Graph Drivers
    private(set) lazy var noDataLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[0].asDriver().map {
        $0 ? SystemFont.bold.of(textStyle: .footnote) : SystemFont.regular.of(textStyle: .footnote)
    }
    
    private(set) lazy var previousLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[1].asDriver().map {
        $0 ? SystemFont.bold.of(textStyle: .footnote) : SystemFont.regular.of(textStyle: .footnote)
    }
    
    private(set) lazy var previousDollarLabelTextColor: Driver<UIColor> = self.viewModel.billComparisonDriver.map {
        guard let compared = $0.compared else { return .deepGray }
        return compared.charges < 0 ? .successGreenText : .deepGray
    }
    
    private(set) lazy var currentLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[2].asDriver().map {
        $0 ? SystemFont.bold.of(textStyle: .footnote) : SystemFont.regular.of(textStyle: .footnote)
    }
    
    private(set) lazy var currentDollarLabelTextColor: Driver<UIColor> = self.viewModel.billComparisonDriver.map {
        guard let reference = $0.reference else { return .deepGray }
        return reference.charges < 0 ? .successGreenText : .deepGray
    }

}
