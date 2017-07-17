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
    
    @IBOutlet weak var primaryColorView: UIView!
    @IBOutlet weak var oneTouchSlider: OneTouchSlider!
    
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
    
    let viewModel = HomeViewModel(accountService: ServiceFactory.createAccountService())
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        oneTouchSlider.delegate = self
        
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
        
        primaryColorView.backgroundColor = .primaryColor
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
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
//        viewModel.fetchAccountDetail(isRefresh: false)
    }
    
}

extension HomeViewController: oneTouchSliderDelegate {
    
    func didFinishSwipe(_ oneTouchSlider: OneTouchSlider) {
        dLog(message: "Finished swipe")
    }
    
    func didCancelSwipe(_ oneTouchSlider: OneTouchSlider) {
        dLog(message: "Canceled swipe")
    }
    
    func sliderValueChanged(_ oneTouchSlider: OneTouchSlider) {
        //here if we need it
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

