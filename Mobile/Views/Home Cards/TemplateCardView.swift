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
    @IBOutlet weak var clippingView: UIView!
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var callToActionButton: UIButton!
    
    @IBOutlet weak var errorStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    
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
        callToActionButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)
        
        errorLabel.font = OpenSans.regular.of(textStyle: .title1)
        errorLabel.setLineHeight(lineHeight: 26)
        errorLabel.textAlignment = .center
    }
    
    private func bindViewModel() {
        //grab all the content
        viewModel.templateImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.titleString.drive(titleLabel.rx.text).disposed(by: bag)
        viewModel.bodyString.drive(bodyLabel.rx.text).disposed(by: bag)
        viewModel.bodyStringA11yLabel.drive(bodyLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.ctaString.drive(callToActionButton.rx.title()).disposed(by: bag)
        
        //show error state if an error is received
        viewModel.shouldShowErrorState.drive(contentView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowErrorState.not().drive(errorStack.rx.isHidden).disposed(by: bag)
        viewModel.errorLabelText.drive(onNext: { [weak self] errorText in
            self?.errorLabel.text = errorText
            let localizedAccessibililtyText = NSLocalizedString("%@ OverView, %@", comment: "")
            self?.errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, Environment.shared.opco.displayString, errorText ?? "")
        }).disposed(by: bag)
        
        callToActionButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.ctaUrl.asObservable())
            .subscribe(onNext: {
                Analytics.log(event: .HomePromoCard, dimensions: [.link: $0.absoluteString])
            })
            .disposed(by: bag)
        
        callToActionButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.linkToEcobee)
            .filter { $0 }
            .subscribe(onNext: { _ in
                let appLinkUrl = URL(string: "ecobee://")!
                let appStoreUrl = URL(string:"https://itunes.apple.com/us/app/ecobee/id916985674?mt=8")!
                
                if UIApplication.shared.canOpenURL(appLinkUrl) {
                    Analytics.log(event: .HomePromoCard, dimensions: [.link: appLinkUrl.absoluteString])
                    UIApplication.shared.openURL(appLinkUrl)
                } else if UIApplication.shared.canOpenURL(appStoreUrl) {
                    Analytics.log(event: .HomePromoCard, dimensions: [.link: appStoreUrl.absoluteString])
                    UIApplication.shared.openURL(appStoreUrl)
                }
            })
            .disposed(by: bag)
        
    }
    
    private(set) lazy var safariViewController: Driver<SFSafariViewController> = self.callToActionButton.rx.tap.asDriver()
        .withLatestFrom(self.viewModel.isHourlyPricing)
        .filter(!)
        .withLatestFrom(self.viewModel.ctaUrl)
        .map(SFSafariViewController.createWithCustomStyle)
    
    private lazy var hourlyPricingViewController: Driver<UIViewController> = self.callToActionButton.rx.tap.asDriver()
        .withLatestFrom(self.viewModel.isHourlyPricing)
        .filter { $0 }
        .withLatestFrom(self.viewModel.accountDetailElements.asDriver(onErrorDriveWith: .empty()))
        .map {
            let hourlyPricingVC = UIStoryboard(name: "Home", bundle: nil)
                .instantiateViewController(withIdentifier: "hourlyPricingViewController") as! HourlyPricingViewController
            hourlyPricingVC.accountDetail = $0
            return hourlyPricingVC
    }
    
    private lazy var peakRewardsViewController: Driver<UIViewController> = self.callToActionButton.rx.tap.asDriver()
        .withLatestFrom(self.viewModel.linkToPeakRewards)
        .filter { $0 }
        .withLatestFrom(self.viewModel.accountDetailElements.asDriver(onErrorDriveWith: .empty()))
        .map {
            let peakRewardsVC = UIStoryboard(name: "PeakRewards", bundle: nil)
                .instantiateInitialViewController() as! PeakRewardsViewController
            peakRewardsVC.accountDetail = $0
            return peakRewardsVC
        }
        .do(onNext: { _ in
            Analytics.log(event: .HomePromoCard,
                                 dimensions: [.link: "https://secure.bge.com/Peakrewards/Pages/default.aspx"])
        })
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(self.hourlyPricingViewController,
                                                                                         self.peakRewardsViewController)
}
