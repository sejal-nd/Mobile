//
//  HomeOutageCardView.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt
import SafariServices

class HomeOutageCardView: UIView {
    
    @IBOutlet private weak var clippingView: UIView!
    
    // Content View
    @IBOutlet private weak var contentView: UIStackView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var powerStatusTitleLabel: UILabel!
    @IBOutlet private weak var powerStatusLabel: UILabel!
    @IBOutlet private weak var restorationView: UIView!
    @IBOutlet private weak var restorationStatusLabel: UILabel!
    @IBOutlet private weak var outageReportedView: UIView!
    @IBOutlet private weak var outageReportedLabel: UILabel!
    @IBOutlet private weak var callToActionButton: ButtonControl!
    @IBOutlet private weak var buttonControlLabel: UILabel!
    
    // Custom Error View
    @IBOutlet private weak var customErrorView: UIView!
    @IBOutlet private weak var customErrorTitleLabel: UILabel!
    @IBOutlet private weak var gasOnlyView: UIView!
    @IBOutlet private weak var gasOnlyLabel: UILabel!
    @IBOutlet private weak var gasOnlySublabel: UILabel!
    @IBOutlet private weak var nonPayFinaledView: UIView!
    @IBOutlet private weak var nonPayFinaledTextView: DataDetectorTextView!
    
    // Maintenance Mode View
    @IBOutlet private weak var maintenanceModeView: UIView!
    @IBOutlet private weak var maintenanceModeLabel: UILabel!
    
    // Generic Error View
    @IBOutlet private weak var errorView: UIStackView!
    @IBOutlet private weak var errorTitleLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    
    // Loading View
    @IBOutlet private weak var loadingView: UIView!
    
    var bag = DisposeBag()
    
    private(set) lazy var reportOutageTapped: Driver<OutageStatus> = callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(viewModel.showReportedOutageTime)
        .filter(!)
        .withLatestFrom(viewModel.currentOutageStatus)
    
    private(set) lazy var viewOutageMapTapped: Driver<Void> = callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(viewModel.showReportedOutageTime)
        .filter { $0 }
        .mapTo(())
    
    private var viewModel: HomeOutageCardViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomeOutageCardViewModel) -> HomeOutageCardView {
        let view = Bundle.main.loadViewFromNib() as HomeOutageCardView
        view.styleViews()
        view.showLoadingState()
        view.viewModel = viewModel
        return view
    }
    
    private func styleViews() {
        layer.cornerRadius = 10
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        clippingView.layer.cornerRadius = 10
        clippingView.layer.masksToBounds = true
        
        // Content View
        titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        powerStatusTitleLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        powerStatusLabel.font = OpenSans.bold.of(size: 22)
        restorationStatusLabel.font = OpenSans.regular.of(textStyle: .footnote)
        outageReportedLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        buttonControlLabel.font = SystemFont.semibold.of(textStyle: .title1)
        callToActionButton.backgroundColorOnPress = .softGray
        
        // Custom Error View
        customErrorTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        gasOnlyLabel.font = OpenSans.semibold.of(textStyle: .title1)
        gasOnlySublabel.font = OpenSans.regular.of(textStyle: .footnote)
        nonPayFinaledTextView.tintColor = .actionBlue // For phone numbers
        
        // Maintenance Mode View
        maintenanceModeLabel.font = OpenSans.regular.of(textStyle: .title1)
        
        // Generic Error View
        errorLabel.font = OpenSans.regular.of(textStyle: .title1)
        
        errorTitleLabel.textColor = .blackText
        errorTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
    }
    
    private func showLoadingState() {
        loadingView.isHidden = false
        maintenanceModeView.isHidden = true
        contentView.isHidden = true
        customErrorView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showMaintenanceModeState() {
        loadingView.isHidden = true
        maintenanceModeView.isHidden = false
        contentView.isHidden = true
        customErrorView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showContentState() {
        loadingView.isHidden = true
        maintenanceModeView.isHidden = true
        contentView.isHidden = false
        customErrorView.isHidden = true
        errorView.isHidden = true
    }
    
    private func showCustomErrorState() {
        loadingView.isHidden = true
        maintenanceModeView.isHidden = true
        contentView.isHidden = true
        customErrorView.isHidden = false
        errorView.isHidden = true
    }
    
    private func showErrorState() {
        loadingView.isHidden = true
        maintenanceModeView.isHidden = true
        contentView.isHidden = true
        customErrorView.isHidden = true
        errorView.isHidden = false
    }
    
    private func showOutstandingBalanceWarning() {
        nonPayFinaledView.isHidden = false
        gasOnlyView.isHidden = true
    }
    
    private func showGasOnlyWarning() {
        nonPayFinaledView.isHidden = true
        gasOnlyView.isHidden = false
    }
    
    private func bindViewModel() {
        Driver.merge(
            viewModel.showLoadingState,
            viewModel.showMaintenanceModeState,
            viewModel.showContentView,
            viewModel.showCustomErrorView,
            viewModel.showErrorState
        )
            .drive(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
            .disposed(by: bag)
        
        // Show/Hide States
        
        // Different Overall States
        viewModel.showLoadingState
            .drive(onNext: { [weak self] in self?.showLoadingState() })
            .disposed(by: bag)
        
        viewModel.showMaintenanceModeState
            .drive(onNext: { [weak self] in self?.showMaintenanceModeState() })
            .disposed(by: bag)
        
        viewModel.showContentView
            .drive(onNext: { [weak self] in self?.showContentState() })
            .disposed(by: bag)
        
        viewModel.showCustomErrorView
            .drive(onNext: { [weak self] in self?.showCustomErrorState() })
            .disposed(by: bag)
        
        viewModel.showErrorState
            .drive(onNext: { [weak self] in self?.showErrorState() })
            .disposed(by: bag)
        
        viewModel.showOutstandingBalanceWarning
            .drive(onNext: { [weak self] in self?.showOutstandingBalanceWarning() })
            .disposed(by: bag)
        
        viewModel.showGasOnly
            .drive(onNext: { [weak self] in self?.showGasOnlyWarning() })
            .disposed(by: bag)
        
        // Sub-states
        viewModel.showEtr.not().drive(restorationView.rx.isHidden).disposed(by: bag)
        viewModel.showReportedOutageTime.not().drive(outageReportedView.rx.isHidden).disposed(by: bag)
        
        // Bind Model to UI
        viewModel.powerStatusImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.powerStatus.drive(powerStatusLabel.rx.text).disposed(by: bag)
        
        viewModel.etrText
            .map { $0.attributedString(textAlignment: .center, lineHeight: 20) }
            .drive(restorationStatusLabel.rx.attributedText)
            .disposed(by: bag)
        
        viewModel.reportedOutageTime.drive(outageReportedLabel.rx.text).disposed(by: bag)
        
        viewModel.accountNonPayFinaledMessage
            .drive(nonPayFinaledTextView.rx.attributedText)
            .disposed(by: bag)
        
        viewModel.callToActionButtonText.drive(buttonControlLabel.rx.text).disposed(by: bag)
        viewModel.callToActionButtonText.drive(callToActionButton.rx.accessibilityLabel).disposed(by: bag)
    }
    
}
