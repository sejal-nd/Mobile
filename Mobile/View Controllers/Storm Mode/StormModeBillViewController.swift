//
//  StormModeBillViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 9/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class StormModeBillViewController: AccountPickerViewController {
    
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var prepaidView: PrepaidCardView!
    @IBOutlet private weak var buttonStack: UIStackView!
    @IBOutlet private weak var makeAPaymentButton: DisclosureButton!
    @IBOutlet private weak var paymentActivityButton: DisclosureButton!
    @IBOutlet private weak var myWalletButton: DisclosureButton!
    @IBOutlet private weak var noNetworkConnectionView: NoNetworkConnectionView!
    
    var billCardView: HomeBillCardView!
    
    override var showMinimizedPicker: Bool { return false }
    
    var refreshControl: UIRefreshControl?
    
    let disposeBag = DisposeBag()
    
    let viewModel = StormModeBillViewModel(accountService: ServiceFactory.createAccountService(),
                                           walletService: ServiceFactory.createWalletService(),
                                           paymentService: ServiceFactory.createPaymentService(),
                                           authService: ServiceFactory.createAuthenticationService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .stormModeBlack
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        billCardView = HomeBillCardView.create(withViewModel: viewModel.billCardViewModel)
        contentStack.insertArrangedSubview(billCardView, at: 0)
        
        makeAPaymentButton.stormTheme = true
        makeAPaymentButton.accessibilityLabel = makeAPaymentButton.labelText
        paymentActivityButton.stormTheme = true
        paymentActivityButton.accessibilityLabel = paymentActivityButton.labelText
        myWalletButton.stormTheme = true
        myWalletButton.accessibilityLabel = myWalletButton.labelText
        
        bindActions()
        bindViewStates()
        bindBillCard()
        
        NotificationCenter.default.rx.notification(.didMaintenanceModeTurnOn)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.refreshControl?.endRefreshing()
                self?.scrollView!.alwaysBounceVertical = true
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }
    
    @objc func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            scrollView!.alwaysBounceVertical = true
            
            guard refreshControl == nil else { return }
            
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
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
    
    func bindViewStates() {
        viewModel.didFinishRefresh
            .drive(onNext: { [weak self] in self?.refreshControl?.endRefreshing() })
            .disposed(by: disposeBag)
        
        viewModel.isSwitchingAccounts
            .drive(onNext: { [weak self] in self?.setRefreshControlEnabled(enabled: !$0) })
            .disposed(by: disposeBag)
        
        viewModel.showBillCard.not().drive(billCardView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showButtonStack.not().drive(buttonStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showPrepaidCard.not().drive(prepaidView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMakeAPaymentButton.not().drive(makeAPaymentButton.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showNoNetworkConnectionView.not().drive(noNetworkConnectionView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showNoNetworkConnectionView.drive(scrollView!.rx.isHidden).disposed(by: disposeBag)
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
                    let paymentVc = UIStoryboard(name: "Payment", bundle: nil).instantiateInitialViewController() as! MakePaymentViewController
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
        
        Observable.merge(noNetworkConnectionView.reload)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.viewModel.fetchData.onNext(.switchAccount) })
            .disposed(by: disposeBag)
    }
    
    func bindBillCard() {
        guard let billCardView = billCardView else { return }
        
        billCardView.oneTouchPayFinished
            .map { FetchingAccountState.switchAccount }
            .bind(to: viewModel.fetchData)
            .disposed(by: billCardView.bag)
        
        billCardView.modalViewControllers
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            })
            .disposed(by: billCardView.bag)
        
        billCardView.pushedViewControllers
            .drive(onNext: { [weak self] viewController in
                guard let self = self else { return }
                
                if let vc = viewController as? WalletViewController {
                    vc.didUpdate
                        .asDriver(onErrorDriveWith: .empty())
                        .delay(0.5)
                        .drive(onNext: { [weak self] toastMessage in
                            self?.view.showToast(toastMessage)
                        })
                        .disposed(by: vc.disposeBag)
                }
                
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: billCardView.bag)
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
