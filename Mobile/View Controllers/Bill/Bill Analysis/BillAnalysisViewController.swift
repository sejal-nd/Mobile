//
//  BillAnalysisViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import Charts

class BillAnalysisViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var electricGasSegmentView: UIView!
    @IBOutlet weak var electricGasSegmentedControl: SegmentedControl!
    
    // Current Charges Summary
    @IBOutlet weak var currentChargesSummaryView: UIView!
    @IBOutlet weak var currentChargesSummaryLabel: UILabel!
    @IBOutlet weak var currentChargesPieChartView: PieChartView!
    
    @IBOutlet weak var currentChargesLegendView: UIView!
    @IBOutlet weak var supplyLegendBox: UIView!
    @IBOutlet weak var supplyLegendLabel: UILabel!
    @IBOutlet weak var supplyValueLabel: UILabel!
    @IBOutlet weak var taxesFeesLegendBox: UIView!
    @IBOutlet weak var taxesFeesLegendLabel: UILabel!
    @IBOutlet weak var taxesFeesValueLabel: UILabel!
    @IBOutlet weak var deliveryLegendBox: UIView!
    @IBOutlet weak var deliveryLegendLabel: UILabel!
    @IBOutlet weak var deliveryValueLabel: UILabel!
    @IBOutlet weak var totalChargesLegendBox: UIView!
    @IBOutlet weak var totalChargesLegendLabel: UILabel!
    @IBOutlet weak var totalChargesValueLabel: UILabel!
    
    // Bill Comparison
    @IBOutlet weak var billComparisonTitleLabel: UILabel!
    @IBOutlet weak var billComparisonSegmentedControl: BillAnalysisSegmentedControl!
    
    @IBOutlet weak var billComparisonContentView: UIView!
    @IBOutlet weak var billComparisonLoadingView: UIView!
    @IBOutlet weak var billComparisonErrorView: UIView!
    @IBOutlet weak var billComparisonErrorLabel: UILabel!
    
    @IBOutlet weak var barGraphStackView: UIStackView!
    
    @IBOutlet weak var noDataContainerButton: ButtonControl!
    @IBOutlet weak var noDataBarView: UIView!
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var noDataDateLabel: UILabel!

    @IBOutlet weak var previousContainerButton: ButtonControl!
    @IBOutlet weak var previousDollarLabel: UILabel!
    @IBOutlet weak var previousBarView: UIView!
    @IBOutlet weak var previousDateLabel: UILabel!
    @IBOutlet weak var previousBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var currentContainerButton: ButtonControl!
    @IBOutlet weak var currentDollarLabel: UILabel!
    @IBOutlet weak var currentBarView: UIView!
    @IBOutlet weak var currentDateLabel: UILabel!
    @IBOutlet weak var currentBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var projectedContainerButton: ButtonControl!
    @IBOutlet weak var projectedDollarLabel: UILabel!
    @IBOutlet weak var projectedBarImage: UIImageView!
    @IBOutlet weak var projectedDateLabel: UILabel!
    @IBOutlet weak var projectedBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var projectionNotAvailableContainerButton: ButtonControl!
    @IBOutlet weak var projectionNotAvailableBarView: UIView!
    @IBOutlet weak var projectionNotAvailableDaysRemainingLabel: UILabel!
    @IBOutlet weak var projectionNotAvailableUntilNextForecastLabel: UILabel!
    @IBOutlet weak var projectionNotAvailableDateLabel: UILabel!
    
    @IBOutlet weak var barDescriptionView: UIView!
    @IBOutlet weak var barDescriptionDateLabel: UILabel!
    @IBOutlet weak var barDescriptionTempLabel: UILabel!
    @IBOutlet weak var barDescriptionDetailLabel: UILabel!
    @IBOutlet weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    // Likely Reasons
    @IBOutlet weak var likelyReasonsLabel: UILabel!
    
    @IBOutlet weak var likelyReasonsStackView: UIStackView!
    
    @IBOutlet var likelyReasonsNoDataLabels: [UILabel]!
    
    @IBOutlet weak var billPeriodContainerButton: ButtonControl!
    @IBOutlet weak var billPeriodTitleLabel: UILabel!
    @IBOutlet weak var billPeriodBubbleView: UIView!
    @IBOutlet weak var billPeriodUpDownImageView: UIImageView!
    
    @IBOutlet weak var weatherContainerButton: ButtonControl!
    @IBOutlet weak var weatherTitleLabel: UILabel!
    @IBOutlet weak var weatherBubbleView: UIView!
    @IBOutlet weak var weatherUpDownImageView: UIImageView!
    
    @IBOutlet weak var otherContainerButton: ButtonControl!
    @IBOutlet weak var otherTitleLabel: UILabel!
    @IBOutlet weak var otherBubbleView: UIView!
    @IBOutlet weak var otherUpDownImageView: UIImageView!
    
    @IBOutlet weak var likelyReasonsDescriptionContainerView: UIView!
    @IBOutlet weak var likelyReasonsDescriptionView: UIView!
    @IBOutlet weak var likelyReasonsDescriptionTitleLabel: UILabel!
    @IBOutlet weak var likelyReasonsDescriptionDetailLabel: UILabel!
    @IBOutlet weak var likelyReasonsDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var footerLabel: UILabel!
    
    let centerPieChartColor = UIColor(red: 89/255, green: 103/255, blue: 113/255, alpha: 1)
    
    let viewModel = BillAnalysisViewModel(usageService: ServiceFactory.createUsageService())
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let residentialAMIString = String(format: "%@%@", viewModel.accountDetail.isResidential ? "Residential/" : "Commercial/", viewModel.accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        Analytics().logScreenView(AnalyticsPageView.BillNeedHelp.rawValue, dimensionIndex: Dimensions.ResidentialAMI, dimensionValue: residentialAMIString)
        
        title = NSLocalizedString("Bill Analysis", comment: "")
        
        billComparisonSegmentedControl.setItems(leftLabel: NSLocalizedString("Last Year", comment: ""),
                                                rightLabel: NSLocalizedString("Previous Bill", comment: ""),
                                                initialSelectedIndex: 1)
        
        styleViews()
        bindViewModel()
        
        if UIScreen.main.bounds.size.width < 375 { // If smaller than iPhone 6 width
            barGraphStackView.spacing = 11
            likelyReasonsStackView.spacing = 8
        }
        
        // layoutIfNeeded() for the initial selection triangle positions
        barGraphStackView.layoutIfNeeded()
        likelyReasonsStackView.layoutIfNeeded()
        
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        onBarPress(sender: currentContainerButton) // Initial selection
        onLikelyReasonPress(sender: billPeriodContainerButton)
    }
    
    private func fetchData() {
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            self.viewModel.shouldShowProjectedBar.asObservable()
                .observeOn(MainScheduler.instance)
                .take(1)
                .subscribe(onNext: { [weak self] shouldShow in
                    guard let `self` = self else { return }
                    if shouldShow {
                        self.onBarPress(sender: self.projectedContainerButton)
                    } else {
                        self.onBarPress(sender: self.currentContainerButton)
                    }
                }).disposed(by: self.disposeBag)
        })
    }
    
    private func styleViews() {
        scrollView.backgroundColor = .softGray
        
        electricGasSegmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        if !viewModel.shouldShowElectricGasToggle {
            electricGasSegmentView.isHidden = true
        }
        
        currentChargesSummaryLabel.font = OpenSans.bold.of(textStyle: .title1)
        currentChargesSummaryLabel.textColor = .blackText
        currentChargesSummaryLabel.text = NSLocalizedString("Current Charges Summary", comment: "")
        
        if viewModel.shouldShowCurrentChargesSection {
            styleCurrentChargesSection()
        } else {
            currentChargesSummaryView.isHidden = true
        }
        
        billComparisonTitleLabel.font = OpenSans.bold.of(textStyle: .title1)
        billComparisonTitleLabel.textColor = .blackText
        billComparisonTitleLabel.text = NSLocalizedString("Bill Comparison", comment: "")
        
        billComparisonErrorLabel.font = SystemFont.regular.of(textStyle: .headline)
        billComparisonErrorLabel.textColor = .blackText
        billComparisonErrorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        styleBarGraph()
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        barDescriptionDateLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        barDescriptionDateLabel.textColor = .blackText
        barDescriptionTempLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionTempLabel.textColor = .blackText
        barDescriptionDetailLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionDetailLabel.textColor = .blackText
        
        likelyReasonsLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        likelyReasonsLabel.textColor = .blackText
        
        styleLikelyReasonsButtons()
        
        likelyReasonsDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        likelyReasonsDescriptionTitleLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        likelyReasonsDescriptionTitleLabel.textColor = .blackText
        likelyReasonsDescriptionDetailLabel.font = OpenSans.regular.of(textStyle: .footnote)
        likelyReasonsDescriptionDetailLabel.textColor = .blackText
        
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        footerLabel.textColor = .blackText
        footerLabel.text = NSLocalizedString("The amounts shown are usage-related charges and may not include credits and other adjustments. " +
            "Amounts for Budget Billing customers are based on actual usage in the period, not on your monthly budget payment.", comment: "")
    }
    
    private func styleCurrentChargesSection() {
        let supplyCharges = viewModel.accountDetail.billingInfo.supplyCharges ?? 0
        let taxesAndFees = viewModel.accountDetail.billingInfo.taxesAndFees ?? 0
        let deliveryCharges = viewModel.accountDetail.billingInfo.deliveryCharges ?? 0
        let totalCharges = supplyCharges + taxesAndFees + deliveryCharges
        
        // Pie Chart
        currentChargesPieChartView.legend.enabled = false // Hide the legend because we'll draw our own
        currentChargesPieChartView.chartDescription?.enabled = false // Hides the chart description
        currentChargesPieChartView.holeColor = centerPieChartColor
        currentChargesPieChartView.holeRadiusPercent = 0.71
        currentChargesPieChartView.transparentCircleRadiusPercent = 0.75
        currentChargesPieChartView.transparentCircleColor = .softGray
        
        let centerAttrText = NSMutableAttributedString(string: totalCharges.currencyString ?? "$0.00")
        centerAttrText.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: centerAttrText.length))
        centerAttrText.addAttribute(.font, value: OpenSans.semibold.of(size: 24), range: NSRange(location: 0, length: centerAttrText.length))
        currentChargesPieChartView.centerAttributedText = centerAttrText
        
        currentChargesPieChartView.accessibilityLabel = totalCharges.currencyString ?? "$0.00"
        
        var pieChartValues = [PieChartDataEntry]()
        var pieChartColors = [UIColor]()
        if supplyCharges > 0 {
            pieChartValues.append(PieChartDataEntry(value: supplyCharges))
            pieChartColors.append(.primaryColor)
        }
        if taxesAndFees > 0 {
            pieChartValues.append(PieChartDataEntry(value: taxesAndFees))
            pieChartColors.append(.blackText)
        }
        if deliveryCharges > 0 {
            pieChartValues.append(PieChartDataEntry(value: deliveryCharges))
            pieChartColors.append(.accentGray)
        }

        let dataSet = PieChartDataSet(values: pieChartValues, label: "Current Charges")
        dataSet.colors = pieChartColors
        dataSet.drawValuesEnabled = false
        dataSet.sliceSpace = 4
        let data = PieChartData(dataSet: dataSet)
        currentChargesPieChartView.data = data
        currentChargesPieChartView.notifyDataSetChanged()
        
        // Legend View
        currentChargesLegendView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        
        supplyLegendBox.backgroundColor = .accentGray
        supplyLegendLabel.textColor = .blackText
        supplyLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        supplyLegendLabel.text = NSLocalizedString("Supply", comment: "")
        supplyValueLabel.textColor = .blackText
        supplyValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        supplyValueLabel.text = supplyCharges.currencyString
        
        taxesFeesLegendBox.backgroundColor = .blackText
        taxesFeesLegendLabel.textColor = .blackText
        taxesFeesLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        taxesFeesLegendLabel.text = NSLocalizedString("Taxes & Fees", comment: "")
        taxesFeesValueLabel.textColor = .blackText
        taxesFeesValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        taxesFeesValueLabel.text = taxesAndFees.currencyString
        
        deliveryLegendBox.backgroundColor = .primaryColor
        deliveryLegendLabel.textColor = .blackText
        deliveryLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        deliveryLegendLabel.text = NSLocalizedString("Delivery", comment: "")
        deliveryValueLabel.textColor = .blackText
        deliveryValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        deliveryValueLabel.text = deliveryCharges.currencyString
        
        totalChargesLegendBox.backgroundColor = centerPieChartColor
        totalChargesLegendLabel.textColor = .deepGray
        totalChargesLegendLabel.font = OpenSans.bold.of(textStyle: .headline)
        totalChargesLegendLabel.text = NSLocalizedString("TOTAL CHARGES", comment: "")
        totalChargesValueLabel.textColor = .deepGray
        totalChargesValueLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        totalChargesValueLabel.text = totalCharges.currencyString
    }
    
    private func styleBarGraph() {
        let dashedBorderColor = UIColor(red: 0, green: 80/255, blue: 125/255, alpha: 0.24)
        noDataBarView.addDashedBorder(color: dashedBorderColor)
        previousBarView.backgroundColor = .primaryColor
        currentBarView.backgroundColor = .primaryColor
        projectionNotAvailableBarView.addDashedBorder(color: dashedBorderColor)
        
        switch Environment.sharedInstance.opco {
        case .bge:
            projectedBarImage.tintColor = UIColor(red: 0, green: 110/255, blue: 187/255, alpha: 1)
        case .comEd:
            projectedBarImage.tintColor = UIColor(red: 0, green: 145/255, blue: 182/255, alpha: 1)
        case .peco:
            projectedBarImage.tintColor = UIColor(red: 114/255, green: 184/255, blue: 101/255, alpha: 1)
        }
        
        // Bar Graph Text Colors
        noDataLabel.textColor = .deepGray
        noDataDateLabel.textColor = .blackText
        previousDollarLabel.textColor = .blackText
        previousDateLabel.textColor = .blackText
        currentDollarLabel.textColor = .blackText
        currentDateLabel.textColor = .blackText
        projectedDollarLabel.textColor = .blackText
        projectedDateLabel.textColor = .blackText
        projectionNotAvailableDaysRemainingLabel.textColor = .actionBlue
        projectionNotAvailableUntilNextForecastLabel.textColor = .deepGray
        projectionNotAvailableDateLabel.textColor = .blackText
        
        // Bar Graph Text Fonts
        noDataLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        noDataLabelFont.drive(noDataDateLabel.rx.font).disposed(by: disposeBag)
        previousLabelFont.drive(previousDollarLabel.rx.font).disposed(by: disposeBag)
        previousLabelFont.drive(previousDateLabel.rx.font).disposed(by: disposeBag)
        previousDollarLabelTextColor.drive(previousDollarLabel.rx.textColor).disposed(by: disposeBag)
        currentLabelFont.drive(currentDollarLabel.rx.font).disposed(by: disposeBag)
        currentLabelFont.drive(currentDateLabel.rx.font).disposed(by: disposeBag)
        currentDollarLabelTextColor.drive(currentDollarLabel.rx.textColor).disposed(by: disposeBag)
        projectedLabelFont.drive(projectedDollarLabel.rx.font).disposed(by: disposeBag)
        projectedLabelFont.drive(projectedDateLabel.rx.font).disposed(by: disposeBag)
       
        projectionNotAvailableDaysRemainingLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        projectionNotAvailableUntilNextForecastLabel.font = SystemFont.regular.of(textStyle: .footnote)
        projectionNotAvailableLabelFont.drive(projectionNotAvailableDateLabel.rx.font).disposed(by: disposeBag)
    }
    
    private func styleLikelyReasonsButtons() {
        billPeriodTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        billPeriodTitleLabel.textColor = .deepGray
        billPeriodBubbleView.layer.cornerRadius = 17.5
        billPeriodBubbleView.layer.borderWidth = 2
        billPeriodBorderColor.drive(billPeriodBubbleView.rx.borderColor).disposed(by: disposeBag)
        billPeriodBubbleView.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        
        weatherTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        weatherTitleLabel.textColor = .deepGray
        weatherBubbleView.layer.cornerRadius = 17.5
        weatherBubbleView.layer.borderWidth = 2
        weatherBorderColor.drive(weatherBubbleView.rx.borderColor).disposed(by: disposeBag)
        weatherBubbleView.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        
        otherTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        otherTitleLabel.textColor = .deepGray
        otherBubbleView.layer.cornerRadius = 17.5
        otherBubbleView.layer.borderWidth = 2
        otherBorderColor.drive(otherBubbleView.rx.borderColor).disposed(by: disposeBag)
        otherBubbleView.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        
        for label in likelyReasonsNoDataLabels {
            label.textColor = .deepGray
            label.font = SystemFont.medium.of(size: 16)
            label.text = NSLocalizedString("No data", comment: "")
        }
    }
    
    private func bindViewModel() {
        // Loading/Error/Content States
        viewModel.shouldShowBillComparisonContentView.not().drive(billComparisonContentView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isFetching.asDriver().not().drive(billComparisonLoadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(billComparisonErrorView.rx.isHidden).disposed(by: disposeBag)
        
        // Segmented Controls
        electricGasSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
        electricGasSegmentedControl.selectedIndex.asObservable().skip(1).distinctUntilChanged().subscribe(onNext: { [weak self] index in
            self?.fetchData()
            if index == 0 {
                Analytics().logScreenView(AnalyticsPageView.BillElectricityToggle.rawValue)
            } else {
                Analytics().logScreenView(AnalyticsPageView.BillGasToggle.rawValue)
            }
        }).disposed(by: disposeBag)
        billComparisonSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.lastYearPreviousBillSelectedSegmentIndex).disposed(by: disposeBag)
        billComparisonSegmentedControl.selectedIndex.asObservable().skip(1).distinctUntilChanged().subscribe(onNext: { [weak self] index in
            self?.fetchData()
            if index == 0 {
                Analytics().logScreenView(AnalyticsPageView.BillLastYearToggle.rawValue)
            } else {
                Analytics().logScreenView(AnalyticsPageView.BillPreviousToggle.rawValue)
            }
        }).disposed(by: disposeBag)
        
        // Bar graph height constraints
        viewModel.previousBarHeightConstraintValue.drive(previousBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.currentBarHeightConstraintValue.drive(currentBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.projectedBarHeightConstraintValue.drive(projectedBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        
        // Bar show/hide
        viewModel.noPreviousData.asDriver().not().drive(noDataContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().drive(previousContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowProjectedBar.not().drive(projectedContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowProjectionNotAvailableBar.not().drive(projectionNotAvailableContainerButton.rx.isHidden).disposed(by: disposeBag)
        
        // Bar labels
        viewModel.noDataBarDateLabelText.drive(noDataDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.previousBarDollarLabelText.drive(previousDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.previousBarDateLabelText.drive(previousDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.currentBarDollarLabelText.drive(currentDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.currentBarDateLabelText.drive(currentDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDollarLabelText.drive(projectedDollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDateLabelText.drive(projectedDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDateLabelText.drive(projectionNotAvailableDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionNotAvailableDaysRemainingText.drive(projectionNotAvailableDaysRemainingLabel.rx.text).disposed(by: disposeBag)
        
        // Bar accessibility
        viewModel.noDataBarA11yLabel.drive(noDataContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.previousBarA11yLabel.drive(previousContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.currentBarA11yLabel.drive(currentContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.projectedBarA11yLabel.drive(projectedContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.projectionNotAvailableA11yLabel.drive(projectionNotAvailableContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        Observable.combineLatest(viewModel.noPreviousData.asObservable(), viewModel.shouldShowProjectedBar.asObservable(), viewModel.shouldShowProjectionNotAvailableBar.asObservable()).map { [weak self] in
            guard let `self` = self else { return }
            var a11yElementArray: [ButtonControl] = []
            if $0.0 {
                a11yElementArray.append(self.noDataContainerButton)
            } else {
                a11yElementArray.append(self.previousContainerButton)
            }
            a11yElementArray.append(self.currentContainerButton)
            if $0.1 {
                a11yElementArray.append(self.projectedContainerButton)
            }
            if $0.2 {
                a11yElementArray.append(self.projectionNotAvailableContainerButton)
            }
            self.barGraphStackView.accessibilityElements = a11yElementArray
        }.subscribe().disposed(by: disposeBag)
        
        // Bar description labels
        viewModel.barDescriptionDateLabelText.drive(barDescriptionDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionAvgTempLabelText.drive(barDescriptionTempLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionDetailLabelText.drive(barDescriptionDetailLabel.rx.text).disposed(by: disposeBag)
        
        // Likely reasons
        viewModel.billPeriodArrowImage.drive(billPeriodUpDownImageView.rx.image).disposed(by: disposeBag)
        viewModel.billPeriodA11yLabel.drive(billPeriodContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.weatherArrowImage.drive(weatherUpDownImageView.rx.image).disposed(by: disposeBag)
        viewModel.weatherA11yLabel.drive(weatherContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.otherArrowImage.drive(otherUpDownImageView.rx.image).disposed(by: disposeBag)
        viewModel.otherA11yLabel.drive(otherContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        viewModel.likelyReasonsLabelText.drive(likelyReasonsLabel.rx.text).disposed(by: disposeBag)
        viewModel.likelyReasonsDescriptionTitleText.drive(likelyReasonsDescriptionTitleLabel.rx.text).disposed(by: disposeBag)
        viewModel.likelyReasonsDescriptionDetailText.drive(likelyReasonsDescriptionDetailLabel.rx.text).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().drive(likelyReasonsDescriptionContainerView.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().drive(billPeriodUpDownImageView.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().drive(weatherUpDownImageView.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().drive(otherUpDownImageView.rx.isHidden).disposed(by: disposeBag)
        for label in likelyReasonsNoDataLabels {
            viewModel.noPreviousData.asDriver().not().drive(label.rx.isHidden).disposed(by: disposeBag)
        }
        viewModel.noPreviousData.asDriver().not().drive(billPeriodContainerButton.rx.isAccessibilityElement).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().not().drive(weatherContainerButton.rx.isAccessibilityElement).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().not().drive(otherContainerButton.rx.isAccessibilityElement).disposed(by: disposeBag)
    }
    
    @IBAction func onBarPress(sender: ButtonControl) {
        let centerPoint = sender.center
        let convertedPoint = barGraphStackView.convert(centerPoint, to: barDescriptionView)

        let centerXOffset = (barDescriptionView.bounds.width / 2)
        if convertedPoint.x < centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = -1 * (centerXOffset - convertedPoint.x)
        } else if convertedPoint.x > centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = convertedPoint.x - centerXOffset
        } else {
            barDescriptionTriangleCenterXConstraint.constant = 0
        }
        
        viewModel.setBarSelected(tag: sender.tag)
    }
    
    @IBAction func onLikelyReasonPress(sender: ButtonControl) {
        let centerPoint = sender.center
        let convertedPoint = likelyReasonsStackView.convert(centerPoint, to: likelyReasonsDescriptionView)
        
        let centerXOffset = (likelyReasonsDescriptionView.bounds.width / 2)
        if convertedPoint.x < centerXOffset {
            likelyReasonsDescriptionTriangleCenterXConstraint.constant = -1 * (centerXOffset - convertedPoint.x)
        } else if convertedPoint.x > centerXOffset {
            likelyReasonsDescriptionTriangleCenterXConstraint.constant = convertedPoint.x - centerXOffset
        } else {
            likelyReasonsDescriptionTriangleCenterXConstraint.constant = 0
        }
        
        if sender.tag == 0 {
            Analytics().logScreenView(AnalyticsPageView.BillPreviousReason.rawValue)
        } else if sender.tag == 1 {
            Analytics().logScreenView(AnalyticsPageView.BillWeatherReason.rawValue)
        } else {
            Analytics().logScreenView(AnalyticsPageView.BillOtherReason.rawValue)
        }
        
        viewModel.setLikelyReasonSelected(tag: sender.tag)
    }
    
    // NOTE: I've put the color drivers in the view controller because our custom colors (i.e. `primaryColor`) are not included
    // in the test target, but the viewModel needs to be included in the test target
    
    // MARK: Bill Comparison Bar Graph Drivers
    private(set) lazy var noDataLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[0].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var previousLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[1].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var previousDollarLabelTextColor: Driver<UIColor> = self.viewModel.currentBillComparison.asDriver().map {
        guard let compared = $0?.compared else { return .blackText }
        return compared.charges < 0 ? .successGreenText : .blackText
    }
    
    private(set) lazy var currentLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[2].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var currentDollarLabelTextColor: Driver<UIColor> = self.viewModel.currentBillComparison.asDriver().map {
        guard let reference = $0?.reference else { return .blackText }
        return reference.charges < 0 ? .successGreenText : .blackText
    }
    
    private(set) lazy var projectedLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[3].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var projectionNotAvailableLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[4].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    // MARK: Likely Reasons Border Color Drivers
    private(set) lazy var billPeriodBorderColor: Driver<CGColor> =
        Driver.combineLatest(self.viewModel.likelyReasonsSelectionStates.value[0].asDriver(), self.viewModel.noPreviousData.asDriver()) {
            $0 && !$1 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
        }
    
    private(set) lazy var weatherBorderColor: Driver<CGColor> =
        Driver.combineLatest(self.viewModel.likelyReasonsSelectionStates.value[1].asDriver(), self.viewModel.noPreviousData.asDriver()) {
            $0 && !$1 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
        }
    
    private(set) lazy var otherBorderColor: Driver<CGColor> =
        Driver.combineLatest(self.viewModel.likelyReasonsSelectionStates.value[2].asDriver(), self.viewModel.noPreviousData.asDriver()) {
            $0 && !$1 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
        }
    
}
