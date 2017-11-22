//
//  UsageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import SafariServices
import RxSwift
import RxCocoa
import RxSwiftExt
import SafariServices

class UsageViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var gradientView: UIView!

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var usageGraphPlaceholderButton: DisclosureButton!
    @IBOutlet weak var top5EnergyTipsButton: DisclosureButton!
    @IBOutlet weak var updateYourHomeProfileButton: DisclosureButton!
    
    @IBOutlet weak var hourlyPricingCard: UIView!
    @IBOutlet weak var hourlyPricingTitleLabel: UILabel!
    @IBOutlet weak var hourlyPricingBodyLabel: UILabel!
    @IBOutlet weak var hourlyPricingEnrollButton: UIButton!
    
    @IBOutlet weak var peakTimeSavingsCard: UIView!
    @IBOutlet weak var peakTimeSavingsTitleLabel: UILabel!
    @IBOutlet weak var peakTimeSavingsBodyLabel: UILabel!
    @IBOutlet weak var peakTimeSavingsEnrollButton: UIButton!
    
    @IBOutlet weak var smartEnergyRewardsContainerView: UIView!
    @IBOutlet weak var smartEnergyRewardsTitleLabel: UILabel!
    @IBOutlet weak var smartEnergyRewardsFooterLabel: UILabel!
    
    @IBOutlet weak var smartEnergyRewardsContentView: UIView!
    @IBOutlet weak var smartEnergyRewardsSeasonLabel: UILabel!
    @IBOutlet weak var smartEnergyRewardsView: SmartEnergyRewardsView!
    @IBOutlet weak var smartEnergyRewardsViewAllSavingsButton: UIButton!
    
    @IBOutlet weak var smartEnergyRewardsEmptyStateView: UIView!
    @IBOutlet weak var smartEnergyRewardsEmptyStateLabel: UILabel!
    
    var accountDetail: AccountDetail! // Passed from HomeViewController
    
    let gradientLayer = CAGradientLayer()
    
    var viewModel: UsageViewModel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let residentialAMIString = String(format: "%@%@", accountDetail.isResidential ? "Residential/" : "Commercial/", accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        Analytics().logScreenView(AnalyticsPageView.ViewUsageLink.rawValue, dimensionIndices: [
            Dimensions.ResidentialAMI,
            Dimensions.PeakSmart
        ], dimensionValues: [
            residentialAMIString,
            (Environment.sharedInstance.opco == .bge && accountDetail.isSERAccount) || (Environment.sharedInstance.opco != .bge && accountDetail.isPTSAccount) ? "true" : "false"
        ])
        
        if accountDetail.peakRewards == "ACTIVE" {
            let thermbutton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_thermostat"), style: .plain, target: nil, action: nil)
            thermbutton.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    Analytics().logScreenView(AnalyticsPageView.ViewUsagePeakRewards.rawValue)
                    self?.performSegue(withIdentifier: "peakRewardsSegue", sender: nil)
                })
                .disposed(by: disposeBag)
            navigationItem.rightBarButtonItem = thermbutton
        }

        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 244/255, green: 245/255, blue: 246/255, alpha: 1).cgColor,
            UIColor(red: 239/255, green: 241/255, blue: 243/255, alpha: 1).cgColor
        ]
        gradientView.layer.addSublayer(gradientLayer)
        
        styleViews()
        buttonTapSetup()
        
        viewModel = UsageViewModel(accountDetail: accountDetail)
        smartEnergyRewardsView.viewModel = SmartEnergyRewardsViewModel(accountDetailDriver: Driver.just(accountDetail))
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.frame
        
        smartEnergyRewardsView.layoutIfNeeded()
        smartEnergyRewardsView.superviewDidLayoutSubviews()
    }
    
    private func styleViews() {
        hourlyPricingCard.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        hourlyPricingCard.layer.cornerRadius = 2
        hourlyPricingTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        hourlyPricingTitleLabel.textColor = .blackText
        hourlyPricingBodyLabel.font = SystemFont.regular.of(textStyle: .footnote)
        hourlyPricingBodyLabel.textColor = .deepGray
        hourlyPricingEnrollButton.setTitleColor(.actionBlue, for: .normal)
        hourlyPricingEnrollButton.titleLabel?.font = SystemFont.medium.of(textStyle: .headline)
        
        peakTimeSavingsCard.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        peakTimeSavingsCard.layer.cornerRadius = 2
        peakTimeSavingsTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        peakTimeSavingsTitleLabel.textColor = .blackText
        peakTimeSavingsTitleLabel.text = NSLocalizedString("Peak Time Savings", comment: "")
        peakTimeSavingsBodyLabel.font = SystemFont.regular.of(textStyle: .footnote)
        peakTimeSavingsBodyLabel.textColor = .deepGray
        peakTimeSavingsBodyLabel.text = NSLocalizedString("Earn a credit on your bill when you participate in this program that pays you back for using less energy when it is most in demand.", comment: "")
        peakTimeSavingsEnrollButton.setTitleColor(.actionBlue, for: .normal)
        peakTimeSavingsEnrollButton.titleLabel?.font = SystemFont.medium.of(textStyle: .headline)
        peakTimeSavingsEnrollButton.setTitle(NSLocalizedString("Enroll Now", comment: ""), for: .normal)
        
        if Environment.sharedInstance.opco == .comEd && accountDetail.isResidential {
            if !accountDetail.isAMIAccount || accountDetail.isPTSAccount {
                peakTimeSavingsCard.isHidden = true
            }
            if accountDetail.isHourlyPricing {
                hourlyPricingTitleLabel.text = NSLocalizedString("Hourly Pricing", comment: "")
                hourlyPricingBodyLabel.text = NSLocalizedString("See how your savings stack up, view your usage, check real-time prices, and more.", comment: "")
                hourlyPricingEnrollButton.setTitle(NSLocalizedString("Take Me to Savings!", comment: ""), for: .normal)
            } else {
                hourlyPricingTitleLabel.text = NSLocalizedString("Consider ComEd’s Other Rate – Hourly Pricing", comment: "")
                hourlyPricingBodyLabel.text = NSLocalizedString("Save on ComEd’s Hourly Pricing program. It’s simple: shift your usage to times when the price of energy is lower to reduce your bill.", comment: "")
                hourlyPricingEnrollButton.setTitle(NSLocalizedString("Enroll Me Now", comment: ""), for: .normal)
            }
        } else {
            hourlyPricingCard.isHidden = true
            peakTimeSavingsCard.isHidden = true
        }

        smartEnergyRewardsTitleLabel.textColor = .blackText
        smartEnergyRewardsTitleLabel.font = OpenSans.bold.of(textStyle: .title1)
        smartEnergyRewardsTitleLabel.text = Environment.sharedInstance.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") :
            NSLocalizedString("Smart Energy Rewards", comment: "")
        
        smartEnergyRewardsSeasonLabel.textColor = .deepGray
        smartEnergyRewardsSeasonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        
        smartEnergyRewardsViewAllSavingsButton.setTitleColor(.actionBlue, for: .normal)
        smartEnergyRewardsViewAllSavingsButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)
        smartEnergyRewardsViewAllSavingsButton.titleLabel?.text = NSLocalizedString("View All Savings", comment: "")
        
        smartEnergyRewardsFooterLabel.textColor = .blackText
        smartEnergyRewardsFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        smartEnergyRewardsFooterLabel.text = NSLocalizedString("You earn bill credits for every kWh you save. " +
            "We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use.", comment: "")
        
        smartEnergyRewardsEmptyStateLabel.font = OpenSans.regular.of(textStyle: .title1)
        smartEnergyRewardsEmptyStateLabel.setLineHeight(lineHeight: 26)
        smartEnergyRewardsEmptyStateLabel.textAlignment = .center
        smartEnergyRewardsEmptyStateLabel.textColor = .deepGray
        smartEnergyRewardsEmptyStateLabel.text = NSLocalizedString("Your energy savings data will be available here once we have more data.", comment: "")
    }
    
    private func buttonTapSetup() {
        Driver.merge(usageGraphPlaceholderButton.rx.tap.asDriver().map(to: "usageWebViewSegue"),
                     top5EnergyTipsButton.rx.tap.asDriver().map(to: "top5EnergyTipsSegue"),
                     updateYourHomeProfileButton.rx.tap.asDriver().map(to: "updateYourHomeProfileSegue"),
                     smartEnergyRewardsViewAllSavingsButton.rx.tap.asDriver().map(to: "totalSavingsSegue"))
            .drive(onNext: { [weak self] in
                if $0 == "totalSavingsSegue" {
                    Analytics().logScreenView(AnalyticsPageView.AllSavingsUsage.rawValue)
                }
                self?.performSegue(withIdentifier: $0, sender: nil)
            })
            .disposed(by: disposeBag)
        
        hourlyPricingEnrollButton.rx.tap.asDriver().drive(onNext: { [weak self] in
            guard let accountDetail = self?.accountDetail else { return }
            if accountDetail.isHourlyPricing {
                Analytics().logScreenView(AnalyticsPageView.HourlyPricing.rawValue, dimensionIndex: Dimensions.HourlyPricingEnrollment, dimensionValue: "enrolled")
                self?.performSegue(withIdentifier: "hourlyPricingSegue", sender: nil)
            } else {
                Analytics().logScreenView(AnalyticsPageView.HourlyPricing.rawValue, dimensionIndex: Dimensions.HourlyPricingEnrollment, dimensionValue: "unenrolled")
                let safariVc = SFSafariViewController.createWithCustomStyle(url: URL(string: "https://hourlypricing.comed.com")!)
                self?.present(safariVc, animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
        
        peakTimeSavingsEnrollButton.rx.tap.asDriver().drive(onNext: { [weak self] _ in
            Analytics().logScreenView(AnalyticsPageView.PeakTimePromo.rawValue)
            let safariVc = SFSafariViewController.createWithCustomStyle(url: URL(string: "http://comed.com/PTS")!)
            self?.present(safariVc, animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        smartEnergyRewardsContainerView.isHidden = !viewModel.shouldShowSmartEnergyRewards
        if viewModel.shouldShowSmartEnergyRewardsContent {
            smartEnergyRewardsContentView.isHidden = false
            smartEnergyRewardsEmptyStateView.isHidden = true
        } else {
            smartEnergyRewardsContentView.isHidden = true
            smartEnergyRewardsEmptyStateView.isHidden = false
            Analytics().logScreenView(AnalyticsPageView.EmptyStatePeakSmart.rawValue)
        }
        smartEnergyRewardsSeasonLabel.text = viewModel.smartEnergyRewardsSeasonLabelText
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as UsageWebViewController:
            vc.accountDetail = accountDetail
        case let vc as Top5EnergyTipsViewController:
            vc.accountDetail = accountDetail
        case let vc as MyHomeProfileViewController:
            vc.accountDetail = accountDetail
            vc.didSaveHomeProfile
                .delay(0.5)
                .drive(onNext: { [weak self] in
                    self?.view.showToast(NSLocalizedString("Home profile updated", comment: ""))
                })
                .disposed(by: disposeBag)
        case let vc as HourlyPricingViewController:
            vc.accountDetail = accountDetail
        case let vc as TotalSavingsViewController:
            vc.eventResults = accountDetail.SERInfo.eventResults
        case let vc as PeakRewardsViewController:
            vc.accountDetail = accountDetail
        default: break
        }
    }

}
