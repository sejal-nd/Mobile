//
//  MiniWalletViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol MiniWalletViewControllerDelegate: class {
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem)
}

class MiniWalletViewController: UIViewController {
    
    weak var delegate: MiniWalletViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableFooterLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    // Bottom Bar
    @IBOutlet weak var addPaymentAccountBottomBar: UIView!
    @IBOutlet weak var addPaymentAccountLabel: UILabel!
    @IBOutlet weak var miniBankButton: ButtonControl!
    @IBOutlet weak var miniCreditCardButton: ButtonControl!
    
    let viewModel = MiniWalletViewModel(walletService: ServiceFactory.createWalletService())
    
    // These should be passed by whatever VC is presenting MiniWalletViewController
    var sentFromPayment = false
    var bankAccountsDisabled = false
    var creditCardsDisabled = false
    var tableHeaderLabelText: String?
    var accountDetail: AccountDetail!
    // --------- //
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Select Payment Method", comment: "")

        tableFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        tableFooterLabel.textColor = .blackText
        tableFooterLabel.text = viewModel.footerLabelText
        
        addPaymentAccountBottomBar.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        addPaymentAccountLabel.textColor = .deepGray
        addPaymentAccountLabel.text = NSLocalizedString("Add Payment Method", comment: "")
        addPaymentAccountLabel.font = SystemFont.regular.of(textStyle: .headline)
        miniCreditCardButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniCreditCardButton.layer.cornerRadius = 8
        miniBankButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniBankButton.layer.cornerRadius = 8
        viewModel.isFetchingWalletItems.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowTableView.map(!).drive(tableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorLabel.map(!).drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        if accountDetail.isCashOnly {
            bankAccountsDisabled = true
        }
        
        if viewModel.walletItems.value == nil { // Wallet items are passed in from MakePaymentViewController - so only fetch if necessary
            fetchWalletItems()
        }
        
        setupButtonTaps()
        
        addAccessibility()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeFooterToFit()
    }
    
    
    // MARK: - Helper
    
    func addAccessibility() {
        miniBankButton.isAccessibilityElement = true
        miniBankButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        
        miniCreditCardButton.isAccessibilityElement = true
        miniCreditCardButton.accessibilityLabel = NSLocalizedString("Add credit card", comment: "")
        
        addPaymentAccountBottomBar.accessibilityElements = [addPaymentAccountLabel, miniBankButton, miniCreditCardButton]
    }
    
    func setupButtonTaps() {
        Driver.merge(miniBankButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.onAddBankAccountPress()
            }).disposed(by: disposeBag)
        
        Driver.merge(miniCreditCardButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.onAddCreditCardPress()
            }).disposed(by: disposeBag)
    }
    
    func fetchWalletItems() {
        viewModel.fetchWalletItems(onSuccess: { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.view.setNeedsLayout()
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }, onError: { [weak self] in
                guard let self = self else { return }
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
        })
    }
    
    @objc func onBankAccountPress(sender: ButtonControl) {
        guard let walletItem = viewModel.walletItems.value?[sender.tag] else { return }
        delegate?.miniWalletViewController(self, didSelectWalletItem: walletItem)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onAddBankAccountPress() {
        let actionSheet = UIAlertController.saveToWalletActionSheet(bankOrCard: .bank, saveHandler: { [weak self] _ in
            guard let self = self else { return }
            let paymentusVC = PaymentusFormViewController(bankOrCard: .bank, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
            paymentusVC.delegate = self.delegate as? PaymentusFormViewControllerDelegate
            paymentusVC.shouldPopToMakePaymentOnSave = self.sentFromPayment
            self.navigationController?.pushViewController(paymentusVC, animated: true)
            }, dontSaveHandler: { [weak self] _ in
                guard let self = self else { return }
                let paymentusVC = PaymentusFormViewController(bankOrCard: .bank, temporary: true)
                paymentusVC.delegate = self.delegate as? PaymentusFormViewControllerDelegate
                paymentusVC.shouldPopToMakePaymentOnSave = self.sentFromPayment
                self.navigationController?.pushViewController(paymentusVC, animated: true)
        })
        present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func onCreditCardPress(sender: ButtonControl) {
        guard let walletItem = viewModel.walletItems.value?[sender.tag] else { return }
        delegate?.miniWalletViewController(self, didSelectWalletItem: walletItem)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onAddCreditCardPress() {
        let actionSheet = UIAlertController.saveToWalletActionSheet(bankOrCard: .card, saveHandler: { [weak self] _ in
            guard let self = self else { return }
            let paymentusVC = PaymentusFormViewController(bankOrCard: .card, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
            paymentusVC.delegate = self.delegate as? PaymentusFormViewControllerDelegate
            paymentusVC.shouldPopToMakePaymentOnSave = self.sentFromPayment
            self.navigationController?.pushViewController(paymentusVC, animated: true)
            }, dontSaveHandler: { [weak self] _ in
                guard let self = self else { return }
                let paymentusVC = PaymentusFormViewController(bankOrCard: .card, temporary: true)
                paymentusVC.delegate = self.delegate as? PaymentusFormViewControllerDelegate
                paymentusVC.shouldPopToMakePaymentOnSave = self.sentFromPayment
                self.navigationController?.pushViewController(paymentusVC, animated: true)
        })
        present(actionSheet, animated: true, completion: nil)
    }
    
}


// MARK: - Table View Delegate

extension MiniWalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let walletItems = viewModel.walletItems.value else { return 0 }
        return walletItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 32
    }
}


// MARK: - Table View Data Source

extension MiniWalletViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MiniWalletItemCell", for: indexPath) as? MiniWalletTableViewCell else {
            fatalError("Invalid Table View Cell.")
        }
        guard let item = viewModel.walletItems.value?[indexPath.row] else {
            return UITableViewCell()
        }
        switch item.bankOrCard {
        case .bank:
            cell.bindToWalletItem(item, isSelectedItem: item == viewModel.selectedItem.value)
            cell.innerContentView.tag = indexPath.row
            cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.innerContentView.addTarget(self, action: #selector(onBankAccountPress(sender:)), for: .touchUpInside)
            cell.innerContentView.isEnabled = !bankAccountsDisabled
        case .card:
            cell.bindToWalletItem(item, isSelectedItem: item == viewModel.selectedItem.value)
            cell.innerContentView.tag = indexPath.row
            cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.innerContentView.addTarget(self, action: #selector(onCreditCardPress(sender:)), for: .touchUpInside)
            
            cell.innerContentView.isEnabled = true
            if creditCardsDisabled || item.isExpired {
                cell.innerContentView.isEnabled = false
            }
        }
        
        return cell
    }
}
