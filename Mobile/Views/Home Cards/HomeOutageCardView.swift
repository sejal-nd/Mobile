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
    @IBOutlet private weak var errorLabel: UILabel!
    
    var bag = DisposeBag()
    
    private(set) lazy var buttonTapped: Driver<OutageStatus> = callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(viewModel.currentOutageStatus)
    
    private var viewModel: HomeOutageCardViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomeOutageCardViewModel) -> HomeOutageCardView {
        let view = Bundle.main.loadViewFromNib() as HomeOutageCardView
        view.styleViews()
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
        outageReportedLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
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
    }
    
    private func bindViewModel() {
        // Bind Model to UI
        viewModel.powerStatusImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.powerStatus.drive(powerStatusLabel.rx.text).disposed(by: bag)
        
        viewModel.restorationTime
            .map { $0?.attributedString(withLineHeight: 20) }
            .drive(restorationStatusLabel.rx.attributedText)
            .disposed(by: bag)
        
        viewModel.reportedOutageTime.drive(outageReportedLabel.rx.text).disposed(by: bag)
        
        viewModel.accountNonPayFinaledMessage
            .drive(nonPayFinaledTextView.rx.attributedText)
            .disposed(by: bag)
        
        // Show/Hide States
        viewModel.shouldShowContentView.not().drive(contentView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowRestorationTime.not().drive(restorationView.rx.isHidden).disposed(by: bag)
        
        // show error state if an error is received
        viewModel.shouldShowErrorState.not().drive(errorView.rx.isHidden).disposed(by: bag)
        
        // Maintenance Mode State
        viewModel.shouldShowMaintenanceModeState.not().drive(maintenanceModeView.rx.isHidden).disposed(by: bag)
        
        viewModel.showCustomErrorView.not().drive(customErrorView.rx.isHidden).disposed(by: bag)
        viewModel.showOutstandingBalanceWarning.not().drive(nonPayFinaledView.rx.isHidden).disposed(by: bag)
        viewModel.showGasOnly.not().drive(gasOnlyView.rx.isHidden).disposed(by: bag)
    }
    
}
