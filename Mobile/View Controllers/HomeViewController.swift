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
    
    @IBOutlet weak var headerContentView: UIView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var topLoadingIndicatorView: UIView!
    @IBOutlet weak var homeLoadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var weatherWidgetView: UIView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherIconImage: UIImageView!
    
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl? {
        didSet {
            refreshDisposable?.dispose()
            refreshDisposable = refreshControl?.rx.controlEvent(.valueChanged).asObservable()
                .map { FetchingAccountState.refresh }
                .bind(to: viewModel.fetchAccountDetail)
        }
    }
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")!
    
    let viewModel = HomeViewModel(accountService: ServiceFactory.createAccountService(), weatherService: ServiceFactory.createWeatherService())
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { state in
            switch(state) {
            case .loadingAccounts:
                // Sam, do your custom loading here
                break
            case .readyToFetchData:
                if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                    self.viewModel.fetchAccountDetail(isRefresh: false)
                } else if self.viewModel.currentAccountDetail.value == nil {
                    self.viewModel.fetchAccountDetail(isRefresh: false)
                }
            }
        }).addDisposableTo(bag)
        
        styleViews()
        bindLoadingStates()
        configureAccessibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func styleViews() {
        scrollView.backgroundColor = .primaryColor
        weatherWidgetView.backgroundColor = .primaryColor
        headerStackView.backgroundColor = .primaryColor
    }
    
    func bindLoadingStates() {
        topLoadingIndicatorView.isHidden = true
        viewModel.isFetchingAccountDetail.filter(!).drive(rx.isRefreshing).addDisposableTo(bag)
        viewModel.isFetchingDifferentAccount.not().drive(rx.isPullToRefreshEnabled).addDisposableTo(bag)
        viewModel.isFetchingDifferentAccount.drive(homeLoadingIndicator.rx.isAnimating).addDisposableTo(bag)
        
        self.viewModel.weatherTemp.drive(self.temperatureLabel.rx.text).addDisposableTo(self.bag)
        self.viewModel.weatherIcon.drive(self.weatherIconImage.rx.image).addDisposableTo(self.bag)
        self.viewModel.greeting.drive(self.greetingLabel.rx.text).addDisposableTo(self.bag)
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
        viewModel.fetchAccountDetail(isRefresh: false)
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

