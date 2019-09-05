//
//  HomeProjectedBillCardView.swift
//  Mobile
//
//  Created by Marc Shilling on 7/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeProjectedBillCardView: UIView {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet private weak var clippingView: UIView!
    
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var loadingView: UIView!
    
    @IBOutlet private weak var infoStack: UIStackView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var segmentedControlContainer: UIView!
    @IBOutlet private weak var segmentedControl: SegmentedControl!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var projectionLabelTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private weak var projectionLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet private weak var projectionSubLabel: UILabel!
    @IBOutlet private weak var projectionFooterLabel: UILabel!
    
    @IBOutlet weak var callToActionButton: UIButton!
    @IBOutlet private weak var emptyStateView: UIView!
    @IBOutlet private weak var emptyStateTitleLabel: UILabel!
    @IBOutlet private weak var emptyStateDescriptionLabel: UILabel!
    
    @IBOutlet private weak var maintenanceModeView: UIView!
    
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorTitleLabel: UILabel!
    @IBOutlet private weak var errorDescriptionLabel: UILabel!
    
    private var viewModel: HomeProjectedBillCardViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomeProjectedBillCardViewModel) -> HomeProjectedBillCardView {
        let view = Bundle.main.loadViewFromNib() as HomeProjectedBillCardView
        view.viewModel = viewModel
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        
        clippingView.layer.cornerRadius = 10
        
        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        emptyStateTitleLabel.textColor = .deepGray
        emptyStateTitleLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        emptyStateDescriptionLabel.textColor = .deepGray
        emptyStateDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        emptyStateDescriptionLabel.attributedText = NSLocalizedString("Projected bill is not available for this account.", comment: "")
            .attributedString(textAlignment: .center, lineHeight: 26)
        
        errorTitleLabel.textColor = .deepGray
        errorTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        errorDescriptionLabel.textColor = .deepGray
        errorDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        errorDescriptionLabel.attributedText = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
            .attributedString(textAlignment: .center, lineHeight: 26)
        
        segmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        segmentedControl.selectedIndex.value = 0
        
        stackView.bringSubviewToFront(segmentedControlContainer)

        infoButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        projectionLabel.textColor = .deepGray
        projectionLabel.font = OpenSans.semiboldItalic.of(textStyle: .title1)
        
        projectionSubLabel.textColor = .deepGray
        projectionSubLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        projectionFooterLabel.textColor = .deepGray
        projectionFooterLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        callToActionButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
    }
    
    private func showContent() {
        infoStack.isHidden = false
        emptyStateView.isHidden = true
        errorView.isHidden = true
        maintenanceModeView.isHidden = true
    }
    
    private func showEmptyState() {
        infoStack.isHidden = true
        emptyStateView.isHidden = false
        errorView.isHidden = true
        maintenanceModeView.isHidden = true
    }
    
    private func showErrorState() {
        infoStack.isHidden = true
        emptyStateView.isHidden = true
        errorView.isHidden = false
        maintenanceModeView.isHidden = true
    }
    
    private func showMaintenanceModeState() {
        infoStack.isHidden = true
        emptyStateView.isHidden = true
        errorView.isHidden = true
        maintenanceModeView.isHidden = false
    }
    
    private func bindViewModel() {
        viewModel.showLoadingState.drive(contentStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showLoadingState.not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showContent
            .drive(onNext: { [weak self] in
                self?.showContent()
            })
            .disposed(by: disposeBag)
        
        viewModel.showEmptyState
            .drive(onNext: { [weak self] in
                self?.showEmptyState()
            })
            .disposed(by: disposeBag)
        
        viewModel.showError
            .drive(onNext: { [weak self] in
                self?.showErrorState()
            })
            .disposed(by: disposeBag)
        
        viewModel.showMaintenanceModeState
            .drive(onNext: { [weak self] in
                self?.showMaintenanceModeState()
            })
            .disposed(by: disposeBag)
        
        viewModel.showLoadingState
            .drive(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
            .disposed(by: disposeBag)
        
        viewModel.shouldShowElectricGasSegmentedControl.drive(onNext: { [weak self] shouldShow in
            self?.projectionLabelTopSpaceConstraint.constant = shouldShow ? 31 : 16
        }).disposed(by: disposeBag)
        
        viewModel.shouldShowElectricGasSegmentedControl.not().drive(segmentedControlContainer.rx.isHidden).disposed(by: disposeBag)
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
        
        viewModel.projectionLabelString.drive(projectionLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionSubLabelString.drive(projectionSubLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionFooterLabelString.drive(projectionFooterLabel.rx.text).disposed(by: disposeBag)
        
        viewModel.projectionNotAvailable.drive(infoButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.projectionNotAvailable.drive(projectionFooterLabel.rx.isHidden).disposed(by: disposeBag)
    }
    
    @IBAction func ctaPress(_ sender: Any) {
        FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .projected_bill_cta)])
    }
    
    @IBAction func segmentValueChange(_ sender: SegmentedControl) {
        if sender.selectedIndex.value == 0 {
            FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .projected_bill_electric_press)])

        } else {
            FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .projected_bill_gas_press)])
        }
    }
    
}
