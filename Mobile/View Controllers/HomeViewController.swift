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

class HomeViewController: AccountPickerViewController {
    
    @IBOutlet weak var primaryColorHeaderView: UIView!
    @IBOutlet weak var headerContentView: UIView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var topLoadingIndicatorView: UIView!
    @IBOutlet weak var homeLoadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var weatherWidgetView: UIView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherIconImage: UIImageView!
    
    @IBOutlet weak var cardStackView: UIStackView!
    
    var billCardView: HomeBillCardView!
    var templateCardView: TemplateCardView!
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl? {
        didSet {
            refreshDisposable?.dispose()
            refreshDisposable = refreshControl?.rx.controlEvent(.valueChanged).asObservable()
                .map { FetchingAccountState.refresh }
                .bind(to: viewModel.fetchData)
        }
    }
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")!
    
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
            .subscribe(onNext: { state, accountDetail in
                switch(state) {
                case .loadingAccounts:
                    // Sam, do your custom loading here
                    break
                case .readyToFetchData:
                    self.viewModel.currentAccount.value = self.accountPicker.currentAccount
                    if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    } else if accountDetail == nil {
                        self.viewModel.fetchData.onNext(.switchAccount)
                    }
                }
                
            })
            .addDisposableTo(bag)
        
        billCardView = HomeBillCardView.create(withViewModel: self.viewModel.billCardViewModel)
        cardStackView.addArrangedSubview(billCardView)
        
        if viewModel.showTemplateCard {
            templateCardView = TemplateCardView.create(withViewModel: self.viewModel.templateCardViewModel)
            templateCardView.callToActionViewController
                .drive(onNext: { [weak self] viewController in
                    self?.present(viewController, animated: true, completion: nil)
                }).addDisposableTo(bag)
            cardStackView.addArrangedSubview(templateCardView)
        }
        
        styleViews()
        bindLoadingStates()
        configureAccessibility()
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: NSNotification.Name.DidMaintenanceModeTurnOn, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func killRefresh() -> Void {
        self.refreshControl?.endRefreshing()
        self.scrollView.alwaysBounceVertical = true
    }
    
    func styleViews() {
        primaryColorHeaderView.backgroundColor = .primaryColor
        scrollView.backgroundColor = .primaryColor
        weatherWidgetView.backgroundColor = .primaryColor
        headerStackView.backgroundColor = .primaryColor
        scrollView.rx.contentOffset
            .asDriver()
            .map { $0.y < 0 ? .primaryColor: .softGray }
            .drive(onNext: { [weak self] color in self?.scrollView.backgroundColor = color })
            .addDisposableTo(bag)
    }
    
    func bindLoadingStates() {
        topLoadingIndicatorView.isHidden = true
        viewModel.fetchingTracker.asDriver().filter(!).drive(rx.isRefreshing).addDisposableTo(bag)
        viewModel.switchAccountsTracker.asDriver().not().drive(rx.isPullToRefreshEnabled).addDisposableTo(bag)
        viewModel.switchAccountsTracker.asDriver().drive(homeLoadingIndicator.rx.isAnimating).addDisposableTo(bag)
        
        viewModel.weatherTemp.debug("*****").drive(temperatureLabel.rx.text).addDisposableTo(bag)
        viewModel.weatherIcon.drive(weatherIconImage.rx.image).addDisposableTo(bag)
        viewModel.greeting.drive(greetingLabel.rx.text).addDisposableTo(bag)
    }
    
    func configureAccessibility() {
        guard let greetingString = greetingLabel.text,
            let temperatureString = temperatureLabel.text else {
                greetingLabel.accessibilityLabel = NSLocalizedString("Greetings", comment: "")
                temperatureLabel.accessibilityLabel = NSLocalizedString("Temperature not available", comment: "") //TODO: not sure about these
                return
        }
        
        greetingLabel.accessibilityLabel = NSLocalizedString(greetingString, comment: "")
        temperatureLabel.accessibilityLabel = NSLocalizedString(temperatureString, comment: "")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    func showDelayedToast(withMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
    }
}

extension HomeViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchData.onNext(.switchAccount)
    }
}

extension Reactive where Base: HomeViewController {
    
    var isPullToRefreshEnabled: UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: self.base) { vc, refresh in
            if refresh {
                guard vc.refreshControl == nil else { return }
                let refreshControl = UIRefreshControl()
                vc.refreshControl = refreshControl
                refreshControl.tintColor = .white
                vc.scrollView.insertSubview(refreshControl, at: 0)
                vc.scrollView.alwaysBounceVertical = true
            } else {
                vc.refreshControl?.endRefreshing()
                vc.refreshControl?.removeFromSuperview()
                vc.refreshControl = nil
                vc.scrollView.alwaysBounceVertical = false
            }
        }
    }
    
    var isRefreshing: UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: self.base) { vc, refresh in
            if refresh {
                vc.refreshControl?.beginRefreshing()
            } else {
                vc.refreshControl?.endRefreshing()
            }
        }
    }
    
}

