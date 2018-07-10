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

fileprivate let editHomeSegueId = "editHomeSegue"

class HomeViewController: AccountPickerViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backgroundTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerContentView: UIView!
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet weak var maintenanceModeView: MaintenanceModeView!
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var cardStackView: UIStackView!
    
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var personalizeButton: UIButton!
    
    var weatherView: HomeWeatherView!
    var billCardView: HomeBillCardView?
    var usageCardView: HomeUsageCardView?
    var templateCardView: TemplateCardView?
    var projectedBillCardView: HomeProjectedBillCardView?
    var topPersonalizeButton: ButtonControl?
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl?
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")
    
    let viewModel = HomeViewModel(accountService: ServiceFactory.createAccountService(),
                                  weatherService: ServiceFactory.createWeatherService(),
                                  walletService: ServiceFactory.createWalletService(),
                                  paymentService: ServiceFactory.createPaymentService(),
                                  usageService: ServiceFactory.createUsageService(),
                                  authService: ServiceFactory.createAuthenticationService())
    
    // Should be moved when we add the Usage tab.
    var shortcutItem = ShortcutItem.none
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        backgroundView.backgroundColor = .primaryColor
        scrollView?.rx.contentOffset.asDriver()
            .map { -min(0, $0.y) }
            .distinctUntilChanged()
            .drive(backgroundTopConstraint.rx.constant)
            .disposed(by: bag)
        
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
        
        HomeCardPrefsStore.shared.listObservable
            .scan(([HomeCard](), [HomeCard]())) { oldCards, newCards in (oldCards.1, newCards) }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] (oldCards, newCards) in
                self?.scrollView?.setContentOffset(.zero, animated: false)
                
                // Perform reorder if preference changed
                guard oldCards != newCards else { return }
                self?.setCards(oldCards: oldCards, newCards: newCards)
                
                // Refresh if not first load and new card(s) added
                if !oldCards.isEmpty && !Set(newCards).subtracting(oldCards).isEmpty {
                    self?.viewModel.fetchData.onNext(.switchAccount)
                }
            })
            .disposed(by: bag)
        
        contentStackView.isHidden = true
        
        let versionString = UserDefaults.standard.string(forKey: UserDefaultKeys.homeCardCustomizeTappedVersion) ?? "0.0.0"
        let tappedVersion = Version(string: versionString) ?? Version(major: 0, minor: 0, patch: 0)
        if tappedVersion < viewModel.latestNewCardVersion {
            topPersonalizeButtonSetup()
        }
        
        personalizeButton.setTitleColor(.white, for: .normal)
        personalizeButton.titleLabel?.font = SystemFont.bold.of(textStyle: .title1)
        personalizeButton.titleLabel?.numberOfLines = 0
        personalizeButton.titleLabel?.textAlignment = .center
        personalizeButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let this = self else { return }
                UserDefaults.standard.set(Version.current.string, forKey: UserDefaultKeys.homeCardCustomizeTappedVersion)
                this.performSegue(withIdentifier: editHomeSegueId, sender: nil)
                
                guard let button = this.topPersonalizeButton else { return }
                UIView.animate(withDuration: 0.15, animations: {
                    button.isHidden = true
                }, completion: { _ in
                    this.cardStackView.removeArrangedSubview(button)
                    button.removeFromSuperview()
                    this.topPersonalizeButton = nil
                })
            })
            .disposed(by: bag)
        
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
    
    func topPersonalizeButtonSetup() {
        let topPersonalizeButton = ButtonControl().usingAutoLayout()
        topPersonalizeButton.backgroundColorOnPress = .softGray
        topPersonalizeButton.normalBackgroundColor = .white
        topPersonalizeButton.layer.cornerRadius = 10
        topPersonalizeButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        let label = UILabel()
        label.text = NSLocalizedString("Did you know you can personalize your home screen?", comment: "")
        label.font = SystemFont.semibold.of(textStyle: .subheadline)
        label.textColor = .actionBlue
        label.numberOfLines = 0
        label.setLineHeight(lineHeight: 20)
        let caretImageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
        caretImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        caretImageView.setContentHuggingPriority(.required, for: .horizontal)
        let buttonStack = UIStackView().usingAutoLayout()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 15
        buttonStack.distribution = .fill
        buttonStack.alignment = .center
        buttonStack.isUserInteractionEnabled = false
        
        [label, caretImageView].forEach(buttonStack.addArrangedSubview)
        
        topPersonalizeButton.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: topPersonalizeButton.leadingAnchor, constant: 25),
            buttonStack.trailingAnchor.constraint(equalTo: topPersonalizeButton.trailingAnchor, constant: -14),
            buttonStack.topAnchor.constraint(equalTo: topPersonalizeButton.topAnchor, constant: 9),
            buttonStack.bottomAnchor.constraint(equalTo: topPersonalizeButton.bottomAnchor, constant: -12)
            ])
        
        contentStackView.insertArrangedSubview(topPersonalizeButton, at: 0)
        
        topPersonalizeButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self, weak topPersonalizeButton] in
                guard let this = self, let button = topPersonalizeButton else { return }
                UserDefaults.standard.set(Version.current.string, forKey: UserDefaultKeys.homeCardCustomizeTappedVersion)
                this.performSegue(withIdentifier: editHomeSegueId, sender: nil)
                UIView.animate(withDuration: 0.15, animations: {
                    button.isHidden = true
                }, completion: { _ in
                    this.cardStackView.removeArrangedSubview(button)
                    button.removeFromSuperview()
                    this.topPersonalizeButton = nil
                })
            })
            .disposed(by: bag)
        
        self.topPersonalizeButton = topPersonalizeButton
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
        usageCardView?.superviewDidLayoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shortcutItem = .none
    }
    
    func styleViews() {
        view.backgroundColor = .primaryColorAccountPicker
        loadingView.layer.cornerRadius = 10
        loadingView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
    }
    
    func setCards(oldCards: [HomeCard], newCards: [HomeCard]) {
        Set(oldCards)
            .subtracting(newCards)
            .forEach { removeCardView(forCard: $0) }
        
        newCards
            .map(cardView)
            .enumerated()
            .forEach { index, view in
                cardStackView.insertArrangedSubview(view, at: index)
        }
    }
    
    func removeCardView(forCard card: HomeCard) {
        let view = cardView(forCard: card)
        cardStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        
        switch card {
        case .bill:
            billCardView = nil
        case .usage:
            usageCardView = nil
        case .template:
            templateCardView = nil
        default:
            fatalError(card.displayString + " card view doesn't exist yet")
        }
    }
    
    func cardView(forCard card: HomeCard) -> UIView {
        switch card {
        case .bill:
            let billCardView: HomeBillCardView
            if let billCard = self.billCardView {
                billCardView = billCard
            } else {
                billCardView = HomeBillCardView.create(withViewModel: viewModel.billCardViewModel)
                self.billCardView = billCardView
                bindBillCard()
            }
            
            return billCardView
        case .usage:
            let usageCardView: HomeUsageCardView
            if let billCard = self.usageCardView {
                usageCardView = billCard
            } else {
                usageCardView = HomeUsageCardView.create(withViewModel: viewModel.usageCardViewModel)
                self.usageCardView = usageCardView
                bindUsageCard()
            }
            
            return usageCardView
        case .template:
            let templateCardView: TemplateCardView
            if let templateCard = self.templateCardView {
                templateCardView = templateCard
            } else {
                templateCardView = TemplateCardView.create(withViewModel: viewModel.templateCardViewModel)
                self.templateCardView = templateCardView
                bindTemplateCard()
            }
            
            return templateCardView
        case .projectedBill:
            let projectedBillCardView: HomeProjectedBillCardView
            if let projectedBillCard = self.projectedBillCardView {
                projectedBillCardView = projectedBillCard
            } else {
                projectedBillCardView = HomeProjectedBillCardView.create(withViewModel: viewModel.projectedBillCardViewModel)
                self.projectedBillCardView = projectedBillCardView
                bindProjectedBillCard()
            }
            return projectedBillCardView
        default:
            fatalError(card.displayString + " card view doesn't exist yet")
        }
    }
    
    func bindBillCard() {
        guard let billCardView = billCardView else { return }
        
        billCardView.oneTouchPayFinished
            .map { FetchingAccountState.switchAccount }
            .bind(to: viewModel.fetchData)
            .disposed(by: billCardView.bag)
        
        billCardView.viewBillPressed
            .drive(onNext: { [weak self] in
                self?.tabBarController?.selectedIndex = 1
            })
            .disposed(by: billCardView.bag)
        
        billCardView.modalViewControllers
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            })
            .disposed(by: billCardView.bag)
        
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
            .disposed(by: billCardView.bag)
    }
    
    func bindUsageCard() {
        guard let usageCardView = usageCardView else { return }
        
        Driver.merge(usageCardView.viewUsageButton.rx.touchUpInside.asDriver(),
                     usageCardView.viewUsageEmptyStateButton.rx.touchUpInside.asDriver(),
                     viewModel.shouldShowUsageCard.filter { [weak self] in $0 && self?.shortcutItem == .viewUsageOptions }.map(to: ())) // Shortcut response
            .withLatestFrom(viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                self?.shortcutItem = .none
                self?.performSegue(withIdentifier: "usageSegue", sender: $0)
            })
            .disposed(by: usageCardView.disposeBag)
        
        viewModel.shouldShowUsageCard.not().drive(usageCardView.rx.isHidden).disposed(by: usageCardView.disposeBag)
        
        usageCardView.viewAllSavingsButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.accountDetailEvents.elements()
                .asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                Analytics.log(event: .AllSavingsSmartEnergy)
                self?.performSegue(withIdentifier: "totalSavingsSegue", sender: $0)
            }).disposed(by: usageCardView.disposeBag)
    }
    
    func bindTemplateCard() {
        guard let templateCardView = templateCardView else { return }
        
        templateCardView.safariViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: templateCardView.bag)
        
        templateCardView.pushedViewControllers
            .drive(onNext: { [weak self] viewController in
                viewController.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(viewController, animated: true)
            }).disposed(by: templateCardView.bag)
    }
    
    func bindProjectedBillCard() {
        guard let projectedBillCardView = projectedBillCardView else { return }
        
        viewModel.shouldShowProjectedBillCard.not().drive(projectedBillCardView.rx.isHidden).disposed(by: projectedBillCardView.disposeBag)
        
        projectedBillCardView.viewMoreButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.accountDetailEvents.elements()
                .asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                let billAnalysis = BillAnalysisViewController()
                billAnalysis.hidesBottomBarWhenPushed = true
                billAnalysis.viewModel.accountDetail = $0
                self?.navigationController?.pushViewController(billAnalysis, animated: true)
            }).disposed(by: projectedBillCardView.disposeBag)
        
        projectedBillCardView.infoButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            let alertVc = UIAlertController(title: NSLocalizedString("Estimated Amount", comment: ""),
                                            message: NSLocalizedString("This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: ""),
                                            preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        }).disposed(by: projectedBillCardView.disposeBag)
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
        
        viewModel.isSwitchingAccounts.asDriver().drive(contentStackView.rx.isHidden).disposed(by: bag)
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

