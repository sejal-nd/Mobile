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
    
    // Bill Comparison
    @IBOutlet private weak var billComparisonView: UIView!
    @IBOutlet private weak var usageOverviewLabel: UILabel!
    @IBOutlet private weak var billComparisonStackView: UIStackView!
    @IBOutlet private weak var segmentedControl: BillAnalysisSegmentedControl!
    
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
    @IBOutlet private weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var viewUsageButton: ButtonControl!
    @IBOutlet private weak var viewUsageButtonLabel: UILabel!
    @IBOutlet weak var viewUsageEmptyStateButton: ButtonControl!
    @IBOutlet private weak var viewUsageEmptyStateButtonLabel: UILabel!
    
    @IBOutlet private weak var comparisonLoadingView: UIView!
    
    @IBOutlet private weak var unavailableView: UIStackView!
    @IBOutlet private weak var unavailableTitleLabel: UILabel!
    @IBOutlet private weak var unavailableDescriptionLabel: UILabel!
    
    @IBOutlet private weak var billComparisonEmptyStateView: UIView!
    @IBOutlet private weak var billComparisonEmptyStateTitleLabel: UILabel!
    @IBOutlet private weak var billComparisonEmptyStateLabel: UILabel!
    
    @IBOutlet private weak var smartEnergyRewardsView: UIView!
    @IBOutlet private weak var smartEnergyRewardsTitleLabel: UILabel!
    @IBOutlet private weak var smartEnergyRewardsSeasonLabel: UILabel!
    
    @IBOutlet private weak var smartEnergyRewardsGrayBackgroundView: UIView!
    @IBOutlet private weak var smartEnergyRewardsGraphView: SmartEnergyRewardsView!
    
    @IBOutlet private weak var smartEnergyRewardsFooterLabel: UILabel!
    
    @IBOutlet weak var viewAllSavingsButton: ButtonControl!
    @IBOutlet weak var viewAllSavingsButtonLabel: UILabel!
    
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
        view.smartEnergyRewardsGraphView.viewModel = SmartEnergyRewardsViewModel(accountDetailDriver: viewModel.accountDetailDriver)
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmentedControl.setItems(leftLabel: NSLocalizedString("Electric", comment: ""),
                                  rightLabel: NSLocalizedString("Gas", comment: ""),
                                  initialSelectedIndex: 0)
        
        billComparisonStackView.bringSubview(toFront: segmentedControl)
        
        clippingView.layer.cornerRadius = 10
        styleBillComparison()
        styleSmartEnergyRewards()
        unavailableTitleLabel.textColor = .blackText
        unavailableTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        unavailableDescriptionLabel.font = OpenSans.regular.of(textStyle: .title1)
        
        unavailableDescriptionLabel.textColor = .middleGray
        unavailableDescriptionLabel.attributedText = NSLocalizedString("Your usage overview will be available here once we have two full months of data.", comment: "")
            .attributedString(withLineHeight: 26, textAlignment: .center)
    }
    
    func superviewDidLayoutSubviews() {
        // We use this to appropriately position to initial selection triangle, and then to stop
        // receiving layout events after the user manually tapped a button, otherwise the
        // initial selection bar would never be able to be deselected
        if !userTappedBarGraph {
            moveTriangleTo(centerPoint: currentContainerButton.center)
        }
        smartEnergyRewardsGraphView.superviewDidLayoutSubviews()
    }
    
    private func styleBillComparison() {
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.cornerRadius = 10
        
        usageOverviewLabel.textColor = .blackText
        usageOverviewLabel.font = OpenSans.semibold.of(size: 18)
        
        billComparisonEmptyStateLabel.font = OpenSans.regular.of(textStyle: .title1)
       
        billComparisonEmptyStateLabel.textColor = .middleGray
        billComparisonEmptyStateLabel.attributedText = NSLocalizedString("Your usage overview will be available here once we have two full months of data.", comment: "")
            .attributedString(withLineHeight: 26, textAlignment: .center)
        
        billComparisonContentView.backgroundColor = .softGray
        
        let dashedBorderColor = UIColor(red: 0, green: 80/255, blue: 125/255, alpha: 0.24)
        noDataBarView.addDashedBorder(color: dashedBorderColor)
        previousBarView.backgroundColor = .primaryColor
        currentBarView.backgroundColor = .primaryColor
        
        // Bar Graph Text Colors
        noDataLabel.textColor = .deepGray
        noDataDateLabel.textColor = .blackText
        previousDollarLabel.textColor = .blackText
        previousDateLabel.textColor = .blackText
        currentDollarLabel.textColor = .blackText
        currentDateLabel.textColor = .blackText
        
        // Bar Graph Text Fonts
        noDataLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        barDescriptionView.layer.cornerRadius = 10
        barDescriptionDateLabel.textColor = .blackText
        barDescriptionDateLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionTotalBillTitleLabel.textColor = .blackText
        barDescriptionTotalBillTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionTotalBillValueLabel.textColor = .blackText
        barDescriptionTotalBillValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionUsageTitleLabel.textColor = .blackText
        barDescriptionUsageTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionUsageValueLabel.textColor = .blackText
        barDescriptionUsageValueLabel.font = OpenSans.regular.of(textStyle: .footnote)

        viewUsageButtonLabel.textColor = .actionBlue
        viewUsageButtonLabel.font = SystemFont.semibold.of(textStyle: .title1)
        viewUsageButtonLabel.text = NSLocalizedString("View Usage", comment: "")
        
        viewUsageEmptyStateButtonLabel.textColor = .actionBlue
        viewUsageEmptyStateButtonLabel.font = SystemFont.semibold.of(textStyle: .title1)
        viewUsageEmptyStateButtonLabel.text = NSLocalizedString("View Usage", comment: "")
    }
    
    private func styleSmartEnergyRewards() {
        smartEnergyRewardsTitleLabel.textColor = .blackText
        smartEnergyRewardsTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        smartEnergyRewardsTitleLabel.text = Environment.shared.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") :
            NSLocalizedString("Smart Energy Rewards", comment: "")
        
        smartEnergyRewardsSeasonLabel.textColor = .deepGray
        smartEnergyRewardsSeasonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        
        smartEnergyRewardsGrayBackgroundView.backgroundColor = .softGray
        
        smartEnergyRewardsFooterLabel.textColor = .blackText
        smartEnergyRewardsFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        smartEnergyRewardsFooterLabel.text = NSLocalizedString("You earn bill credits for every kWh you save. " +
            "We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use.", comment: "")
        
        viewAllSavingsButtonLabel.textColor = .actionBlue
        viewAllSavingsButtonLabel.font = SystemFont.semibold.of(textStyle: .title1)
        viewAllSavingsButtonLabel.text = NSLocalizedString("View All Savings", comment: "")
        
        smartEnergyRewardsEmptyStateTitleLabel.textColor = .blackText
        smartEnergyRewardsEmptyStateTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        smartEnergyRewardsEmptyStateTitleLabel.text = Environment.shared.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") :
            NSLocalizedString("Smart Energy Rewards", comment: "")
        
        smartEnergyRewardsEmptyStateDetailLabel.textColor = .middleGray
        smartEnergyRewardsEmptyStateDetailLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        smartEnergyRewardsEmptyStateDetailLabel.text = NSLocalizedString("As a \(smartEnergyRewardsEmptyStateTitleLabel.text!) customer, you can earn bill credits for every kWh you save. " +
            "We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent " +
            "\(smartEnergyRewardsEmptyStateTitleLabel.text!) season will display here once available.", comment: "")
    }
    
    private func showContent() {
        billComparisonView.isHidden = false
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
    }
    
    private func showSmartEnergyRewards() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = false
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
    }
    
    private func showSmartEnergyRewardsEmptyState() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = false
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = true
    }
    
    private func showBillComparisonEmptyState() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = false
        unavailableView.isHidden = true
    }
    
    private func showUnavailableState() {
        billComparisonView.isHidden = true
        smartEnergyRewardsView.isHidden = true
        smartEnergyRewardsEmptyStateView.isHidden = true
        billComparisonEmptyStateView.isHidden = true
        unavailableView.isHidden = false
    }
    
    private func bindViewModel() {
        viewModel.showLoadingState.drive(contentStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showLoadingState.not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showLoadingState
            .drive(onNext: { _ in UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil) })
            .disposed(by: disposeBag)
        
        // Bill Comparison vs. SER Show/Hide
        viewModel.showBillComparison
            .drive(onNext: { [weak self] in self?.showContent() })
            .disposed(by: disposeBag)
        
        viewModel.showSmartEnergyRewards
            .drive(onNext: { [weak self] in self?.showSmartEnergyRewards() })
            .disposed(by: disposeBag)
        
        viewModel.showSmartEnergyEmptyState
            .do(onNext: { Analytics.log(event: .emptyStateSmartEnergyHome) })
            .drive(onNext: { [weak self] in self?.showSmartEnergyRewardsEmptyState() })
            .disposed(by: disposeBag)
        
        viewModel.showBillComparisonEmptyState
            .do(onNext: { Analytics.log(event: .emptyStateUsageOverview) })
            .drive(onNext: { [weak self] in self?.showBillComparisonEmptyState() })
            .disposed(by: disposeBag)
        
        viewModel.showUnavailableState
            .drive(onNext: { [weak self] in self?.showUnavailableState() })
            .disposed(by: disposeBag)
        
        // --- Bill Comparison ---
        
        // Loading/Error/Content States
        
        viewModel.loadingTracker.asDriver().not().drive(comparisonLoadingView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showBillComparisonEmptyStateButton.not()
            .drive(viewUsageEmptyStateButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        // Segmented Controls
        viewModel.showElectricGasSegmentedControl.not()
            .drive(segmentedControl.rx.isHidden).disposed(by: disposeBag)
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().subscribe(onNext: { index in
            if index == 0 {
                Analytics.log(event: .viewUsageElectricity)
            } else {
                Analytics.log(event: .viewUsageGas)
            }
        }).disposed(by: disposeBag)
        
        viewModel.billComparisonEvents.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.moveTriangleTo(centerPoint: self.currentContainerButton.center)
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
            guard let `self` = self else { return }
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
    }
    
    @IBAction func onBarPress(sender: ButtonControl) {
        let centerPoint = sender.center
        moveTriangleTo(centerPoint: centerPoint)
        viewModel.setBarSelected(tag: sender.tag)
        userTappedBarGraph = true
    }
    
    private func moveTriangleTo(centerPoint: CGPoint) {
        let convertedPoint = barGraphStackView.convert(centerPoint, to: barDescriptionView)
        
        let centerXOffset = (barDescriptionView.bounds.width / 2)
        if convertedPoint.x < centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = -1 * (centerXOffset - convertedPoint.x)
        } else if convertedPoint.x > centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = convertedPoint.x - centerXOffset
        } else {
            barDescriptionTriangleCenterXConstraint.constant = 0
        }
    }
    
    // MARK: Bill Comparison Bar Graph Drivers
    private(set) lazy var noDataLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[0].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var previousLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[1].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var previousDollarLabelTextColor: Driver<UIColor> = self.viewModel.billComparisonDriver.map {
        guard let compared = $0.compared else { return .blackText }
        return compared.charges < 0 ? .successGreenText : .blackText
    }
    
    private(set) lazy var currentLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[2].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var currentDollarLabelTextColor: Driver<UIColor> = self.viewModel.billComparisonDriver.map {
        guard let reference = $0.reference else { return .blackText }
        return reference.charges < 0 ? .successGreenText : .blackText
    }

}
