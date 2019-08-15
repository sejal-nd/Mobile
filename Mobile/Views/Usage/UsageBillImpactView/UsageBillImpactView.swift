//
//  UsageBillImpactView.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UsageBillImpactView: UIView {

    @IBOutlet private weak var view: UIView!
    @IBOutlet weak var reasonsWhyLabel: UILabel! {
        didSet {
            reasonsWhyLabel.textColor = .deepGray
            reasonsWhyLabel.font = OpenSans.regular.of(textStyle: .headline)
        }
    }
    @IBOutlet weak var tooltipButton: UIButton!
    @IBOutlet weak var elecGasSegmentedControl: SegmentedControlNew! {
        didSet {
            elecGasSegmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        }
    }
    
    @IBOutlet weak var differenceDescriptionLabel: UILabel! {
        didSet {
            differenceDescriptionLabel.textColor = .deepGray
            differenceDescriptionLabel.font = OpenSans.regular.of(textStyle: .callout)
        }
    }
    
    @IBOutlet weak var comparisonToggleButton: SecondaryButton!
    
    @IBOutlet weak var dropdownView: UIView!
    
    @IBOutlet weak var billPeriodTapView: UIView!
    @IBOutlet weak var billPeriodTitleLabel: UILabel! {
        didSet {
            billPeriodTitleLabel.textColor = .deepGray
            billPeriodTitleLabel.font = SystemFont.regular.of(textStyle: .caption2)
        }
    }
    @IBOutlet weak var billPeriodImageView: UIImageView!
    @IBOutlet weak var billPeriodAmountLabel: UILabel! {
        didSet {
            billPeriodAmountLabel.textColor = .deepGray
            billPeriodAmountLabel.font = SystemFont.regular.of(textStyle: .callout)
        }
    }
    @IBOutlet weak var billPeriodCaretImageView: UIImageView!
    @IBOutlet weak var billPeriodDetailView: UIView!
    @IBOutlet weak var billPeriodDetailLabel: UILabel! {
        didSet {
            billPeriodDetailLabel.textColor = .deepGray
            billPeriodDetailLabel.font = SystemFont.regular.of(textStyle: .caption1)
        }
    }
    
    @IBOutlet weak var weatherTapView: UIView!
    @IBOutlet weak var weatherTitleLabel: UILabel! {
        didSet {
            weatherTitleLabel.textColor = .deepGray
            weatherTitleLabel.font = SystemFont.regular.of(textStyle: .caption2)
        }
    }
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var weatherAmountLabel: UILabel! {
        didSet {
            weatherAmountLabel.textColor = .deepGray
            weatherAmountLabel.font = SystemFont.regular.of(textStyle: .callout)
        }
    }
    @IBOutlet weak var weatherCaretImageView: UIImageView!
    @IBOutlet weak var weatherDetailView: UIView!
    @IBOutlet weak var weatherDetailLabel: UILabel! {
        didSet {
            weatherDetailLabel.textColor = .deepGray
            weatherDetailLabel.font = SystemFont.regular.of(textStyle: .caption1)
        }
    }
    
    @IBOutlet weak var otherTapView: UIView!
    @IBOutlet weak var otherTitleLabel: UILabel! {
        didSet {
            otherTitleLabel.textColor = .deepGray
            otherTitleLabel.font = SystemFont.regular.of(textStyle: .caption2)
        }
    }
    @IBOutlet weak var otherImageView: UIImageView!
    @IBOutlet weak var otherAmountLabel: UILabel! {
        didSet {
            otherAmountLabel.textColor = .deepGray
            otherAmountLabel.font = SystemFont.regular.of(textStyle: .callout)
        }
    }
    @IBOutlet weak var otherCaretImageView: UIImageView!
    @IBOutlet weak var otherDetailView: UIView!
    @IBOutlet weak var otherDetailLabel: UILabel! {
        didSet {
            otherDetailLabel.textColor = .deepGray
            otherDetailLabel.font = SystemFont.regular.of(textStyle: .caption1)
        }
    }
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var bottomSpacer: UIView!
    
    private let disposeBag = DisposeBag()
    
    let billPeriodExpanded = BehaviorRelay(value: false)
    let weatherExpanded = BehaviorRelay(value: false)
    let otherExpanded = BehaviorRelay(value: false)
    
//    private var isExpanded = false {
//        didSet {
//            guard hasLoadedView else { return }
//            UIView.animate(withDuration: 0.3, animations: { [weak self] in
//                if let isExpanded = self?.isExpanded, isExpanded {
//                    self?.billFactorView.isHidden = false
//                    self?.carrotImageView.image = #imageLiteral(resourceName: "ic_caret_up")
//                } else {
//                    self?.billFactorView.isHidden = true
//                    self?.carrotImageView.image = #imageLiteral(resourceName: "ic_caret_down")
//                }
//                self?.contentStackView.layoutIfNeeded()
//            })
//        }
//    }
    
    private var viewModel: BillViewModel?
    
    private var hasLoadedView = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("UsageBillImpactView", owner: self, options: nil)
        addSubview(view)
        view.frame = bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        loadingView.isHidden = true
        
        let billPeriodTap = UITapGestureRecognizer(target: self, action: #selector(onBillPeriodTap))
        billPeriodTapView.addGestureRecognizer(billPeriodTap)
        let weatherTap = UITapGestureRecognizer(target: self, action: #selector(onWeatherTap))
        weatherTapView.addGestureRecognizer(weatherTap)
        let otherTap = UITapGestureRecognizer(target: self, action: #selector(onOtherTap))
        otherTapView.addGestureRecognizer(otherTap)
    }
    
    func superviewDidLayoutSubviews() {
        // Fixes layout issues with segmented control
        elecGasSegmentedControl.selectIndex(elecGasSegmentedControl.selectedIndex.value, animated: false)
        hasLoadedView = true
    }
    
    func configure(withViewModel viewModel: BillViewModel) {
        self.viewModel = viewModel
        bindViewModel(viewModel)
    }
    
    func bindViewModel(_ viewModel: BillViewModel) {
        viewModel.reasonsWhyLabelText.drive(reasonsWhyLabel.rx.text).disposed(by: disposeBag)
        
        viewModel.showElectricGasSegmentedControl.not().drive(elecGasSegmentedControl.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.differenceDescriptionLabelAttributedText.drive(differenceDescriptionLabel.rx.attributedText).disposed(by: disposeBag)
        
        billPeriodExpanded.asDriver().drive(onNext: { [weak self] expanded in
            self?.billPeriodDetailView.isHidden = !expanded
            self?.billPeriodCaretImageView.image = expanded ? #imageLiteral(resourceName: "ic_caret_up.pdf") : #imageLiteral(resourceName: "ic_caret_down.pdf")
        }).disposed(by: disposeBag)
        viewModel.billPeriodArrowImage.drive(billPeriodImageView.rx.image).disposed(by: disposeBag)
        viewModel.currentBillComparison.map { abs($0.billPeriodCostDifference).currencyString }.drive(billPeriodAmountLabel.rx.text).disposed(by: disposeBag)
        viewModel.billPeriodDetailLabelText.drive(billPeriodDetailLabel.rx.text).disposed(by: disposeBag)
        
        weatherExpanded.asDriver().drive(onNext: { [weak self] expanded in
            self?.weatherDetailView.isHidden = !expanded
            self?.weatherCaretImageView.image = expanded ? #imageLiteral(resourceName: "ic_caret_up.pdf") : #imageLiteral(resourceName: "ic_caret_down.pdf")
        }).disposed(by: disposeBag)
        viewModel.weatherArrowImage.drive(weatherImageView.rx.image).disposed(by: disposeBag)
        viewModel.currentBillComparison.map { abs($0.weatherCostDifference).currencyString }.drive(weatherAmountLabel.rx.text).disposed(by: disposeBag)
        viewModel.weatherDetailLabelText.drive(weatherDetailLabel.rx.text).disposed(by: disposeBag)
        
        otherExpanded.asDriver().drive(onNext: { [weak self] expanded in
            self?.otherDetailView.isHidden = !expanded
            self?.otherCaretImageView.image = expanded ? #imageLiteral(resourceName: "ic_caret_up.pdf") : #imageLiteral(resourceName: "ic_caret_down.pdf")
        }).disposed(by: disposeBag)
        viewModel.otherArrowImage.drive(otherImageView.rx.image).disposed(by: disposeBag)
        viewModel.currentBillComparison.map { abs($0.otherCostDifference).currencyString }.drive(otherAmountLabel.rx.text).disposed(by: disposeBag)
        viewModel.otherDetailLabelText.drive(otherDetailLabel.rx.text).disposed(by: disposeBag)
        
        viewModel.electricGasSelectedSegmentIndex.asDriver()
            .distinctUntilChanged()
            .drive(elecGasSegmentedControl.selectedIndex)
            .disposed(by: disposeBag)
        
        elecGasSegmentedControl.selectedIndex.asDriver()
            .distinctUntilChanged()
            .filter { _ in self.hasLoadedView }
            .do(onNext: { [weak self] _ in self?.setInnerLoadingState(true) })
            .drive(viewModel.electricGasSelectedSegmentIndex)
            .disposed(by: disposeBag)
        
        viewModel.compareToLastYear.asDriver().drive(onNext: { [weak self] lastYear in
            let title = lastYear ? NSLocalizedString("Compare to Previous Bill", comment: "") :
                NSLocalizedString("Compare to Last Year", comment: "")
            UIView.performWithoutAnimation {
                self?.comparisonToggleButton.setTitle(title, for: .normal)
                self?.comparisonToggleButton.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)
        
        viewModel.showUsageBillImpactInnerError.drive(onNext: { [weak self] in
            self?.loadingView.isHidden = true
            self?.differenceDescriptionLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
            self?.bottomSpacer.isHidden = false
        }).disposed(by: disposeBag)
        
        // Likely reasons
//        viewModel.billPeriodArrowImage.drive(billPeriodUpDownImageView.rx.image).disposed(by: disposeBag)
//        viewModel.billPeriodA11yLabel.drive(billPeriodButton.rx.accessibilityLabel).disposed(by: disposeBag)
//        viewModel.weatherArrowImage.drive(weatherUpDownImageView.rx.image).disposed(by: disposeBag)
//        viewModel.weatherA11yLabel.drive(weatherButton.rx.accessibilityLabel).disposed(by: disposeBag)
//        viewModel.otherArrowImage.drive(otherUpDownImageView.rx.image).disposed(by: disposeBag)
//        viewModel.otherA11yLabel.drive(otherButton.rx.accessibilityLabel).disposed(by: disposeBag)
//
//        viewModel.likelyReasonsLabelText.drive(descriptionLabel.rx.text).disposed(by: disposeBag)
//        viewModel.likelyReasonsDescriptionTitleText.drive(bubbleViewTitleLabel.rx.text).disposed(by: disposeBag)
//        viewModel.likelyReasonsDescriptionDetailText.drive(bubbleViewDescriptionLabel.rx.text).disposed(by: disposeBag)
//        viewModel.noPreviousData.drive(likelyReasonsDescriptionView.rx.isHidden).disposed(by: disposeBag)
//        viewModel.noPreviousData.drive(billPeriodUpDownImageView.rx.isHidden).disposed(by: disposeBag)
//        viewModel.noPreviousData.drive(weatherUpDownImageView.rx.isHidden).disposed(by: disposeBag)
//        viewModel.noPreviousData.drive(otherUpDownImageView.rx.isHidden).disposed(by: disposeBag)
//        for label in likelyReasonsNoDataLabels {
//            viewModel.noPreviousData.not().drive(label.rx.isHidden).disposed(by: disposeBag)
//        }
//
//        Driver.combineLatest(viewModel.likelyReasonsSelection.asDriver().distinctUntilChanged(),
//                             viewModel.noPreviousData.distinctUntilChanged())
//            .drive(onNext: { [weak self] likelyReasonsSelection, noPreviousData in
//                self?.updateLikelyReasonsSelection(noPreviousData ? nil : likelyReasonsSelection)
//            })
//            .disposed(by: disposeBag)
//
//        viewModel.noPreviousData.drive(billPeriodCircleButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
//        viewModel.noPreviousData.drive(weatherCircleButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
//        viewModel.noPreviousData.drive(otherCircleButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
    }
    
    @IBAction func comparisonToggleButtonPress() {
        guard let viewModel = viewModel else { return }
        setInnerLoadingState(true)
        viewModel.compareToLastYear.value = !viewModel.compareToLastYear.value
    }
    
    func setInnerLoadingState(_ loading: Bool) {
        guard let viewModel = viewModel else { return }
        viewModel.usageBillImpactInnerLoading = loading
        dropdownView.isHidden = loading
        loadingView.isHidden = !loading
        bottomSpacer.isHidden = true
        if loading {
            reasonsWhyLabel.text = NSLocalizedString("Reasons Why Your Bill is...", comment: "")
            let elecGasStr = elecGasSegmentedControl.selectedIndex.value == 0 ? "electric" : "gas"
            differenceDescriptionLabel.text = String.localizedStringWithFormat("Your %@ charges are...", elecGasStr)
        }
    }
    
    @objc func onBillPeriodTap() {
        billPeriodExpanded.accept(!billPeriodExpanded.value)
        if billPeriodExpanded.value {
            GoogleAnalytics.log(event: .billPreviousReason)
        }
    }
    
    @objc func onWeatherTap() {
        weatherExpanded.accept(!weatherExpanded.value)
        if weatherExpanded.value {
            GoogleAnalytics.log(event: .billWeatherReason)
        }
    }
    
    @objc func onOtherTap() {
        otherExpanded.accept(!otherExpanded.value)
        if otherExpanded.value {
            GoogleAnalytics.log(event: .billOtherReason)
        }
    }
    
}
