//
//  SmartEnergyRewardsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import SafariServices

class SmartEnergyRewardsViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var smartEnergyRewardsContainerView: UIView!
    @IBOutlet private weak var smartEnergyRewardsFooterLabel: UILabel!
    
    @IBOutlet private weak var smartEnergyRewardsContentView: UIView!
    @IBOutlet private weak var smartEnergyRewardsSeasonLabel: UILabel!
    @IBOutlet private weak var smartEnergyRewardsView: SmartEnergyRewardsView!
    @IBOutlet private weak var smartEnergyRewardsViewAllSavingsButton: UIButton!
    
    @IBOutlet private weak var smartEnergyRewardsEmptyStateView: UIView!
    @IBOutlet private weak var smartEnergyRewardsEmptyStateLabel: UILabel!
    
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var loadingIndicator: LoadingIndicator!
    
    var accountDetail: AccountDetail! // Passed from HomeViewController
    var eventResults: [SERResult]? // If nil, fetch from the server
    
    var viewModel: SmartEnergyRewardsVCViewModel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
 
        viewModel = SmartEnergyRewardsVCViewModel(accountService: ServiceFactory.createAccountService(),
                                                  accountDetail: accountDetail,
                                                  eventResults: eventResults)
        
        smartEnergyRewardsView.viewModel = viewModel.smartEnergyRewardsViewModel
        
        styleViews()
        buttonTapSetup()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setWhiteNavBar()
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
        
        errorLabel.textColor = .blackText
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
    }
    
    private func buttonTapSetup() {
        smartEnergyRewardsViewAllSavingsButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.eventResults)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] eventResults in
                Analytics.log(event: .allSavingsUsage)
                self?.performSegue(withIdentifier: "totalSavingsSegue", sender: eventResults)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        loadingIndicator.isHidden = false
        errorLabel.isHidden = true
        scrollView.isHidden = true
        viewModel.eventResults
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.scrollView.isHidden = false
                self.loadingIndicator.isHidden = true
                self.errorLabel.isHidden = true
                }, onError: { [weak self] _ in
                    guard let self = self else { return }
                    self.scrollView.isHidden = true
                    self.loadingIndicator.isHidden = true
                    self.errorLabel.isHidden = false
            })
            .disposed(by: disposeBag)
        
        smartEnergyRewardsContainerView.isHidden = !viewModel.shouldShowSmartEnergyRewards
        
        viewModel.shouldShowSmartEnergyRewardsContent
            .not()
            .drive(smartEnergyRewardsContentView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.shouldShowSmartEnergyRewardsContent
            .drive(smartEnergyRewardsEmptyStateView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.shouldShowSmartEnergyRewardsContent.asObservable()
            .filter(!)
            .subscribe(onNext: { _ in Analytics.log(event: .emptyStatePeakSmart) })
            .disposed(by: disposeBag)
        
        viewModel.smartEnergyRewardsSeasonLabelText
            .drive(smartEnergyRewardsSeasonLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.smartEnergyRewardsFooterText
            .drive(smartEnergyRewardsFooterLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case let (vc as UsageWebViewController, _):
            vc.accountDetail = accountDetail
        case let (vc as Top5EnergyTipsViewController, _):
            vc.accountDetail = accountDetail
        case let (vc as MyHomeProfileViewController, _):
            vc.accountDetail = accountDetail
            vc.didSaveHomeProfile
                .delay(0.5)
                .drive(onNext: { [weak self] in
                    self?.view.showToast(NSLocalizedString("Home profile updated", comment: ""))
                })
                .disposed(by: disposeBag)
        case let (vc as HourlyPricingViewController, _):
            vc.accountDetail = accountDetail
        case let (vc as TotalSavingsViewController, eventResults as [SERResult]):
            vc.eventResults = eventResults
        case let (vc as PeakRewardsViewController, _):
            vc.accountDetail = accountDetail
        default: break
        }
    }

}
