//
//  StormModeBillViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 9/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class StormModeBillViewController: AccountPickerViewController {
    
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var buttonStack: UIStackView!
    @IBOutlet private weak var makeAPaymentButton: DisclosureButton!
    @IBOutlet private weak var paymentActivityButton: DisclosureButton!
    @IBOutlet private weak var myWalletButton: DisclosureButton!
    
    override var showMinimizedPicker: Bool { return false }
    
    var refreshControl: UIRefreshControl?
    
    let disposeBag = DisposeBag()
    
    let viewModel = StormModeBillViewModel(accountService: ServiceFactory.createAccountService(),
                                           walletService: ServiceFactory.createWalletService(),
                                           paymentService: ServiceFactory.createPaymentService(),
                                           authService: ServiceFactory.createAuthenticationService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        accountPickerViewControllerWillAppear
            .withLatestFrom(viewModel.accountDetailEvents.map { $0 }.startWith(nil)) { ($0, $1) }
            .subscribe(onNext: { [weak self] state, accountDetailEvent in
                guard let this = self else { return }
                switch(state) {
                case .loadingAccounts:
                    this.setRefreshControlEnabled(enabled: false)
                case .readyToFetchData:
                    this.setRefreshControlEnabled(enabled: true)
                    if AccountsStore.shared.currentAccount != this.accountPicker.currentAccount {
                        this.viewModel.fetchData.onNext(.switchAccount)
                    } else if accountDetailEvent?.element == nil {
                        this.viewModel.fetchData.onNext(.switchAccount)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        let billCard = HomeBillCardView.create(withViewModel: viewModel.billCardViewModel)
        contentStack.insertArrangedSubview(billCard, at: 0)
        
        bindActions()
        bindViewStates()
        
        NotificationCenter.default.rx.notification(.didMaintenanceModeTurnOn)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in self?.killRefresh() })
            .disposed(by: disposeBag)
        
        viewModel.fetchData.onNext(.switchAccount)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setColoredNavBar()
    }
    
    @objc func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            scrollView!.alwaysBounceVertical = true
            
            guard refreshControl == nil else { return }
            
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
//            refreshControl?.tintColor = .white
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
    
    func killRefresh() -> Void {
        refreshControl?.endRefreshing()
        scrollView!.alwaysBounceVertical = false
    }
    
    func bindViewStates() {
        viewModel.didFinishRefresh
            .drive(onNext: { [weak self] in self?.refreshControl?.endRefreshing() })
            .disposed(by: disposeBag)
        
        viewModel.showButtonStack.not().drive(buttonStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMakeAPaymentButton.not().drive(makeAPaymentButton.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindActions() {
        paymentActivityButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.accountDetailEvents.elements()
                .asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "PaymentActivitySegue", sender: $0)
            })
            .disposed(by: disposeBag)
        
        makeAPaymentButton.rx.touchUpInside.asObservable()
            .withLatestFrom(viewModel.makePaymentScheduledPaymentAlertInfo)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] alertInfo in
                guard let this = self else { return }
                
                let (titleOpt, messageOpt, accountDetail) = alertInfo
                let goToMakePayment = { [weak self] in
                    guard let this = self else { return }
                    let paymentVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "makeAPayment") as! MakePaymentViewController
                    paymentVc.accountDetail = accountDetail
                    this.navigationController?.pushViewController(paymentVc, animated: true)
                }
                
                if let title = titleOpt, let message = messageOpt {
                    let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { _ in
                        goToMakePayment()
                    }))
                    this.present(alertVc, animated: true, completion: nil)
                } else {
                    goToMakePayment()
                }
            })
            .disposed(by: disposeBag)
        
        myWalletButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.accountDetailEvents.elements()
                .asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "WalletSegue", sender: $0)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case let (vc as BillingHistoryViewController, accountDetail as AccountDetail):
            vc.accountDetail = accountDetail
        case let (vc as WalletViewController, accountDetail as AccountDetail):
            vc.viewModel.accountDetail = accountDetail
        default:
            break
        }
    }

}

extension StormModeBillViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchData.onNext(.switchAccount)
    }
}
