//
//  TemplateCardView.swift
//  Mobile
//
//  Created by Dan Jorquera on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt
import SafariServices

class TemplateCardView: UIView {
    
    var bag = DisposeBag()
    
    @IBOutlet private weak var clippingView: UIView!
    @IBOutlet private weak var contentView: UIStackView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var callToActionButton: UIButton!
    @IBOutlet private weak var errorStack: UIStackView!
    @IBOutlet private weak var errorTitleLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    
    @IBOutlet private weak var loadingView: UIView!
    
    private var viewModel: TemplateCardViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: TemplateCardViewModel) -> TemplateCardView {
        let view = Bundle.main.loadViewFromNib() as TemplateCardView
        view.styleViews()
        view.viewModel = viewModel
        return view
    }
    
    private func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        titleLabel.textColor = .neutralDark
        titleLabel.font = .headline
        bodyLabel.textColor = .neutralDark
        bodyLabel.font = .footnote
        callToActionButton.titleLabel?.font = .headlineSemibold
        
        errorTitleLabel.textColor = .neutralDark
        errorTitleLabel.font = .headline
        
        errorLabel.textColor = .neutralDark
        errorLabel.font = .subheadline
        errorLabel.textAlignment = .center
    }
    
    private func bindViewModel() {
        viewModel.showLoadingState.drive(onNext: { [weak self] in self?.showLoadingState()}).disposed(by: bag)
        viewModel.showContentState.drive(onNext: { [weak self] in self?.showContentState()}).disposed(by: bag)
        viewModel.showErrorState.drive(onNext: { [weak self] in self?.showErrorState()}).disposed(by: bag)
        
        Driver.merge(
            viewModel.showLoadingState,
            viewModel.showContentState,
            viewModel.showErrorState
        )
            .drive(onNext: { UIAccessibility.post(notification: .screenChanged, argument: nil) })
            .disposed(by: bag)
        
        //grab all the content
        viewModel.templateImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.titleString
            .map { $0?.attributedString(textAlignment: .center, lineHeight: 30) }
            .drive(titleLabel.rx.attributedText)
            .disposed(by: bag)
        
        viewModel.bodyString
            .map { $0?.attributedString(textAlignment: .left, lineHeight: 18) }
            .drive(bodyLabel.rx.attributedText).disposed(by: bag)
        viewModel.bodyStringA11yLabel.drive(bodyLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.ctaString.drive(callToActionButton.rx.title(for: .normal)).disposed(by: bag)
        viewModel.ctaString.drive(callToActionButton.rx.accessibilityLabel).disposed(by: bag)
        
        let attributedErrorText = viewModel.errorLabelText.attributedString(textAlignment: .center, lineHeight: 26)
        errorLabel.attributedText = attributedErrorText
        let localizedAccessibililtyText = NSLocalizedString("%@ OverView, %@", comment: "")
        errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, Configuration.shared.opco.displayString, attributedErrorText)
        
        callToActionButton.rx.touchUpInside.asObservable()
            .withLatestFrom(viewModel.ctaUrl.asObservable())
            .subscribe(onNext: { _ in
            
            })
            .disposed(by: bag)
        
        callToActionButton.rx.touchUpInside.asObservable()
            .withLatestFrom(viewModel.linkToEcobee)
            .filter { $0 }
            .subscribe(onNext: { _ in
                let appLinkUrl = URL(string: "ecobee://")!
                let appStoreUrl = URL(string:"https://itunes.apple.com/us/app/ecobee/id916985674?mt=8")!
                
                if UIApplication.shared.canOpenURL(appLinkUrl) {
                    
                    UIApplication.shared.open(appLinkUrl)
                } else if UIApplication.shared.canOpenURL(appStoreUrl) {
                   
                    UIApplication.shared.open(appStoreUrl)
                }
            })
            .disposed(by: bag)
        
    }
    
    private func showLoadingState() {
        contentView.isHidden = true
        loadingView.isHidden = false
        errorStack.isHidden = true
    }
    
    private func showContentState() {
        contentView.isHidden = false
        loadingView.isHidden = true
        errorStack.isHidden = true
    }
    
    private func showErrorState() {
        contentView.isHidden = true
        loadingView.isHidden = true
        errorStack.isHidden = false
    }
    
    private(set) lazy var safariViewController: Driver<SFSafariViewController> = self.callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.isHourlyPricing)
        .withLatestFrom(self.viewModel.isEnergyWiseRewardsEnrolled)
        .filter(!)
        .withLatestFrom(self.viewModel.ctaUrl)
        .map(SFSafariViewController.createWithCustomStyle)
    
    private lazy var hourlyPricingViewController: Driver<UIViewController> = self.callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.isHourlyPricing)
        .filter { $0 }
        .withLatestFrom(self.viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
        .map {
            let hourlyPricingVC = UIStoryboard(name: "Usage", bundle: nil)
                .instantiateViewController(withIdentifier: "hourlyPricingViewController") as! HourlyPricingViewController
            hourlyPricingVC.accountDetail = $0
            return hourlyPricingVC
    }
    
    private lazy var itronSmartThermostatViewController: Driver<UIViewController> = self.callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.isEnergyWiseRewardsEnrolled)
        .filter { $0 }
        .withLatestFrom(self.viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
        .map {
            let vc = UIStoryboard(name: "Usage", bundle: nil)
                .instantiateViewController(withIdentifier: "iTronSmartThermostatViewController") as! iTronSmartThermostatViewController
            vc.accountDetail = $0
            return vc
    }
    
    private lazy var peakRewardsViewController: Driver<UIViewController> = self.callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.linkToPeakRewards)
        .filter { $0 }
        .withLatestFrom(self.viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
        .map {
            let peakRewardsVC = UIStoryboard(name: "PeakRewards", bundle: nil)
                .instantiateInitialViewController() as! PeakRewardsViewController
            peakRewardsVC.accountDetail = $0
            return peakRewardsVC
        }
        .do(onNext: { _ in
            
        })
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(self.hourlyPricingViewController,
                                                                                         self.peakRewardsViewController,
                                                                                         self.itronSmartThermostatViewController)
    
    @IBAction func ctaPress(_ sender: Any) {
        FirebaseUtility.logEvent(.home(parameters: [.promo_cta]))
    }
}
