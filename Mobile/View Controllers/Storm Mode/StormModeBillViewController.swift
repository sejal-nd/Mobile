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
    
    let disposeBag = DisposeBag()
    
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var buttonStack: UIStackView!
    @IBOutlet private weak var makeAPaymentButton: DisclosureButton!
    @IBOutlet private weak var paymentActivityButton: DisclosureButton!
    @IBOutlet private weak var myWalletButton: DisclosureButton!
    
    let viewModel = StormModeBillViewModel(accountService: ServiceFactory.createAccountService(),
                                           walletService: ServiceFactory.createWalletService(),
                                           paymentService: ServiceFactory.createPaymentService(),
                                           authService: ServiceFactory.createAuthenticationService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        let billCard = HomeBillCardView.create(withViewModel: viewModel.billCardViewModel)
        contentStack.insertArrangedSubview(billCard, at: 0)
        
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
        
        viewModel.showButtonStack.not().drive(buttonStack.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.fetchData.onNext(.switchAccount)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setColoredNavBar()
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
