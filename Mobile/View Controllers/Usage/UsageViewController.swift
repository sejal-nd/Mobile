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

    @IBOutlet weak var usageGraphPlaceholderButton: DisclosureButton!
    @IBOutlet weak var top5EnergyTipsButton: DisclosureButton!
    @IBOutlet weak var updateYourHomeProfileButton: DisclosureButton!
    @IBOutlet weak var hourlyPricingCard: UIView!
    @IBOutlet weak var hourlyPricingTitleLabel: UILabel!
    @IBOutlet weak var hourlyPricingBodyLabel: UILabel!
    @IBOutlet weak var takeMeToSavingsButton: UIButton!
    
    var accountDetail: AccountDetail! // Passed from HomeViewController
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
        buttonTapSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
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
