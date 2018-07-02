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
    
    var bag = DisposeBag()
    @IBOutlet weak var contentView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var powerStatusTitleLabel: UILabel!
    @IBOutlet weak var powerStatusLabel: UILabel!
    @IBOutlet weak var restorationStatusLabel: UILabel!
    @IBOutlet weak var callToActionButton: UIButton!
    
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
        titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        titleLabel.setLineHeight(lineHeight: 30)
        powerStatusTitleLabel.font = OpenSans.regular.of(size: 14)
        powerStatusTitleLabel.setLineHeight(lineHeight: 20)
        powerStatusLabel.font = OpenSans.bold.of(size: 22)
        powerStatusLabel.setLineHeight(lineHeight: 25)
        restorationStatusLabel.font = OpenSans.regular.of(size: 12)
        restorationStatusLabel.setLineHeight(lineHeight: 20)
        callToActionButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)
    }
    
    private func bindViewModel() {
        //grab all the content
        viewModel.powerStatusImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.powerStatus.drive(powerStatusLabel.rx.text).disposed(by: bag)
        viewModel.restorationTime.drive(restorationStatusLabel.rx.text).disposed(by: bag)

        // Analytics
        
//        callToActionButton.rx.tap.asObservable()
//            .withLatestFrom(viewModel.ctaUrl.asObservable())
//            .subscribe(onNext: {
//                Analytics.log(event: .HomePromoCard, dimensions: [.Link: $0.absoluteString])
//            })
//            .disposed(by: bag)
        
        callToActionButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.linkToEcobee)
            .filter { $0 }
            .subscribe(onNext: { _ in
                let appLinkUrl = URL(string: "ecobee://")!
                let appStoreUrl = URL(string:"https://itunes.apple.com/us/app/ecobee/id916985674?mt=8")!
                
                if UIApplication.shared.canOpenURL(appLinkUrl) {
                    Analytics.log(event: .HomePromoCard, dimensions: [.Link: appLinkUrl.absoluteString])
                    UIApplication.shared.openURL(appLinkUrl)
                } else if UIApplication.shared.canOpenURL(appStoreUrl) {
                    Analytics.log(event: .HomePromoCard, dimensions: [.Link: appStoreUrl.absoluteString])
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
                          dimensions: [.Link: "https://secure.bge.com/Peakrewards/Pages/default.aspx"])
        })
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(self.hourlyPricingViewController,
                                                                                         self.peakRewardsViewController)
}
