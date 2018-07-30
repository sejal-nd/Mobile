//
//  UsageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import SafariServices

class UsageViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var smartEnergyRewardsContainerView: UIView!
    @IBOutlet weak var smartEnergyRewardsFooterLabel: UILabel!
    
    @IBOutlet weak var smartEnergyRewardsContentView: UIView!
    @IBOutlet weak var smartEnergyRewardsSeasonLabel: UILabel!
    @IBOutlet weak var smartEnergyRewardsView: SmartEnergyRewardsView!
    @IBOutlet weak var smartEnergyRewardsViewAllSavingsButton: UIButton!
    
    @IBOutlet weak var smartEnergyRewardsEmptyStateView: UIView!
    @IBOutlet weak var smartEnergyRewardsEmptyStateLabel: UILabel!
    
    var accountDetail: AccountDetail! // Passed from HomeViewController
    
    var viewModel: UsageViewModel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let residentialAMIString = String(format: "%@%@", accountDetail.isResidential ? "Residential/" : "Commercial/", accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        
        let isPeakSmart = (Environment.shared.opco == .bge && accountDetail.isSERAccount) ||
            (Environment.shared.opco != .bge && accountDetail.isPTSAccount)
        
        Analytics.log(event: .ViewUsageLink,
                             dimensions: [.ResidentialAMI: residentialAMIString,
                                          .PeakSmart: isPeakSmart ? "true" : "false"])
        
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
        
        smartEnergyRewardsView.layoutIfNeeded()
        smartEnergyRewardsView.superviewDidLayoutSubviews()
    }
    
    private func styleViews() {
        title = Environment.shared.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") :
            NSLocalizedString("Smart Energy Rewards", comment: "")
        
        smartEnergyRewardsSeasonLabel.textColor = .deepGray
        smartEnergyRewardsSeasonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        
        smartEnergyRewardsViewAllSavingsButton.setTitleColor(.actionBlue, for: .normal)
        smartEnergyRewardsViewAllSavingsButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)
        smartEnergyRewardsViewAllSavingsButton.titleLabel?.text = NSLocalizedString("View All Savings", comment: "")
        
        smartEnergyRewardsFooterLabel.textColor = .blackText
        smartEnergyRewardsFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        smartEnergyRewardsEmptyStateLabel.font = OpenSans.regular.of(textStyle: .title1)
        smartEnergyRewardsEmptyStateLabel.setLineHeight(lineHeight: 26)
        smartEnergyRewardsEmptyStateLabel.textAlignment = .center
        smartEnergyRewardsEmptyStateLabel.textColor = .deepGray
        smartEnergyRewardsEmptyStateLabel.text = NSLocalizedString("Your energy savings data will be available here once we have more data.", comment: "")
    }
    
    private func buttonTapSetup() {
        smartEnergyRewardsViewAllSavingsButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                Analytics.log(event: .AllSavingsUsage)
                self?.performSegue(withIdentifier: "totalSavingsSegue", sender: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        smartEnergyRewardsContainerView.isHidden = !viewModel.shouldShowSmartEnergyRewards
        if viewModel.shouldShowSmartEnergyRewardsContent {
            smartEnergyRewardsContentView.isHidden = false
            smartEnergyRewardsEmptyStateView.isHidden = true
        } else {
            smartEnergyRewardsContentView.isHidden = true
            smartEnergyRewardsEmptyStateView.isHidden = false
            Analytics.log(event: .EmptyStatePeakSmart)
        }
        smartEnergyRewardsSeasonLabel.text = viewModel.smartEnergyRewardsSeasonLabelText
        smartEnergyRewardsFooterLabel.text = viewModel.smartEnergyRewardsFooterText
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
            vc.eventResults = accountDetail.serInfo.eventResults
        case let vc as PeakRewardsViewController:
            vc.accountDetail = accountDetail
        default: break
        }
    }

}
