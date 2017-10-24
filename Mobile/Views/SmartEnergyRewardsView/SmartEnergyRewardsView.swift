//
//  SmartEnergyRewardsView.swift
//  Mobile
//
//  Created by Marc Shilling on 10/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartEnergyRewardsView: UIView {
    
    var disposeBag = DisposeBag()

    @IBOutlet weak var view: UIView!
    
    @IBOutlet weak var barGraphStackView: UIStackView!
    
    @IBOutlet weak var bar1ContainerButton: ButtonControl!
    @IBOutlet weak var bar1DollarLabel: UILabel!
    @IBOutlet weak var bar1BarView: UIView!
    @IBOutlet weak var bar1DateLabel: UILabel!
    @IBOutlet weak var bar1HeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bar2ContainerButton: ButtonControl!
    @IBOutlet weak var bar2DollarLabel: UILabel!
    @IBOutlet weak var bar2BarView: UIView!
    @IBOutlet weak var bar2DateLabel: UILabel!
    @IBOutlet weak var bar2HeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bar3ContainerButton: ButtonControl!
    @IBOutlet weak var bar3DollarLabel: UILabel!
    @IBOutlet weak var bar3BarView: UIView!
    @IBOutlet weak var bar3DateLabel: UILabel!
    @IBOutlet weak var bar3HeightConstraint: NSLayoutConstraint!
    
    // Bill Comparison - Bar Graph Description View
    @IBOutlet weak var barDescriptionView: UIView!
    @IBOutlet weak var barDescriptionDateLabel: UILabel!
    @IBOutlet weak var barDescriptionPeakHoursLabel: UILabel!
    @IBOutlet weak var barDescriptionTypicalUseTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionTypicalUseValueLabel: UILabel!
    @IBOutlet weak var barDescriptionActualUseTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionActualUseValueLabel: UILabel!
    @IBOutlet weak var barDescriptionEnergySavingsTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionEnergySavingsValueLabel: UILabel!
    @IBOutlet weak var barDescriptionBillCreditTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionBillCreditValueLabel: UILabel!
    @IBOutlet weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    var viewModel: SmartEnergyRewardsViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
            onBarPress(sender: bar3ContainerButton)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(SmartEnergyRewardsView.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        backgroundColor = .clear
        
        styleViews()
    }
    
    private func styleViews() {
        // Bar Graph Text Colors
        bar1DollarLabel.textColor = .blackText
        bar1DateLabel.textColor = .blackText
        bar2DollarLabel.textColor = .blackText
        bar2DateLabel.textColor = .blackText
        bar3DollarLabel.textColor = .blackText
        bar3DateLabel.textColor = .blackText
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        barDescriptionDateLabel.textColor = .blackText
        barDescriptionDateLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionPeakHoursLabel.textColor = .blackText
        barDescriptionPeakHoursLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionTypicalUseTitleLabel.textColor = .blackText
        barDescriptionTypicalUseTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionTypicalUseValueLabel.textColor = .blackText
        barDescriptionTypicalUseValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionActualUseTitleLabel.textColor = .blackText
        barDescriptionActualUseTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionActualUseValueLabel.textColor = .blackText
        barDescriptionActualUseValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionEnergySavingsTitleLabel.textColor = .blackText
        barDescriptionEnergySavingsTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionEnergySavingsValueLabel.textColor = .blackText
        barDescriptionEnergySavingsValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionBillCreditTitleLabel.textColor = .blackText
        barDescriptionBillCreditTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionBillCreditValueLabel.textColor = .blackText
        barDescriptionBillCreditValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
    }
    
    private func bindViewModel() {
        viewModel.shouldShowBar1.not().drive(bar1ContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowBar2.not().drive(bar2ContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowBar3.not().drive(bar3ContainerButton.rx.isHidden).disposed(by: disposeBag)
        
        // Bar Graph Text Fonts
        bar1LabelFont.drive(bar1DollarLabel.rx.font).disposed(by: disposeBag)
        bar1LabelFont.drive(bar1DateLabel.rx.font).disposed(by: disposeBag)
        bar2LabelFont.drive(bar2DollarLabel.rx.font).disposed(by: disposeBag)
        bar2LabelFont.drive(bar2DateLabel.rx.font).disposed(by: disposeBag)
        bar3LabelFont.drive(bar3DollarLabel.rx.font).disposed(by: disposeBag)
        bar3LabelFont.drive(bar3DateLabel.rx.font).disposed(by: disposeBag)
        
        // Bar Graph Label Text
        viewModel.bar1DollarLabelText.drive(bar1DollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.bar1DateLabelText.drive(bar1DateLabel.rx.text).disposed(by: disposeBag)
        viewModel.bar2DollarLabelText.drive(bar2DollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.bar2DateLabelText.drive(bar2DateLabel.rx.text).disposed(by: disposeBag)
        viewModel.bar3DollarLabelText.drive(bar3DollarLabel.rx.text).disposed(by: disposeBag)
        viewModel.bar3DateLabelText.drive(bar3DateLabel.rx.text).disposed(by: disposeBag)
        
        // Bar height constraints
        viewModel.bar1HeightConstraintValue.drive(bar1HeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.bar2HeightConstraintValue.drive(bar2HeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.bar3HeightConstraintValue.drive(bar3HeightConstraint.rx.constant).disposed(by: disposeBag)
        
        // Bar description box
        viewModel.barDescriptionDateLabelText.drive(barDescriptionDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionPeakHoursLabelText.drive(barDescriptionPeakHoursLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionTypicalUseValueLabelText.drive(barDescriptionTypicalUseValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionActualUseValueLabelText.drive(barDescriptionActualUseValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionEnergySavingsValueLabelText.drive(barDescriptionEnergySavingsValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionBillCreditValueLabelText.drive(barDescriptionBillCreditValueLabel.rx.text).disposed(by: disposeBag)
    }
    
    @IBAction func onBarPress(sender: ButtonControl) {
        let centerPoint = sender.center
        moveTriangleTo(centerPoint: centerPoint)
        viewModel.setBarSelected(tag: sender.tag)
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
    private(set) lazy var bar1LabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[0].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var bar2LabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[1].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var bar3LabelFont: Driver<UIFont> = self.viewModel.barGraphSelectionStates.value[2].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }

}
