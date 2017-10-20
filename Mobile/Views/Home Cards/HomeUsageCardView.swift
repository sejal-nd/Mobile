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
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var segmentedControl: BillAnalysisSegmentedControl!
    
    @IBOutlet weak var billComparisonContentView: UIView!

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
    
    @IBOutlet weak var barDescriptionView: UIView!
    @IBOutlet weak var barDescriptionDateLabel: UILabel!
    @IBOutlet weak var barDescriptionTotalBillTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionTotalBillValueLabel: UILabel!
    @IBOutlet weak var barDescriptionUsageTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionUsageValueLabel: UILabel!
    
    @IBOutlet weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var viewUsageButton: UIButton!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
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
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmentedControl.setItems(leftLabel: NSLocalizedString("Electricity", comment: ""),
                                  rightLabel: NSLocalizedString("Gas", comment: ""),
                                  initialSelectedIndex: 0)
        
        stackView.bringSubview(toFront: segmentedControl)
    
        styleViews()
    }
    
    func superviewDidLayoutSubviews() {
        // We use this to appropriately position to initial selection triangle, and then to stop
        // receiving layout events after the user manually tapped a button, otherwise the
        // initial selection bar would never be able to be deselected
        if !userTappedBarGraph {
            moveTriangleTo(centerPoint: currentContainerButton.center)
        }
    }
    
    private func styleViews() {
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.cornerRadius = 2
        
        titleLabel.textColor = .blackText
        titleLabel.font = OpenSans.semibold.of(size: 18)
        
        errorLabel.font = OpenSans.regular.of(textStyle: .title1)
        errorLabel.setLineHeight(lineHeight: 26)
        errorLabel.textAlignment = .center
        errorLabel.textColor = .middleGray
        errorLabel.text = NSLocalizedString("Your usage overview will be available here once we have more data.", comment: "")
        
        billComparisonContentView.backgroundColor = .softGray
        
        styleBarGraph()
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
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

        viewUsageButton.setTitleColor(.actionBlue, for: .normal)
        viewUsageButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)

    }
    
    private func styleBarGraph() {
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
    }
    
    private func bindViewModel() {
        // Loading/Error/Content States
        viewModel.shouldShowBillComparisonContentView.not().drive(billComparisonContentView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.loadingTracker.asDriver().not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorView.not().drive(errorView.rx.isHidden).disposed(by: disposeBag)
        
        // Segmented Controls
        viewModel.shouldShowElectricGasSegmentedControl.not().drive(segmentedControl.rx.isHidden).disposed(by: disposeBag)
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
        viewModel.billComparisonEvents.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.moveTriangleTo(centerPoint: self.currentContainerButton.center)
            self.viewModel.setBarSelected(tag: 2)
        }).disposed(by: disposeBag)
        
        // Bar graph height constraints
        viewModel.previousBarHeightConstraintValue.drive(previousBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.currentBarHeightConstraintValue.drive(currentBarHeightConstraint.rx.constant).disposed(by: disposeBag)

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
        
        // Bar description
        viewModel.barDescriptionDateLabelText.drive(barDescriptionDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionTotalBillValueLabelText.drive(barDescriptionTotalBillValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionUsageValueLabelText.drive(barDescriptionUsageValueLabel.rx.text).disposed(by: disposeBag)
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
