//
//  HomeViewController.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import Lottie
import StoreKit
import UserNotifications

class HomeViewController: AccountPickerViewController {
    
    @IBOutlet weak var headerContentView: UIView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var topLoadingIndicatorView: UIView!
    @IBOutlet weak var homeLoadingIndicator: LoadingIndicator!
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet weak var maintenanceModeView: MaintenanceModeView!
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var cardStackView: UIStackView!
    
    @IBOutlet weak var loadingView: UIView!
    
    var weatherView: HomeWeatherView!
    var billCardView: HomeBillCardView!
    var usageCardView: HomeUsageCardView!
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl?
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")
    
    let viewModel = HomeViewModel(accountService: ServiceFactory.createAccountService(),
                                  weatherService: ServiceFactory.createWeatherService(),
                                  walletService: ServiceFactory.createWalletService(),
                                  paymentService: ServiceFactory.createPaymentService(),
                                  usageService: ServiceFactory.createUsageService(),
                                  authService: ServiceFactory.createAuthenticationService())
    
    var shortcutItem = ShortcutItem.none
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        accountPickerViewControllerWillAppear
            .withLatestFrom(Observable.combineLatest(accountPickerViewControllerWillAppear.asObservable(),
                                                     viewModel.accountDetailEvents.map { $0 }.startWith(nil)))
            .subscribe(onNext: { [weak self] state, accountDetailEvent in
                guard let `self` = self else { return }
                switch(state) {
                case .loadingAccounts:
                    self.setRefreshControlEnabled(enabled: false)
                case .readyToFetchData:
                    if AccountsStore.shared.currentAccount != self.accountPicker.currentAccount {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    } else if accountDetailEvent?.element == nil {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    }
                }
            })
            .disposed(by: bag)
        
        weatherView = HomeWeatherView.create(withViewModel: viewModel.weatherViewModel)
        mainStackView.insertArrangedSubview(weatherView, at: 1)
        weatherView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor).isActive = true
        weatherView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor).isActive = true
        
        billCardView = HomeBillCardView.create(withViewModel: viewModel.billCardViewModel)
        billCardView.oneTouchPayFinished
            .map { FetchingAccountState.switchAccount }
            .bind(to: viewModel.fetchData)
            .disposed(by: bag)
        cardStackView.addArrangedSubview(billCardView)
        
        usageCardView = HomeUsageCardView.create(withViewModel: viewModel.usageCardViewModel)
        
        Driver.merge(usageCardView.viewUsageButton.rx.touchUpInside.asDriver(),
                     usageCardView.viewUsageEmptyStateButton.rx.touchUpInside.asDriver(),
                     viewModel.shouldShowUsageCard.filter { [weak self] in $0 && self?.shortcutItem == .viewUsageOptions }.map(to: ())) // Shortcut response
            .withLatestFrom(viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                self?.shortcutItem = .none
                self?.performSegue(withIdentifier: "usageSegue", sender: $0)
            })
            .disposed(by: bag)
        
        cardStackView.addArrangedSubview(usageCardView)
        viewModel.shouldShowUsageCard.not().drive(usageCardView.rx.isHidden).disposed(by: bag)
        
        usageCardView.viewAllSavingsButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.accountDetailEvents.elements()
            .asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                Analytics.log(event: .AllSavingsSmartEnergy)
                self?.performSegue(withIdentifier: "totalSavingsSegue", sender: $0)
            }).disposed(by: bag)
        
        let templateCardView = TemplateCardView.create(withViewModel: viewModel.templateCardViewModel)
        
        templateCardView.safariViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: bag)
        
        templateCardView.pushedViewControllers
            .drive(onNext: { [weak self] viewController in
                viewController.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(viewController, animated: true)
            }).disposed(by: bag)
        
        cardStackView.addArrangedSubview(templateCardView)
        cardStackView.isHidden = true
        
        styleViews()
        bindLoadingStates()
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: .didMaintenanceModeTurnOn, object: nil)
        
        viewModel.shouldShowUsageCard
            .filter(!)
            .drive(onNext: { _ in
                (UIApplication.shared.delegate as? AppDelegate)?.configureQuickActions(isAuthenticated: true, showViewUsageOptions: false)
            })
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.log(event: .HomeOfferComplete)
        if #available(iOS 10.3, *) , AppRating.shouldRequestRating() {
            SKStoreReviewController.requestReview()
        }
        
        if Environment.shared.environmentName != .aut {
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { (granted: Bool, error: Error?) in
                    if !UserDefaults.standard.bool(forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted) {
                        UserDefaults.standard.set(true, forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted)
                        if granted {
                            Analytics.log(event: .AlertsiOSPushOKInitial)
                        } else {
                            Analytics.log(event: .AlertsiOSPushDontAllowInitial)
                        }
                    }
                })
            } else {
                let settings = UIUserNotificationSettings(types: [.badge, .alert, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
            }
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        if !UserDefaults.standard.bool(forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted) {
            Analytics.log(event: .AlertsiOSPushInitial)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        usageCardView.superviewDidLayoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shortcutItem = .none
    }
    
    func styleViews() {
        view.backgroundColor = .primaryColor
        loadingView.layer.cornerRadius = 10
        loadingView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
    }
    
    @objc func killRefresh() -> Void {
        self.refreshControl?.endRefreshing()
        self.scrollView!.alwaysBounceVertical = true
    }
    
    @objc func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            refreshControl?.tintColor = .white
            scrollView!.insertSubview(refreshControl!, at: 0)
            scrollView!.alwaysBounceVertical = true
        } else {
            if let rc = refreshControl {
                rc.endRefreshing()
                rc.removeFromSuperview()
                refreshControl = nil
            }
            scrollView!.alwaysBounceVertical = false
        }
    }
    
    @objc func onPullToRefresh() {
        viewModel.fetchData.onNext(.refresh)
    }
    
    func bindLoadingStates() {
        topLoadingIndicatorView.isHidden = true
        
        Observable.merge(viewModel.refreshFetchTracker.asObservable(), viewModel.isSwitchingAccounts.asObservable())
            .subscribe(onNext: { _ in UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil) })
            .disposed(by: bag)
        
        viewModel.refreshFetchTracker.asDriver().filter(!)
            .drive(onNext: { [weak self] _ in
                self?.refreshControl?.endRefreshing()
            }).disposed(by: bag)
        
        viewModel.isSwitchingAccounts.asDriver().not().drive(onNext: { [weak self] refresh in
            guard let `self` = self else { return }
            self.setRefreshControlEnabled(enabled: refresh)
        }).disposed(by: bag)
        
        viewModel.isSwitchingAccounts.asDriver().drive(homeLoadingIndicator.rx.isAnimating).disposed(by: bag)
        viewModel.isSwitchingAccounts.asDriver().drive(cardStackView.rx.isHidden).disposed(by: bag)
        viewModel.isSwitchingAccounts.asDriver().not().drive(loadingView.rx.isHidden).disposed(by: bag)
        
        viewModel.showNoNetworkConnectionState.not().drive(noNetworkConnectionView.rx.isHidden).disposed(by: bag)
        viewModel.showMaintenanceModeState.not().drive(maintenanceModeView.rx.isHidden).disposed(by: bag)
        
        Driver.combineLatest(viewModel.showNoNetworkConnectionState, viewModel.showMaintenanceModeState)
        { $0 || $1 }
            .drive(scrollView!.rx.isHidden).disposed(by: bag)
        
        Observable.merge(maintenanceModeView.reload, noNetworkConnectionView.reload)
            .map(to: FetchingAccountState.switchAccount)
            .bind(to: viewModel.fetchData)
            .disposed(by: bag)
        
        billCardView.viewBillPressed
            .drive(onNext: { [weak self] in
                self?.tabBarController?.selectedIndex = 1
            })
            .disposed(by: bag)
        
        billCardView.modalViewControllers
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        billCardView.pushedViewControllers
            .drive(onNext: { [weak self] viewController in
                guard let `self` = self else { return }
                
                if let vc = viewController as? WalletViewController {
                    vc.didUpdate
                        .asDriver(onErrorDriveWith: .empty())
                        .delay(0.5)
                        .drive(onNext: { [weak self] toastMessage in
                            self?.view.showToast(toastMessage)
                        })
                        .disposed(by: vc.disposeBag)
                } else if let vc = viewController as? AutoPayViewController {
                    vc.delegate = self
                } else if let vc = viewController as? BGEAutoPayViewController {
                    vc.delegate = self
                }
                
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: bag)
        
        weatherView.didTapTemperatureTip
            .map(InfoModalViewController.init)
            .drive(onNext: { [weak self] in
                self?.present($0, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        // Clear shortcut handling in the case of an error.
        Observable.merge(viewModel.usageCardViewModel.accountDetailChanged.errors(),
                         viewModel.accountDetailEvents.errors())
            .subscribe(onNext: { [weak self] _ in
                self?.shortcutItem = .none
            })
            .disposed(by: bag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UsageViewController, let accountDetail = sender as? AccountDetail {
            vc.accountDetail = accountDetail
        } else if let vc = segue.destination as? TotalSavingsViewController, let accountDetail = sender as? AccountDetail {
            vc.eventResults = accountDetail.serInfo.eventResults
        }
    }
    
}

extension HomeViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchData.onNext(.switchAccount)
    }
}

extension HomeViewController: AutoPayViewControllerDelegate {
    
    func autoPayViewController(_ autoPayViewController: AutoPayViewController, enrolled: Bool) {
        let message = enrolled ? NSLocalizedString("Enrolled in AutoPay", comment: ""): NSLocalizedString("Unenrolled from AutoPay", comment: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
        if enrolled {
            Analytics.log(event: .AutoPayEnrollComplete)
        } else {
            Analytics.log(event: .AutoPayUnenrollComplete)
        }
    }
    
}

extension HomeViewController: BGEAutoPayViewControllerDelegate {
    
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
    }
}

