//
//  UsageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UsageViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var usageGraphPlaceholderButton: DisclosureButton!
    @IBOutlet weak var top5EnergyTipsButton: DisclosureButton!
    @IBOutlet weak var updateYourHomeProfileButton: DisclosureButton!
    @IBOutlet weak var hourlyPricingCard: UIView!
    @IBOutlet weak var hourlyPricingTitleLabel: UILabel!
    @IBOutlet weak var hourlyPricingBodyLabel: UILabel!
    @IBOutlet weak var takeMeToSavingsButton: UIButton!
    
    @IBOutlet weak var smartEnergyRewardsTitleLabel: UILabel!
    @IBOutlet weak var smartEnergyRewardsSeasonLabel: UILabel!
    @IBOutlet weak var smartEnergyRewardsView: SmartEnergyRewardsView!
    
    var accountDetail: AccountDetail! // Passed from HomeViewController
    
    var gradientLayer = CAGradientLayer()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
        buttonTapSetup()
        
        smartEnergyRewardsView.viewModel = SmartEnergyRewardsViewModel(accountDetailDriver: Driver.just(accountDetail))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.removeFromSuperlayer()
        gradientLayer = CAGradientLayer()
        
        // for some reason the gradient layer was being cut short,
        // so I added 2 to the height 🤷🏻‍♂️
        gradientLayer.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height)
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 244/255, green: 245/255, blue: 246/255, alpha: 1).cgColor,
            UIColor(red: 239/255, green: 241/255, blue: 243/255, alpha: 1).cgColor
        ]
        contentView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func styleViews() {
        hourlyPricingCard.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        hourlyPricingCard.layer.cornerRadius = 2
        hourlyPricingCard.isHidden = Environment.sharedInstance.opco != .comEd && accountDetail.isResidential
        
        if accountDetail.isHourlyPricing {
            hourlyPricingTitleLabel.text = NSLocalizedString("Hourly Pricing", comment: "")
            hourlyPricingBodyLabel.text = NSLocalizedString("See how your savings stack up, view your usage, check real-time prices, and more.", comment: "")
            takeMeToSavingsButton.setTitle(NSLocalizedString("Take Me to Savings!", comment: ""), for: .normal)
        } else {
            hourlyPricingTitleLabel.text = NSLocalizedString("Consider ComEd’s Other Rate – Hourly Pricing", comment: "")
            hourlyPricingBodyLabel.text = NSLocalizedString("Save on ComEd’s Hourly Pricing program. It’s simple: shift your usage to times when the price of energy is lower to reduce your bill.", comment: "")
            takeMeToSavingsButton.setTitle(NSLocalizedString("Enroll Me Now", comment: ""), for: .normal)
        }
        
        hourlyPricingTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
        hourlyPricingTitleLabel.textColor = .blackText
        hourlyPricingBodyLabel.font = SystemFont.regular.of(textStyle: .footnote)
        hourlyPricingBodyLabel.textColor = .deepGray
        
        takeMeToSavingsButton.setTitleColor(.actionBlue, for: .normal)
        takeMeToSavingsButton.titleLabel?.font = SystemFont.medium.of(textStyle: .headline)
    }
    
    func buttonTapSetup() {
        Driver.merge(usageGraphPlaceholderButton.rx.tap.asDriver().mapTo("usageWebViewSegue"),
                     top5EnergyTipsButton.rx.tap.asDriver().mapTo("top5EnergyTipsSegue"),
                     updateYourHomeProfileButton.rx.tap.asDriver().mapTo("updateYourHomeProfileSegue"),
                     takeMeToSavingsButton.rx.tap.asDriver().mapTo("hourlyPricingSegue"))
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: $0, sender: nil)
            })
            .disposed(by: disposeBag)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as UsageWebViewController:
            vc.accountDetail = accountDetail
        case _ as Top5EnergyTipsViewController: break
        case _ as MyHomeProfileViewController: break
        case let vc as HourlyPricingViewController:
            vc.accountDetail = accountDetail
        default: break
        }
    }

}
