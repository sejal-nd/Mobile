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
    @IBOutlet weak var currentChargesBreakdownView: UIView!
    
    // Bill Comparison
    @IBOutlet weak var billComparisonTitleLabel: UILabel!
    @IBOutlet weak var billComparisonSegmentedControl: BillAnalysisSegmentedControl!
    @IBOutlet weak var barGraphStackView: UIStackView!
    
    @IBOutlet weak var noDataContainerButton: ButtonControl!
    @IBOutlet weak var noDataBarView: UIView!
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var noDataDateLabel: UILabel!

    @IBOutlet weak var previousContainerButton: ButtonControl!
    @IBOutlet weak var previousDollarLabel: UILabel!
    @IBOutlet weak var previousBarView: UIView!
    @IBOutlet weak var previousDateLabel: UILabel!
    
    @IBOutlet weak var currentContainerButton: ButtonControl!
    @IBOutlet weak var currentDollarLabel: UILabel!
    @IBOutlet weak var currentBarView: UIView!
    @IBOutlet weak var currentDateLabel: UILabel!
    
    @IBOutlet weak var projectedContainerButton: ButtonControl!
    @IBOutlet weak var projectedDollarLabel: UILabel!
    @IBOutlet weak var projectedBarImage: UIImageView!
    @IBOutlet weak var projectedDateLabel: UILabel!
    
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
    
    @IBOutlet weak var billPeriodContainerButton: ButtonControl!
    @IBOutlet weak var billPeriodTitleLabel: UILabel!
    @IBOutlet weak var billPeriodBubbleView: UIView!
    @IBOutlet weak var billPeriodUpDownImageView: UIImageView!
    @IBOutlet weak var billPeriodDollarLabel: UILabel!
    
    @IBOutlet weak var weatherContainerButton: ButtonControl!
    @IBOutlet weak var weatherTitleLabel: UILabel!
    @IBOutlet weak var weatherBubbleView: UIView!
    @IBOutlet weak var weatherUpDownImageView: UIImageView!
    @IBOutlet weak var weatherDollarLabel: UILabel!
    
    @IBOutlet weak var otherContainerButton: ButtonControl!
    @IBOutlet weak var otherTitleLabel: UILabel!
    @IBOutlet weak var otherBubbleView: UIView!
    @IBOutlet weak var otherUpDownImageView: UIImageView!
    @IBOutlet weak var otherDollarLabel: UILabel!
    
    @IBOutlet weak var likelyReasonsDescriptionView: UIView!
    @IBOutlet weak var likelyReasonsDescriptionTitleLabel: UILabel!
    @IBOutlet weak var likelyReasonsDescriptionDetailLabel: UILabel!
    @IBOutlet weak var likelyReasonsDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var footerLabel: UILabel!
    
    
    let viewModel = BillAnalysisViewModel(usageService: ServiceFactory.createUsageService())
    
    init() {
        super.init(nibName: BillAnalysisViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Bill Analysis", comment: "")
        
        billComparisonSegmentedControl.setItems(leftLabel: NSLocalizedString("Last Year", comment: ""), rightLabel: NSLocalizedString("Previous Bill", comment: ""), initialSelectedIndex: 1)
        
        styleViews()
        
        previousContainerButton.isHidden = true
        currentContainerButton.isHidden = true
        //projectionNotAvailableContainerButton.isHidden = true
        
        if UIScreen.main.bounds.size.width < 375 { // If smaller than iPhone 6 width
            barGraphStackView.spacing = 11
            likelyReasonsStackView.spacing = 8
        }
        
        barGraphStackView.layoutIfNeeded() // Needed for the initial selection triangle position
        likelyReasonsStackView.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        onBarPress(sender: projectedContainerButton) // Initial selection
        onLikelyReasonPress(sender: billPeriodContainerButton)
    }
    
    private func styleViews() {
        scrollView.backgroundColor = .softGray
        
        electricGasSegmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        
        currentChargesSummaryLabel.font = OpenSans.bold.of(textStyle: .title1)
        currentChargesSummaryLabel.textColor = .blackText
        currentChargesSummaryLabel.text = NSLocalizedString("Current Charges Summary", comment: "")
        
        stylePieChart()
        styleCurrentChargesBreakdownView()
        
        billComparisonTitleLabel.font = OpenSans.bold.of(textStyle: .title1)
        billComparisonTitleLabel.textColor = .blackText
        billComparisonTitleLabel.text = NSLocalizedString("Bill Comparison", comment: "")
        
        styleBarGraph()
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        barDescriptionDateLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        barDescriptionDateLabel.textColor = .blackText
        barDescriptionTempLabel.font = OpenSans.semibold.of(textStyle: .footnote)
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
    }
    
    private func styleCurrentChargesBreakdownView() {
        currentChargesBreakdownView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
    }
    
    private func stylePieChart() {
        let entry1 = PieChartDataEntry(value: Double(25.98))
        let entry2 = PieChartDataEntry(value: Double(6.46))
        let entry3 = PieChartDataEntry(value: Double(30.96))
        let dataSet = PieChartDataSet(values: [entry1, entry2, entry3], label: "Current Charges")
        dataSet.colors = [.accentGray, .blackText, .primaryColor]
        dataSet.drawValuesEnabled = false
        dataSet.highlightEnabled = false // Disable selection
        let data = PieChartData(dataSet: dataSet)
        currentChargesPieChartView.data = data
        
        currentChargesPieChartView.legend.enabled = false // Hide the legend because we'll draw our own
        //currentChargesPieChartView.drawSlicesUnderHoleEnabled = false
        currentChargesPieChartView.chartDescription?.enabled = false // Hides the chart description
        currentChargesPieChartView.holeColor = UIColor(red: 89/255, green: 103/255, blue: 113/255, alpha: 1)
        currentChargesPieChartView.holeRadiusPercent = 0.70
        currentChargesPieChartView.transparentCircleRadiusPercent = 0.75
        currentChargesPieChartView.transparentCircleColor = .softGray

        let centerAttrText = NSMutableAttributedString(string:"$63.40")
        centerAttrText.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: NSRange(location: 0, length: 6))
        centerAttrText.addAttribute(NSFontAttributeName, value: OpenSans.semibold.of(size: 24), range: NSRange(location: 0, length: 6))
        currentChargesPieChartView.centerAttributedText = centerAttrText

        currentChargesPieChartView.notifyDataSetChanged()
    }
    
    private func styleBarGraph() {
        let dashedBorderColor = UIColor(red: 0, green: 80/255, blue: 125/255, alpha: 0.24)
        noDataBarView.addDashedBorder(color: dashedBorderColor)
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
        currentLabelFont.drive(currentDollarLabel.rx.font).disposed(by: disposeBag)
        currentLabelFont.drive(currentDateLabel.rx.font).disposed(by: disposeBag)
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
        billPeriodDollarLabel.font = SystemFont.medium.of(size: 16)
        billPeriodDollarLabel.textColor = .deepGray
        
        weatherTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        weatherTitleLabel.textColor = .deepGray
        weatherBubbleView.layer.cornerRadius = 17.5
        weatherBubbleView.layer.borderWidth = 2
        weatherBorderColor.drive(weatherBubbleView.rx.borderColor).disposed(by: disposeBag)
        weatherBubbleView.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        weatherDollarLabel.font = SystemFont.medium.of(size: 16)
        weatherDollarLabel.textColor = .deepGray
        
        otherTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        otherTitleLabel.textColor = .deepGray
        otherBubbleView.layer.cornerRadius = 17.5
        otherBubbleView.layer.borderWidth = 2
        otherBorderColor.drive(otherBubbleView.rx.borderColor).disposed(by: disposeBag)
        otherBubbleView.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        otherDollarLabel.font = SystemFont.medium.of(size: 16)
        otherDollarLabel.textColor = .deepGray
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
        
        viewModel.setLikelyReasonSelected(tag: sender.tag)
    }
    
    // MARK: Bill Comparison Bar Graph Drivers
    private(set) lazy var noDataLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates[0].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var previousLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates[1].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var currentLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates[2].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var projectedLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates[3].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var projectionNotAvailableLabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates[4].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    // MARK: Likely Reasons Border Color Drivers
    private(set) lazy var billPeriodBorderColor: Driver<CGColor> = self.viewModel.likelyReasonsSelectionStates[0].asDriver().map {
        $0 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
    private(set) lazy var weatherBorderColor: Driver<CGColor> = self.viewModel.likelyReasonsSelectionStates[1].asDriver().map {
        $0 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
    private(set) lazy var otherBorderColor: Driver<CGColor> = self.viewModel.likelyReasonsSelectionStates[2].asDriver().map {
        $0 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
}
