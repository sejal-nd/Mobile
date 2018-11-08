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
import SafariServices

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
    
    @IBOutlet weak var personalizeButton: UIButton!
    
    var weatherView: HomeWeatherView!
    var importantUpdateView: HomeUpdateView?
    var appointmentCardView: HomeAppointmentCardView?
    var billCardView: HomeBillCardView?
    var usageCardView: HomeUsageCardView?
    var templateCardView: TemplateCardView?
    var projectedBillCardView: HomeProjectedBillCardView?
    var outageCardView: HomeOutageCardView?
    var topPersonalizeButton: ConversationalButton?
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl?
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")
    
    let viewModel = HomeViewModel(accountService: ServiceFactory.createAccountService(),
                                  weatherService: ServiceFactory.createWeatherService(),
                                  walletService: ServiceFactory.createWalletService(),
                                  paymentService: ServiceFactory.createPaymentService(),
                                  usageService: ServiceFactory.createUsageService(),
                                  authService: ServiceFactory.createAuthenticationService(),
                                  outageService: ServiceFactory.createOutageService(),
                                  alertsService: ServiceFactory.createAlertsService(),
                                  appointmentService: ServiceFactory.createAppointmentService())
    
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
            .withLatestFrom(viewModel.accountDetailEvents.map { $0 }.startWith(nil)) { ($0, $1) }
            .subscribe(onNext: { [weak self] state, accountDetailEvent in
                guard let `self` = self else { return }
                switch(state) {
                case .loadingAccounts:
                    self.setRefreshControlEnabled(enabled: false)
                case .readyToFetchData:
                    self.setRefreshControlEnabled(enabled: true)
                    if AccountsStore.shared.currentAccount != self.accountPicker.currentAccount {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    } else if accountDetailEvent?.element == nil {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    }
                }
            })
            .disposed(by: bag)
        
        viewModel.accountDetailEvents.elements()
            .take(1)
            .subscribe(onNext: { accountDetail in
                let residentialAMIString = String(format: "%@%@", accountDetail.isResidential ? "Residential/" : "Commercial/", accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
                
                let isPeakSmart = (Environment.shared.opco == .bge && accountDetail.isSERAccount) ||
                    (Environment.shared.opco != .bge && accountDetail.isPTSAccount)
                
                Analytics.log(event: .accountLoaded,
                              dimensions: [.residentialAMI: residentialAMIString,
                                           .bgeControlGroup: accountDetail.isBGEControlGroup ? "true" : "false",
                                           .peakSmart: isPeakSmart ? "true" : "false"])
            })
            .disposed(by: bag)
        
        viewSetup()
        styleViews()
        bindLoadingStates()
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: .didMaintenanceModeTurnOn, object: nil)
    }
    
    func viewSetup() {
        // Observe selected card list
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
        
        // Create weather card
        weatherView = .create(withViewModel: viewModel.weatherViewModel)
        mainStackView.insertArrangedSubview(weatherView, at: 1)
        weatherView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor).isActive = true
        weatherView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor).isActive = true
        
        weatherView.didTapTemperatureTip
            .map(InfoModalViewController.init)
            .drive(onNext: { [weak self] in
                self?.present($0, animated: true, completion: nil)
            })
            .disposed(by: weatherView.bag)
        
        // Top personalize button logic
        let versionString = UserDefaults.standard.string(forKey: UserDefaultKeys.homeCardCustomizeTappedVersion) ?? "0.0.0"
        let tappedVersion = Version(string: versionString) ?? Version(major: 0, minor: 0, patch: 0)
        if tappedVersion < viewModel.latestNewCardVersion {
            topPersonalizeButtonSetup()
        }
        
        // Appointment Card
        viewModel.showAppointmentCard
            .distinctUntilChanged()
            .drive(onNext: { [weak self] showAppointmentCard in
                guard let self = self else { return }
                
                guard showAppointmentCard else {
                    self.appointmentCardView?.removeFromSuperview()
                    self.appointmentCardView = nil
                    return
                }
                
                let appointmentCardView = HomeAppointmentCardView
                    .create(withViewModel: self.viewModel.appointmentCardViewModel)
                
                appointmentCardView.bottomButton.rx.touchUpInside.asObservable()
                    .withLatestFrom(Observable.combineLatest(self.viewModel.appointmentCardViewModel.appointments,
                                                             self.viewModel.accountDetailEvents.elements()))
                    .asDriver(onErrorDriveWith: .empty())
                    .drive(onNext: { [weak self] appointments, accountDetail in
                        guard let self = self else { return }
                        let appointment = appointments[0]
                        
                        let status: Appointment.Status
                        if appointments.count > 1 {
                            status = .scheduled
                        } else {
                            status = appointment.status
                        }
                        
                        switch status {
                        case .scheduled, .inProgress, .enRoute:
                            self.performSegue(withIdentifier: "appointmentDetailSegue",
                                              sender: (appointments, accountDetail.premiseNumber!))
                        case .complete:
                            let safariVC = SFSafariViewController
                                .createWithCustomStyle(url: URL(string: "https://google.com")!)
                            self.present(safariVC, animated: true, completion: nil)
                        case .canceled:
                            UIApplication.shared.openPhoneNumberIfCan(self.viewModel.appointmentCardViewModel.contactNumber)
                        }
                    })
                    .disposed(by: appointmentCardView.disposeBag)
                
                let index = self.topPersonalizeButton != nil ? 1 : 0
                self.contentStackView.insertArrangedSubview(appointmentCardView, at: index)
                self.appointmentCardView = appointmentCardView
            })
            .disposed(by: bag)
        
        // If no update, show weather and personalize button at the top.
        // Hide the update view.
        viewModel.importantUpdate
            .filter { $0 == nil }
            .drive(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.weatherView.isHidden = false
                this.topPersonalizeButton?.isHidden = false
                this.importantUpdateView?.removeFromSuperview()
                this.importantUpdateView = nil
            })
            .disposed(by: bag)
        
        // If update, show the update view.
        // Hide weather and personalize button at the top.
        viewModel.importantUpdate
            .filter { $0 != nil }
            .drive(onNext: { [weak self] update in
                guard let this = self, let update = update else { return }
                this.weatherView.isHidden = true
                this.topPersonalizeButton?.isHidden = true
                
                if let importantUpdateView = this.importantUpdateView {
                    importantUpdateView.configure(withUpdate: update)
                } else {
                    let importantUpdateView = HomeUpdateView.create(withUpdate: update)
                    this.mainStackView.insertArrangedSubview(importantUpdateView, at: 1)
                    importantUpdateView.addTabletWidthConstraints(horizontalPadding: 16)
                    importantUpdateView.button.rx.touchUpInside.asDriver()
                        .drive(onNext: { [weak self] in
                            self?.performSegue(withIdentifier: "UpdatesDetailSegue", sender: update)
                        })
                        .disposed(by: importantUpdateView.disposeBag)
                    
                    this.importantUpdateView = importantUpdateView
                }
            })
            .disposed(by: bag)
        
        // Bottom personalize button setup
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
    }
    
    func topPersonalizeButtonSetup() {
        let topPersonalizeButton = ConversationalButton()
        
        contentStackView.insertArrangedSubview(topPersonalizeButton, at: 0)
        
        topPersonalizeButton.titleText = NSLocalizedString("Did you know you can personalize your home screen?", comment: "")
        
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
        Analytics.log(event: .homeOfferComplete)
        if #available(iOS 10.3, *), AppRating.shouldRequestRating() {
            SKStoreReviewController.requestReview()
        }
        
        if Environment.shared.environmentName != .aut {
            let authOptions: UNAuthorizationOptions
            if #available(iOS 12, *) {
                authOptions = [.badge, .alert, .sound, .providesAppNotificationSettings]
            } else {
                authOptions = [.badge, .alert, .sound]
            }
            
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { (granted: Bool, error: Error?) in
                if !UserDefaults.standard.bool(forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted) {
                    UserDefaults.standard.set(true, forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted)
                    if granted {
                        Analytics.log(event: .alertsiOSPushOKInitial)
                    } else {
                        Analytics.log(event: .alertsiOSPushDontAllowInitial)
                    }
                }
            })
            
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        if !UserDefaults.standard.bool(forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted) {
            Analytics.log(event: .alertsiOSPushInitial)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        usageCardView?.superviewDidLayoutSubviews()
    }
    
    func styleViews() {
        view.backgroundColor = .primaryColorAccountPicker
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
        case .projectedBill:
            projectedBillCardView = nil
        case .outageStatus:
            outageCardView = nil
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
                billCardView = .create(withViewModel: viewModel.billCardViewModel)
                self.billCardView = billCardView
                bindBillCard()
            }
            
            return billCardView
        case .usage:
            let usageCardView: HomeUsageCardView
            if let billCard = self.usageCardView {
                usageCardView = billCard
            } else {
                usageCardView = .create(withViewModel: viewModel.usageCardViewModel)
                self.usageCardView = usageCardView
                bindUsageCard()
            }
            
            return usageCardView
        case .template:
            let templateCardView: TemplateCardView
            if let templateCard = self.templateCardView {
                templateCardView = templateCard
            } else {
                templateCardView = .create(withViewModel: viewModel.templateCardViewModel)
                self.templateCardView = templateCardView
                bindTemplateCard()
            }
            
            return templateCardView
        case .projectedBill:
            let projectedBillCardView: HomeProjectedBillCardView
            if let projectedBillCard = self.projectedBillCardView {
                projectedBillCardView = projectedBillCard
            } else {
                projectedBillCardView = .create(withViewModel: viewModel.projectedBillCardViewModel)
                self.projectedBillCardView = projectedBillCardView
                bindProjectedBillCard()
            }
            return projectedBillCardView
        case .outageStatus:
            let outageCardView: HomeOutageCardView
            if let outageCard = self.outageCardView {
                outageCardView = outageCard
            } else {
                outageCardView = .create(withViewModel: viewModel.outageCardViewModel)
                self.outageCardView = outageCardView
                bindOutageCard()
            }
            
            return outageCardView
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

        usageCardView.viewUsageButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.accountDetailEvents.elements()
                .asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                let residentialAMIString = String(format: "%@%@", $0.isResidential ? "Residential/" : "Commercial/", $0.isAMIAccount ? "AMI" : "Non-AMI")
                
                let isPeakSmart = (Environment.shared.opco == .bge && $0.isSERAccount) ||
                    (Environment.shared.opco != .bge && $0.isPTSAccount)
                
                Analytics.log(event: .viewUsageLink,
                              dimensions: [.residentialAMI: residentialAMIString,
                                           .peakSmart: isPeakSmart ? "true" : "false"])
                self?.tabBarController?.selectedIndex = 3
            })
            .disposed(by: usageCardView.disposeBag)
        
        usageCardView.viewAllSavingsButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.accountDetailEvents.elements()
                .asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                Analytics.log(event: .allSavingsSmartEnergy)
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
        
        projectedBillCardView.viewMoreButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.projectedBillCardViewModel.isGas)
            .drive(onNext: { [weak self] isGas in
                guard let tabBarCtl = self?.tabBarController as? MainTabBarController else {
                    return
                }
                
                tabBarCtl.navigateToUsage(selectedBar: .projected, isGas: isGas, isPreviousBill: true)
            }).disposed(by: projectedBillCardView.disposeBag)
        
        projectedBillCardView.infoButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            let alertVc = UIAlertController(title: NSLocalizedString("Estimated Amount", comment: ""),
                                            message: NSLocalizedString("This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: ""),
                                            preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        }).disposed(by: projectedBillCardView.disposeBag)
    }
    
    func bindOutageCard() {
        guard let outageCardView = outageCardView else { return }
        
        outageCardView.reportOutageTapped
            .drive(onNext: { [weak self] outageStatus in
                self?.performSegue(withIdentifier: "reportOutageSegue", sender: outageStatus)
            })
            .disposed(by: outageCardView.bag)
        
        outageCardView.viewOutageMapTapped
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "outageMapSegue", sender: nil)
            })
            .disposed(by: outageCardView.bag)
    }
    
    @objc func killRefresh() -> Void {
        self.refreshControl?.endRefreshing()
        self.scrollView!.alwaysBounceVertical = true
    }
    
    @objc func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            scrollView!.alwaysBounceVertical = true
            
            guard refreshControl == nil else { return }
            
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            refreshControl?.tintColor = .white
            scrollView!.insertSubview(refreshControl!, at: 0)
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
        viewModel.refreshFetchTracker.asObservable()
            .subscribe(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
            .disposed(by: bag)
        
        viewModel.refreshFetchTracker.asDriver().filter(!)
            .drive(onNext: { [weak self] _ in
                self?.refreshControl?.endRefreshing()
            }).disposed(by: bag)
        viewModel.showNoNetworkConnectionState.not().drive(noNetworkConnectionView.rx.isHidden).disposed(by: bag)
        viewModel.showMaintenanceModeState.not().drive(maintenanceModeView.rx.isHidden).disposed(by: bag)
        
        Driver.combineLatest(viewModel.showNoNetworkConnectionState, viewModel.showMaintenanceModeState)
        { $0 || $1 }
            .drive(scrollView!.rx.isHidden).disposed(by: bag)
        
        Observable.merge(maintenanceModeView.reload, noNetworkConnectionView.reload)
            .mapTo(FetchingAccountState.switchAccount)
            .bind(to: viewModel.fetchData)
            .disposed(by: bag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case let (vc as AppointmentsViewController, (appointments, premiseNumber) as ([Appointment], String)):
            vc.appointments = appointments
            vc.premiseNumber = premiseNumber
            vc.viewModel.appointments
                .skip(1) // First element just repeats the one passed in from this screen.
                .bind(to: viewModel.appointmentsUpdates)
                .disposed(by: vc.disposeBag)
        case let (vc as SmartEnergyRewardsViewController, accountDetail as AccountDetail):
            vc.accountDetail = accountDetail
        case let (vc as TotalSavingsViewController, accountDetail as AccountDetail):
            vc.eventResults = accountDetail.serInfo.eventResults
        case let (vc as UpdatesDetailViewController, update as OpcoUpdate):
            vc.opcoUpdate = update
        case let (vc as ReportOutageViewController, currentOutageStatus as OutageStatus):
            vc.viewModel.outageStatus = currentOutageStatus
            if let phone = currentOutageStatus.contactHomeNumber {
                vc.viewModel.phoneNumber.value = phone
            }
            
            // Show a toast only after an outage is reported from this workflow
            RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
                .drive(onNext: { [weak self] in
                    guard let this = self else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                        this.view.showToast(NSLocalizedString("Outage report received", comment: ""))
                        Analytics.log(event: .reportOutageAuthComplete)
                    })
                })
                .disposed(by: vc.disposeBag)
        default:
            break
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
            Analytics.log(event: .autoPayEnrollComplete)
        } else {
            Analytics.log(event: .autoPayUnenrollComplete)
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
