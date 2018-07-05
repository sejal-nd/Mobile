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
    
    @IBOutlet weak var clippingView: UIView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var errorView: UIStackView!
    @IBOutlet weak var maintenanceModeView: UIView!
    @IBOutlet weak var gasOnlyView: UIView!
    
    @IBOutlet weak var reportStatusView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var powerStatusTitleLabel: UILabel!
    @IBOutlet weak var powerStatusLabel: UILabel!
    @IBOutlet weak var restorationView: UIView!
    @IBOutlet weak var restorationStatusLabel: UILabel!
    @IBOutlet weak var callToActionButton: ButtonControl!
    @IBOutlet weak var buttonControlLabel: UILabel!
    
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
        titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        powerStatusTitleLabel.font = OpenSans.regular.of(size: 14)
        powerStatusLabel.font = OpenSans.bold.of(size: 22)
        restorationStatusLabel.font = OpenSans.regular.of(size: 12)
        buttonControlLabel.font = SystemFont.semibold.of(textStyle: .title1)
        callToActionButton.backgroundColorOnPress = .softGray
    }
    
    private func bindViewModel() {
        // Bind Model to UI
        viewModel.powerStatusImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.powerStatus.drive(powerStatusLabel.rx.text).disposed(by: bag)
        viewModel.shouldShowRestorationTime.not().drive(restorationView.rx.isHidden).disposed(by: bag)
        viewModel.restorationTime.drive(restorationStatusLabel.rx.text).disposed(by: bag)
        viewModel.hasReportedOutage.asDriver(onErrorDriveWith: .empty()).not().drive(reportStatusView.rx.isHidden).disposed(by: bag)
        
        viewModel.shouldShowContentView.not().drive(contentView.rx.isHidden).disposed(by: bag)
        
        // show error state if an error is received
        viewModel.shouldShowErrorState.not().drive(errorView.rx.isHidden).disposed(by: bag)
        
        // Maintenance Mode State
        viewModel.shouldShowMaintenanceModeState.not().drive(maintenanceModeView.rx.isHidden).disposed(by: bag)
        
        // Gas Only State
        viewModel.shouldShowGasOnly.not().drive(gasOnlyView.rx.isHidden).disposed(by: bag)
    }
    
}
