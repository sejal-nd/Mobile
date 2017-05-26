//
//  WalletViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class WalletViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    // Empty state stuff
    @IBOutlet weak var emptyStateScrollView: UIScrollView!
    @IBOutlet weak var choosePaymentAccountLabel: UILabel!
    @IBOutlet weak var bankButton: ButtonControl!
    @IBOutlet weak var bankButtonLabel: UILabel!
    @IBOutlet weak var bankFeeLabel: UILabel!
    @IBOutlet weak var creditCardButton: ButtonControl!
    @IBOutlet weak var creditCardButtonLabel: UILabel!
    @IBOutlet weak var creditCardFeeLabel: UILabel!
    @IBOutlet weak var emptyStateFooter: UILabel!
    
    // Non-empty state stuff
    @IBOutlet weak var nonEmptyStateView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addPaymentAccountBottomBar: UIView!
    @IBOutlet weak var addPaymentAccountLabel: UILabel!
    @IBOutlet weak var miniCreditCardButton: ButtonControl!
    @IBOutlet weak var miniBankButton: ButtonControl!
    @IBOutlet weak var tableViewFooter: UILabel!
    
    let viewModel = WalletViewModel(walletService: ServiceFactory.createWalletService())

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("My Wallet", comment: "")
        view.backgroundColor = .softGray
        
        // Empty state stuff
        choosePaymentAccountLabel.textColor = .blackText
        choosePaymentAccountLabel.font = OpenSans.regular.of(textStyle: .headline)
        choosePaymentAccountLabel.text = NSLocalizedString("Choose a payment account:", comment: "")
        
        bankButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        bankButton.layer.cornerRadius = 10
        bankButtonLabel.textColor = .blackText
        bankButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        bankButtonLabel.text = NSLocalizedString("Bank Account", comment: "")
        bankFeeLabel.textColor = .deepGray
        bankFeeLabel.text = NSLocalizedString("No fees applied to your payments.", comment: "")
        bankFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        creditCardButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        creditCardButton.layer.cornerRadius = 10
        creditCardButtonLabel.textColor = .blackText
        creditCardButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        creditCardButtonLabel.text = NSLocalizedString("Credit/Debit Card", comment: "")
        creditCardFeeLabel.textColor = .deepGray
        creditCardFeeLabel.text = viewModel.emptyStateCreditFeeLabelText
        creditCardFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        emptyStateFooter.textColor = .blackText
        emptyStateFooter.text = viewModel.footerLabelText
        emptyStateFooter.font = SystemFont.regular.of(textStyle: .footnote)
        
        // Non-empty state stuff
        tableView.backgroundColor = .primaryColor
        tableView.contentInset = UIEdgeInsetsMake(15, 0, 15, 0)
        tableView.indicatorStyle = .white
        
        addPaymentAccountBottomBar.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        addPaymentAccountLabel.textColor = .deepGray
        addPaymentAccountLabel.text = NSLocalizedString("Add Payment Account", comment: "")
        miniCreditCardButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniCreditCardButton.layer.cornerRadius = 8
        miniBankButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniBankButton.layer.cornerRadius = 8
        
        tableViewFooter.text = viewModel.footerLabelText
        
        emptyStateScrollView.isHidden = true
        nonEmptyStateView.isHidden = true
        
        setupBinding()
        setupButtonTaps()
        
        viewModel.fetchWalletItems.onNext() // Fetch the items!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the table footer view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var footerFrame = footerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != footerFrame.size.height {
                footerFrame.size.height = height
                footerView.frame = footerFrame
                tableView.tableFooterView = footerView
            }
        }
    }
    
    func setupBinding() {
        viewModel.isFetchingWalletItems.map(!).drive(loadingIndicator.rx.isHidden).addDisposableTo(disposeBag)
        
        viewModel.shouldShowEmptyState.map(!).drive(emptyStateScrollView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowWallet.map(!).drive(nonEmptyStateView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowWallet.drive(onNext: { shouldShow in
            if shouldShow {
                self.tableView.reloadData()
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.creditCardLimitReached.map(!).drive(miniCreditCardButton.rx.isEnabled).addDisposableTo(disposeBag)
        viewModel.bankAccountLimitReached.map(!).drive(miniBankButton.rx.isEnabled).addDisposableTo(disposeBag)
    }
    
    func setupButtonTaps() {
        Driver.merge(bankButton.rx.touchUpInside.asDriver(), miniBankButton.rx.touchUpInside.asDriver()).drive(onNext: {
            self.performSegue(withIdentifier: "addBankAccountSegue", sender: self)
        }).addDisposableTo(disposeBag)
        
        Driver.merge(creditCardButton.rx.touchUpInside.asDriver(), miniCreditCardButton.rx.touchUpInside.asDriver()).drive(onNext: {
            self.performSegue(withIdentifier: "addCreditCardSegue", sender: self)
        }).addDisposableTo(disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AddBankAccountViewController {
            vc.delegate = self
        } else if let vc = segue.destination as? AddCreditCardViewController {
            vc.delegate = self
        }
    }

}

extension WalletViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let walletItems = viewModel.walletItems.value {
            return walletItems.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.walletItems.value != nil {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 14
    }
    
}

extension WalletViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WalletCell", for: indexPath) as! WalletTableViewCell
        
        let walletItem = viewModel.walletItems.value![indexPath.section]
        cell.bindToWalletItem(walletItem)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row \(indexPath.section)")
    }
    
}

extension WalletViewController: AddBankAccountViewControllerDelegate {
    
    func addBankAccountViewControllerDidAddAccount(_ addBankAccountViewController: AddBankAccountViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.viewModel.fetchWalletItems.onNext()
            self.view.makeToast(NSLocalizedString("Bank account added.", comment: ""), duration: 5.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
        })
    }
    
}

extension WalletViewController: AddCreditCardViewControllerDelegate {
    
    func addCreditCardViewControllerDidAddAccount(_ addCreditCardViewController: AddCreditCardViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.viewModel.fetchWalletItems.onNext()
            self.view.makeToast(NSLocalizedString("Card added.", comment: ""), duration: 5.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
        })
    }
}
