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
    @IBOutlet private weak var restorationStatusValueLabel: UILabel!
    @IBOutlet private weak var outageReportedView: UIView!
    @IBOutlet private weak var outageReportedLabel: UILabel!
    @IBOutlet weak var callToActionButton: UIButton!
    
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
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        clippingView.layer.masksToBounds = true
        
        // Content View
        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        powerStatusTitleLabel.textColor = .deepGray
        powerStatusTitleLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        powerStatusLabel.textColor = .deepGray
        powerStatusLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        restorationStatusLabel.textColor = .deepGray
        restorationStatusLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        restorationStatusLabel.textColor = .deepGray
        restorationStatusLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        outageReportedLabel.textColor = .deepGray
        outageReportedLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        
        callToActionButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        // Custom Error View
        customErrorTitleLabel.textColor = .deepGray
        customErrorTitleLabel.font = OpenSans.regular.of(textStyle: .headline)

        gasOnlyLabel.textColor = .deepGray
        gasOnlyLabel.font = OpenSans.semibold.of(textStyle: .title3)
        
        gasOnlySublabel.textColor = .deepGray
        gasOnlySublabel.font = SystemFont.regular.of(textStyle: .caption1)

        nonPayFinaledTextView.tintColor = .actionBlue // For phone numbers
        
        // Maintenance Mode View
        maintenanceModeLabel.textColor = .deepGray
        maintenanceModeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        // Generic Error View
        errorTitleLabel.textColor = .deepGray
        errorTitleLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        errorLabel.textColor = .deepGray
        errorLabel.font = SystemFont.regular.of(textStyle: .caption1)
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
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
        
        if Environment.shared.opco.isPHI  {
            viewModel.getError
                .drive(onNext: { [weak self] err in
                    if let error  = err as? NetworkingError {
                        if error == .inactive || error == .finaled {
                            self?.errorLabel.text = NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
                        } else if error == .noPay {
                            self?.errorLabel.text = NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
                        } else {
                            self?.errorLabel.text = NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
                        }
                    }
                })
                .disposed(by: bag)
        }
        
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
            .drive(restorationStatusValueLabel.rx.attributedText)
            .disposed(by: bag)
        
        viewModel.reportedOutageTime.drive(outageReportedLabel.rx.text).disposed(by: bag)
        
        viewModel.accountNonPayFinaledMessage
            .drive(nonPayFinaledTextView.rx.attributedText)
            .disposed(by: bag)
        
        viewModel.callToActionButtonText.drive(callToActionButton.rx.title(for: .normal)).disposed(by: bag)
        viewModel.callToActionButtonText.drive(callToActionButton.rx.accessibilityLabel).disposed(by: bag)
    }
    
    @IBAction func ctaPress(_ sender: Any) {        
        FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .outage_cta)])
    }
}
