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
    @IBOutlet private weak var callToActionButton: ButtonControl!
    @IBOutlet private weak var callToActionLabel: UILabel!
    
    @IBOutlet private weak var errorStack: UIStackView!
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
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        clippingView.layer.cornerRadius = 10
        titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        titleLabel.setLineHeight(lineHeight: 30)
        bodyLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        bodyLabel.setLineHeight(lineHeight: 18)
        callToActionLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        errorLabel.font = OpenSans.regular.of(textStyle: .title1)
        errorLabel.setLineHeight(lineHeight: 26)
        errorLabel.textAlignment = .center
    }
    
    private func bindViewModel() {
        viewModel.showLoadingState.drive(onNext: { [weak self] in self?.showLoadingState()}).disposed(by: bag)
        viewModel.showContentState.drive(onNext: { [weak self] in self?.showContentState()}).disposed(by: bag)
        viewModel.showErrorState.drive(onNext: { [weak self] in self?.showErrorState()}).disposed(by: bag)
        
        //grab all the content
        viewModel.templateImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.titleString.drive(titleLabel.rx.text).disposed(by: bag)
        viewModel.bodyString.drive(bodyLabel.rx.text).disposed(by: bag)
        viewModel.bodyStringA11yLabel.drive(bodyLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.ctaString.drive(callToActionLabel.rx.text).disposed(by: bag)
        
        viewModel.errorLabelText.drive(onNext: { [weak self] errorText in
            self?.errorLabel.text = errorText
            let localizedAccessibililtyText = NSLocalizedString("%@ OverView, %@", comment: "")
            self?.errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, Environment.shared.opco.displayString, errorText ?? "")
        }).disposed(by: bag)
        
        callToActionButton.rx.touchUpInside.asObservable()
            .withLatestFrom(viewModel.ctaUrl.asObservable())
            .subscribe(onNext: {
                Analytics.log(event: .homePromoCard, dimensions: [.link: $0.absoluteString])
            })
            .disposed(by: bag)
        
        callToActionButton.rx.touchUpInside.asObservable()
            .withLatestFrom(viewModel.linkToEcobee)
            .filter { $0 }
            .subscribe(onNext: { _ in
                let appLinkUrl = URL(string: "ecobee://")!
                let appStoreUrl = URL(string:"https://itunes.apple.com/us/app/ecobee/id916985674?mt=8")!
                
                if UIApplication.shared.canOpenURL(appLinkUrl) {
                    Analytics.log(event: .homePromoCard, dimensions: [.link: appLinkUrl.absoluteString])
                    UIApplication.shared.openURL(appLinkUrl)
                } else if UIApplication.shared.canOpenURL(appStoreUrl) {
                    Analytics.log(event: .homePromoCard, dimensions: [.link: appStoreUrl.absoluteString])
                    UIApplication.shared.openURL(appStoreUrl)
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
        .filter(!)
        .withLatestFrom(self.viewModel.ctaUrl)
        .map(SFSafariViewController.createWithCustomStyle)
    
    private lazy var hourlyPricingViewController: Driver<UIViewController> = self.callToActionButton.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.isHourlyPricing)
        .filter { $0 }
        .withLatestFrom(self.viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
        .map {
            let hourlyPricingVC = UIStoryboard(name: "Home", bundle: nil)
                .instantiateViewController(withIdentifier: "hourlyPricingViewController") as! HourlyPricingViewController
            hourlyPricingVC.accountDetail = $0
            return hourlyPricingVC
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
            Analytics.log(event: .homePromoCard,
                                 dimensions: [.link: "https://secure.bge.com/Peakrewards/Pages/default.aspx"])
        })
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(self.hourlyPricingViewController,
                                                                                         self.peakRewardsViewController)
}
