//
//  BillAnalysisViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BillAnalysisViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var electricGasSegmentView: UIView!
    @IBOutlet weak var electricGasSegmentedControl: SegmentedControl!
    
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
        
    }
    
    private func styleViews() {
        scrollView.backgroundColor = .softGray
        
        electricGasSegmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        
        billComparisonTitleLabel.font = OpenSans.bold.of(textStyle: .title1)
        
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
        viewModel.noDataLabelFont.drive(noDataDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousLabelFont.drive(previousDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.previousLabelFont.drive(previousDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.currentLabelFont.drive(currentDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.currentLabelFont.drive(currentDateLabel.rx.font).disposed(by: disposeBag)
        viewModel.projectedLabelFont.drive(projectedDollarLabel.rx.font).disposed(by: disposeBag)
        viewModel.projectedLabelFont.drive(projectedDateLabel.rx.font).disposed(by: disposeBag)
       
        projectionNotAvailableDaysRemainingLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        projectionNotAvailableUntilNextForecastLabel.font = SystemFont.regular.of(textStyle: .footnote)
        viewModel.projectionNotAvailableLabelFont.drive(projectionNotAvailableDateLabel.rx.font).disposed(by: disposeBag)
    }
    
    private func styleLikelyReasonsButtons() {
        billPeriodTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        billPeriodTitleLabel.textColor = .deepGray
        billPeriodBubbleView.layer.cornerRadius = 17.5
        billPeriodBubbleView.layer.borderWidth = 2
        viewModel.billPeriodBorderColor.drive(billPeriodBubbleView.rx.borderColor).disposed(by: disposeBag)
        billPeriodBubbleView.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        billPeriodDollarLabel.font = SystemFont.medium.of(size: 16)
        billPeriodDollarLabel.textColor = .deepGray
        
        weatherTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        weatherTitleLabel.textColor = .deepGray
        weatherBubbleView.layer.cornerRadius = 17.5
        weatherBubbleView.layer.borderWidth = 2
        viewModel.weatherBorderColor.drive(weatherBubbleView.rx.borderColor).disposed(by: disposeBag)
        weatherBubbleView.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        weatherDollarLabel.font = SystemFont.medium.of(size: 16)
        weatherDollarLabel.textColor = .deepGray
        
        otherTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        otherTitleLabel.textColor = .deepGray
        otherBubbleView.layer.cornerRadius = 17.5
        otherBubbleView.layer.borderWidth = 2
        viewModel.otherBorderColor.drive(otherBubbleView.rx.borderColor).disposed(by: disposeBag)
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
        
        viewModel.setLikelyReasonSelected(tag: sender.tag)
    }
    
    
    
    



}
