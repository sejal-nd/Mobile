//
//  WalletViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

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
        choosePaymentAccountLabel.text = NSLocalizedString("Choose a payment account:", comment: "")
        
        bankButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        bankButton.layer.cornerRadius = 10
        bankButtonLabel.textColor = .blackText
        bankButtonLabel.text = NSLocalizedString("Bank Account", comment: "")
        bankFeeLabel.textColor = .deepGray
        bankFeeLabel.text = NSLocalizedString("No fees applied to your payments.", comment: "")
        
        creditCardButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        creditCardButton.layer.cornerRadius = 10
        creditCardButtonLabel.textColor = .blackText
        creditCardButtonLabel.text = NSLocalizedString("Credit/Debit Card", comment: "")
        creditCardFeeLabel.textColor = .deepGray
        creditCardFeeLabel.text = NSLocalizedString("A $2.35 convenience fee will be applied\nto your payments.", comment: "")
        
        emptyStateFooter.textColor = .blackText
        emptyStateFooter.text = viewModel.footerLabelText
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
        
        viewModel.fetchWalletItems.onNext() // Fetch the items!
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
        
        switch indexPath.section {
        case 0:
            cell.accountImageView.image = #imageLiteral(resourceName: "ic_bofa")
            cell.bottomBarLabel.text = "No Fee Applied"
            cell.oneTouchPayView.isHidden = false
        case 1:
            cell.accountImageView.image = #imageLiteral(resourceName: "ic_visa")
            cell.bottomBarLabel.text = "$2.35 Convenience Fee"
            cell.oneTouchPayView.isHidden = true
        case 2:
            cell.accountImageView.image = #imageLiteral(resourceName: "ic_mastercard")
            cell.bottomBarLabel.text = "$2.35 Convenience Fee"
            cell.oneTouchPayView.isHidden = true
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row \(indexPath.section)")
    }
    
}
