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

class HomeViewController: AccountPickerViewController {
    
    @IBOutlet weak var primaryColorHeaderView: UIView!
    @IBOutlet weak var headerContentView: UIView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var topLoadingIndicatorView: UIView!
    @IBOutlet weak var homeLoadingIndicator: LoadingIndicator!
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    
    @IBOutlet weak var weatherView: UIView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherIconImage: UIImageView!
    
    @IBOutlet weak var cardStackView: UIStackView!
    
    @IBOutlet weak var loadingView: UIView!
    
    var billCardView: HomeBillCardView!
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl? {
        didSet {
            refreshDisposable?.dispose()
            refreshDisposable = refreshControl?.rx.controlEvent(.valueChanged).asObservable()
                .map { FetchingAccountState.refresh }
                .bind(to: viewModel.fetchData)
        }
    }
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")
    
    let viewModel = HomeViewModel(accountService: ServiceFactory.createAccountService(),
                                  weatherService: ServiceFactory.createWeatherService(),
                                  walletService: ServiceFactory.createWalletService(),
                                  paymentService: ServiceFactory.createPaymentService())
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        accountPickerViewControllerWillAppear
            .withLatestFrom(Observable.combineLatest(accountPickerViewControllerWillAppear.asObservable(),
                                                     viewModel.accountDetailEvents.elements().map { $0 }.startWith(nil)))
            .subscribe(onNext: { [weak self] state, accountDetail in
                guard let `self` = self else { return }
                switch(state) {
                case .loadingAccounts:
                    // Sam, do your custom loading here
                    break
                case .readyToFetchData:
                    if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    } else if accountDetail == nil {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    }
                }
                
            })
            .disposed(by: bag)
        
        billCardView = HomeBillCardView.create(withViewModel: viewModel.billCardViewModel)
        billCardView.oneTouchPayFinished
            .map { FetchingAccountState.switchAccount }
            .bind(to: viewModel.fetchData)
            .disposed(by: bag)
        cardStackView.addArrangedSubview(billCardView)
        
        if viewModel.showTemplateCard {
            let templateCardView = TemplateCardView.create(withViewModel: viewModel.templateCardViewModel)
            templateCardView.callToActionViewController
                .drive(onNext: { [weak self] viewController in
                    self?.present(viewController, animated: true, completion: nil)
                }).disposed(by: bag)
            cardStackView.addArrangedSubview(templateCardView)
        }
        cardStackView.isHidden = true
        
        styleViews()
        bindLoadingStates()
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: NSNotification.Name.DidMaintenanceModeTurnOn, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics().logScreenView(AnalyticsPageView.HomeOfferComplete.rawValue)
        if #available(iOS 10.3, *) , AppRating.shouldRequestRating() {
            SKStoreReviewController.requestReview()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    func killRefresh() -> Void {
        self.refreshControl?.endRefreshing()
        self.scrollView.alwaysBounceVertical = true
    }
    
    func styleViews() {
        view.backgroundColor = .primaryColor
        primaryColorHeaderView.backgroundColor = .primaryColor
        loadingView.layer.cornerRadius = 2
        loadingView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        greetingLabel.isAccessibilityElement = true
        temperatureLabel.isAccessibilityElement = true
        weatherIconImage.isAccessibilityElement = true
        weatherView.accessibilityElements = [greetingLabel, temperatureLabel, weatherIconImage]
    }
    
    func bindLoadingStates() {
        topLoadingIndicatorView.isHidden = true
        
        viewModel.isRefreshing.filter(!).drive(onNext: { [weak self] refresh in
            if refresh {
                self?.refreshControl?.beginRefreshing()
            } else {
                self?.refreshControl?.endRefreshing()
            }
        }).disposed(by: bag)
        
        viewModel.isSwitchingAccounts.not().drive(onNext: { [weak self] refresh in
            guard let `self` = self else { return }
            if refresh {
                guard self.refreshControl == nil else { return }
                let refreshControl = UIRefreshControl()
                self.refreshControl = refreshControl
                refreshControl.tintColor = .white
                self.scrollView.insertSubview(refreshControl, at: 0)
                self.scrollView.alwaysBounceVertical = true
            } else {
                self.refreshControl?.endRefreshing()
                self.refreshControl?.removeFromSuperview()
                self.refreshControl = nil
                self.scrollView.alwaysBounceVertical = false
            }
        }).disposed(by: bag)
        
        viewModel.isSwitchingAccounts.drive(homeLoadingIndicator.rx.isAnimating).disposed(by: bag)
        viewModel.isSwitchingAccounts.drive(cardStackView.rx.isHidden).disposed(by: bag)
        viewModel.isSwitchingAccounts.not().drive(loadingView.rx.isHidden).disposed(by: bag)
        
        viewModel.showNoNetworkConnectionState.not().drive(noNetworkConnectionView.rx.isHidden).disposed(by: bag)
        viewModel.showNoNetworkConnectionState.drive(scrollView.rx.isHidden).disposed(by: bag)
        
        viewModel.isSwitchingAccounts.drive(greetingLabel.rx.isHidden).disposed(by: bag)
        viewModel.isSwitchingAccounts.drive(temperatureLabel.rx.isHidden).disposed(by: bag)
        viewModel.isSwitchingAccounts.drive(weatherIconImage.rx.isHidden).disposed(by: bag)
        
        viewModel.showWeatherDetails.not().drive(temperatureLabel.rx.isHidden).disposed(by: bag)
        viewModel.showWeatherDetails.not().drive(weatherIconImage.rx.isHidden).disposed(by: bag)
        viewModel.showWeatherDetails.drive(temperatureLabel.rx.isAccessibilityElement).disposed(by: bag)
        viewModel.showWeatherDetails.drive(weatherIconImage.rx.isAccessibilityElement).disposed(by: bag)
        
        viewModel.greeting.drive(greetingLabel.rx.text).disposed(by: bag)
        viewModel.weatherTemp.drive(temperatureLabel.rx.text).disposed(by: bag)
        viewModel.weatherIcon.drive(weatherIconImage.rx.image).disposed(by: bag)
        viewModel.weatherIconA11yLabel.drive(weatherIconImage.rx.accessibilityLabel).disposed(by: bag)
        
        noNetworkConnectionView.reload
            .map { FetchingAccountState.switchAccount }
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
                }
                
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: bag)
        
    }
    
}

extension HomeViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchData.onNext(.switchAccount)
    }
}


