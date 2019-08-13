//
//  BillImpactDropdownView.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BillImpactDropdownView: UIView {

    @IBOutlet private weak var contentView: UIView! {
        didSet {
            layer.borderColor = UIColor.accentGray.cgColor
            layer.borderWidth = 1
        }
    }
    
    @IBOutlet private weak var roundedBgView: UIView! {
        didSet {
            roundedBgView.layer.cornerRadius = 10
            roundedBgView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var likelyReasonsStackView: UIStackView!
    @IBOutlet private weak var likelyReasonsDescriptionTriangleView: UIImageView!
    @IBOutlet private weak var likelyReasonsDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    @IBOutlet private weak var likelyReasonsDescriptionView: UIView!
    @IBOutlet private weak var billFactorView: UIView! {
        didSet {
            billFactorView.isHidden = true
        }
    }
    
    @IBOutlet private weak var toggleButtonLabel: UILabel! {
        didSet {
            toggleButtonLabel.textColor = .actionBlue
        }
    }
    
    @IBOutlet private weak var carrotImageView: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        }
    }
    
    @IBOutlet private weak var contrastRoundedView: UIView! {
        didSet {
            contrastRoundedView.layer.cornerRadius = 10
        }
    }
    
    // Buttons
    @IBOutlet private weak var billPeriodButton: ButtonControl!
    @IBOutlet private weak var billPeriodCircleButton: UIView! {
        didSet {
            billPeriodCircleButton.layer.cornerRadius = billPeriodCircleButton.frame.height / 2
            billPeriodCircleButton.layer.borderWidth = 2
            billPeriodCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
            billPeriodCircleButton.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        }
    }
    
    @IBOutlet private weak var billPeriodTitleLabel: UILabel! {
        didSet {
            billPeriodTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet private weak var weatherButton: ButtonControl!
    @IBOutlet private weak var weatherCircleButton: UIView! {
        didSet {
            weatherCircleButton.layer.cornerRadius = weatherCircleButton.frame.height / 2
            weatherCircleButton.layer.borderWidth = 2
            weatherCircleButton.layer.borderColor = UIColor.clear.cgColor
            weatherCircleButton.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        }
    }
    
    @IBOutlet private weak var weatherTitleLabel: UILabel! {
        didSet {
            weatherTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet private weak var otherButton: ButtonControl!
    @IBOutlet private weak var otherCircleButton: UIView! {
        didSet {
            otherCircleButton.layer.cornerRadius = otherCircleButton.frame.height / 2
            otherCircleButton.layer.borderWidth = 2
            otherCircleButton.layer.borderColor = UIColor.clear.cgColor
            otherCircleButton.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        }
    }
    
    @IBOutlet private weak var otherTitleLabel: UILabel! {
        didSet {
            otherTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet private weak var bubbleView: UIView! {
        didSet {
            bubbleView.layer.cornerRadius = 10
            bubbleView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0, height: 2), radius: 4)
        }
    }
    
    @IBOutlet private weak var bubbleViewTitleLabel: UILabel! {
        didSet {
            bubbleViewTitleLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        }
    }
    
    @IBOutlet private weak var bubbleViewDescriptionLabel: UILabel! {
        didSet {
            bubbleViewDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet private weak var footerLabel: UILabel! {
        didSet {
            footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
            footerLabel.textColor = .blackText
            footerLabel.text = NSLocalizedString("The amounts shown are usage-related charges and may not include credits and other adjustments. " +
                "Amounts for Budget Billing customers are based on actual usage in the period, not on your monthly budget payment.", comment: "")
        }
    }
    
    @IBOutlet private weak var billPeriodUpDownImageView: UIImageView!
    @IBOutlet private var likelyReasonsNoDataLabels: [UILabel]!
    @IBOutlet private weak var weatherUpDownImageView: UIImageView!
    @IBOutlet private weak var otherUpDownImageView: UIImageView!
    
    private let disposeBag = DisposeBag()
    
    private var hasLoadedView = false
    
    private var isExpanded = false {
        didSet {
            guard hasLoadedView else { return }
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                if let isExpanded = self?.isExpanded, isExpanded {
                    self?.billFactorView.isHidden = false
                    self?.carrotImageView.image = #imageLiteral(resourceName: "ic_carat_up")
                } else {
                    self?.billFactorView.isHidden = true
                    self?.carrotImageView.image = #imageLiteral(resourceName: "ic_carat_down")
                }
                self?.contentStackView.layoutIfNeeded()
            })
        }
    }
    
    private var viewModel: UsageViewModel?
    
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        prepareViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        prepareViews()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BillImpactDropdownView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        hasLoadedView = true
    }
    
    private func prepareViews() {
        // Default to collapsed
        isExpanded = false
        
        // Default button selected is Bill Period
        factorImpactPress(billPeriodButton)
    }
    
    
    // MARK: - Actions
    
    @IBAction private func toggleStackView(_ sender: Any) {
        isExpanded = !isExpanded
    }
    
    @IBAction private func factorImpactPress(_ sender: ButtonControl) {
        // guard statement will block analytics from occuring on view setup.
        guard let viewModel = viewModel else { return }
        
        if sender.tag == 0 {
            GoogleAnalytics.log(event: .billPreviousReason)
        } else if sender.tag == 1 {
            GoogleAnalytics.log(event: .billWeatherReason)
        } else {
            GoogleAnalytics.log(event: .billOtherReason)
        }
        
        viewModel.setLikelyReasonSelected(tag: sender.tag)
    }
    
    
    // MARK: - Configuration
    
    func configure(withViewModel viewModel: UsageViewModel) {
        self.viewModel = viewModel
        bindViewModel(viewModel)
    }
    
    func bindViewModel(_ viewModel: UsageViewModel) {
        // Likely reasons
        viewModel.billPeriodArrowImage.drive(billPeriodUpDownImageView.rx.image).disposed(by: disposeBag)
        viewModel.billPeriodA11yLabel.drive(billPeriodButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.weatherArrowImage.drive(weatherUpDownImageView.rx.image).disposed(by: disposeBag)
        viewModel.weatherA11yLabel.drive(weatherButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.otherArrowImage.drive(otherUpDownImageView.rx.image).disposed(by: disposeBag)
        viewModel.otherA11yLabel.drive(otherButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        viewModel.likelyReasonsLabelText.drive(descriptionLabel.rx.text).disposed(by: disposeBag)
        viewModel.likelyReasonsDescriptionTitleText.drive(bubbleViewTitleLabel.rx.text).disposed(by: disposeBag)
        viewModel.likelyReasonsDescriptionDetailText.drive(bubbleViewDescriptionLabel.rx.text).disposed(by: disposeBag)
        viewModel.noPreviousData.drive(likelyReasonsDescriptionView.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.drive(billPeriodUpDownImageView.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.drive(weatherUpDownImageView.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.drive(otherUpDownImageView.rx.isHidden).disposed(by: disposeBag)
        for label in likelyReasonsNoDataLabels {
            viewModel.noPreviousData.not().drive(label.rx.isHidden).disposed(by: disposeBag)
        }
        
        Driver.combineLatest(viewModel.likelyReasonsSelection.asDriver().distinctUntilChanged(),
                             viewModel.noPreviousData.distinctUntilChanged())
            .drive(onNext: { [weak self] likelyReasonsSelection, noPreviousData in
                self?.updateLikelyReasonsSelection(noPreviousData ? nil : likelyReasonsSelection)
            })
            .disposed(by: disposeBag)
        
        viewModel.noPreviousData.drive(billPeriodCircleButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
        viewModel.noPreviousData.drive(weatherCircleButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
        viewModel.noPreviousData.drive(otherCircleButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
    }
    
    private func updateLikelyReasonsSelection(_ selection: UsageViewModel.LikelyReasonsSelection?) {
        var selectedCircleButton: UIView?
        switch selection {
        case .billPeriod?:
            selectedCircleButton = billPeriodCircleButton
            billPeriodCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
            weatherCircleButton.layer.borderColor = UIColor.clear.cgColor
            otherCircleButton.layer.borderColor = UIColor.clear.cgColor
        case .weather?:
            selectedCircleButton = weatherCircleButton
            billPeriodCircleButton.layer.borderColor = UIColor.clear.cgColor
            weatherCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
            otherCircleButton.layer.borderColor = UIColor.clear.cgColor
        case .other?:
            selectedCircleButton = otherCircleButton
            billPeriodCircleButton.layer.borderColor = UIColor.clear.cgColor
            weatherCircleButton.layer.borderColor = UIColor.clear.cgColor
            otherCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
        case .none:
            selectedCircleButton = nil
            billPeriodCircleButton.layer.borderColor = UIColor.clear.cgColor
            weatherCircleButton.layer.borderColor = UIColor.clear.cgColor
            otherCircleButton.layer.borderColor = UIColor.clear.cgColor
        }
        
        guard let button = selectedCircleButton else { return }
        
        likelyReasonsDescriptionTriangleCenterXConstraint.isActive = false
        likelyReasonsDescriptionTriangleCenterXConstraint = likelyReasonsDescriptionTriangleView.centerXAnchor
            .constraint(equalTo: button.centerXAnchor)
        likelyReasonsDescriptionTriangleCenterXConstraint.isActive = true
    }
}
