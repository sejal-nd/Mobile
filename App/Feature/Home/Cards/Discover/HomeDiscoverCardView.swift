//
//  HomeDiscoverCardView.swift
//  EUMobile
//
//  Created by Cody Dillon on 12/13/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SafariServices

class HomeDiscoverCardView: UIView {

    var disposeBag = DisposeBag()

    @IBOutlet weak var contentStack: UIStackView!
    @IBOutlet weak var clippingView: UIView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!

    @IBOutlet weak var row1: UIView!
    @IBOutlet weak var row1Button: UIButton!

    @IBOutlet weak var row2: UIView!
    @IBOutlet weak var row2Button: UIButton!

    @IBOutlet weak var row3: UIView!
    @IBOutlet weak var row3Button: UIButton!

    @IBOutlet weak var row4: UIView!
    @IBOutlet weak var row4Button: UIButton!

    @IBOutlet weak var row5: UIView!
    @IBOutlet weak var row5Button: UIButton!

    @IBOutlet weak var row6: UIView!
    @IBOutlet weak var row6Button: UIButton!

    @IBOutlet weak var row7: UIView!
    @IBOutlet weak var row7Button: UIButton!

    @IBOutlet weak var row8: UIView!
    @IBOutlet weak var row8Button: UIButton!

    @IBOutlet weak var row9: UIView!
    @IBOutlet weak var row9Button: UIButton!

    @IBOutlet weak var row10: UIView!
    @IBOutlet weak var row10Button: UIButton!

    private var viewModel: HomeDiscoverCardViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }

    static func create(withViewModel viewModel: HomeDiscoverCardViewModel) -> HomeDiscoverCardView {
        let view = Bundle.main.loadViewFromNib() as HomeDiscoverCardView
        view.styleViews()
        view.viewModel = viewModel
        return view
    }

    func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        //        clippingView.heightAnchor.constraint(equalToConstant: 164.0).isActive = true

        loadingView.isHidden = true
    }

    private func bindViewModel() {
        //        viewModel.showLoadingState.drive(contentStack.rx.isHidden).disposed(by: disposeBag)
        //        viewModel.showLoadingState.not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        //
        //        viewModel.showLoadingState
        //            .drive(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
        //            .disposed(by: disposeBag)

        viewModel.isCustomerHelp.not().drive(row1.rx.isHidden).disposed(by: disposeBag)
        viewModel.isAssistance.not().drive(row2.rx.isHidden).disposed(by: disposeBag)
        viewModel.isHourlyPricing.not().drive(row3.rx.isHidden).disposed(by: disposeBag)
        viewModel.isEnergySavings.not().drive(row4.rx.isHidden).disposed(by: disposeBag)
        viewModel.isPeakRewards.not().drive(row5.rx.isHidden).disposed(by: disposeBag)
        viewModel.isEnergyWiseRewardsEnrolled.not().drive(row6.rx.isHidden).disposed(by: disposeBag)
        viewModel.isEnergyWiseRewardsOffer.not().drive(row7.rx.isHidden).disposed(by: disposeBag)
        viewModel.isCommercial.not().drive(row8.rx.isHidden).disposed(by: disposeBag)
        viewModel.isSignUpForAlerts.not().drive(row9.rx.isHidden).disposed(by: disposeBag)
        viewModel.isHomeEnergyCheckup.not().drive(row10.rx.isHidden).disposed(by: disposeBag)

        row5Button.rx.touchUpInside.asObservable()
            .withLatestFrom(viewModel.linkToEcobee)
            .filter { $0 }
            .subscribe(onNext: { _ in
                let appLinkUrl = URL(string: "ecobee://")!
                let appStoreUrl = URL(string:"https://itunes.apple.com/us/app/ecobee/id916985674?mt=8")!

                if UIApplication.shared.canOpenURL(appLinkUrl) {
                    GoogleAnalytics.log(event: .homePromoCard, dimensions: [.link: appLinkUrl.absoluteString])
                    UIApplication.shared.open(appLinkUrl)
                } else if UIApplication.shared.canOpenURL(appStoreUrl) {
                    GoogleAnalytics.log(event: .homePromoCard, dimensions: [.link: appStoreUrl.absoluteString])
                    UIApplication.shared.open(appStoreUrl)
                }
            })
            .disposed(by: disposeBag)
    }

    private(set) lazy var helpViewController: Driver<SFSafariViewController> = self.row1Button.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.helpUrl)
        .map(SFSafariViewController.createWithCustomStyle)

    private(set) lazy var assistanceViewController: Driver<SFSafariViewController> = self.row2Button.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.assistanceUrl)
        .map(SFSafariViewController.createWithCustomStyle)

    private(set) lazy var energySavingsViewController: Driver<SFSafariViewController> = self.row4Button.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.energySavingsUrl)
        .map(SFSafariViewController.createWithCustomStyle)

    private(set) lazy var energyWiseRewardsOfferViewController: Driver<SFSafariViewController> = self.row7Button.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.energyWiseRewardsOfferUrl)
        .map(SFSafariViewController.createWithCustomStyle)

    private(set) lazy var commercialViewController: Driver<SFSafariViewController> = self.row8Button.rx.touchUpInside.asDriver()
        .withLatestFrom(self.viewModel.commercialUrl)
        .map(SFSafariViewController.createWithCustomStyle)

    private(set) lazy var hourlyPricingViewController: Driver<UIViewController> = self.row3Button.rx.tap
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map {
            let hourlyPricingVC = UIStoryboard(name: "Usage", bundle: nil)
                .instantiateViewController(withIdentifier: "hourlyPricingViewController") as! HourlyPricingViewController
            hourlyPricingVC.accountDetail = $0
            return hourlyPricingVC
    }.asDriver(onErrorDriveWith: .empty())

    private(set) lazy var itronSmartThermostatViewController: Driver<UIViewController> = self.row6Button.rx.touchUpInside
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map {
            let vc = UIStoryboard(name: "Usage", bundle: nil)
                .instantiateViewController(withIdentifier: "iTronSmartThermostatViewController") as! iTronSmartThermostatViewController
            vc.accountDetail = $0
            return vc
    }.asDriver(onErrorDriveWith: .empty())

    private(set) lazy var peakRewardsViewController: Driver<UIViewController> = self.row5Button.rx.touchUpInside
        .withLatestFrom(self.viewModel.linkToPeakRewards)
        .filter {$0 }
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map {
            let peakRewardsVC = UIStoryboard(name: "PeakRewards", bundle: nil)
                .instantiateInitialViewController() as! PeakRewardsViewController
            peakRewardsVC.accountDetail = $0
            return peakRewardsVC
        }.asDriver(onErrorDriveWith: .empty())
        .do(onNext: { _ in
            GoogleAnalytics.log(event: .homePromoCard,
                                 dimensions: [.link: "https://secure.bge.com/Peakrewards/Pages/default.aspx"])
        })

    private(set) lazy var alertPrefsViewController: Driver<UIViewController> = self.row9Button.rx.touchUpInside.asDriver()
            .map {
                let storyboard = UIStoryboard(name: "Alerts", bundle: nil)
                let alertPrefsVC = storyboard.instantiateViewController(withIdentifier: "alertPreferences") as! AlertPreferencesViewController
                let newNavController = LargeTitleNavigationController(rootViewController: alertPrefsVC)

                return newNavController
            }

    private(set) lazy var homeEnergyCheckupViewController: Driver<SFSafariViewController> = self.row10Button.rx.touchUpInside.asDriver()
            .withLatestFrom(self.viewModel.homeEnergyCheckupUrl)
            .map(SFSafariViewController.createWithCustomStyle)

    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(
        self.hourlyPricingViewController,
        self.peakRewardsViewController,
        self.itronSmartThermostatViewController
    )
}
