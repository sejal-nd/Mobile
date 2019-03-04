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
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    // Bottom Bar
    @IBOutlet weak var addPaymentAccountBottomBar: UIView!
    @IBOutlet weak var addPaymentAccountLabel: UILabel!
    @IBOutlet weak var miniBankButton: ButtonControl!
    @IBOutlet weak var miniCreditCardButton: ButtonControl!
    
    let viewModel = MiniWalletViewModel(walletService: ServiceFactory.createWalletService())
    
    // These should be passed by whatever VC is presenting MiniWalletViewController
    weak var popToViewController: UIViewController? // Pop to this view controller on new item save
    var pushBankOnEmpty = false
    var bankAccountsDisabled = false
    var creditCardsDisabled = false
    var allowTemporaryItems = true
    var tableHeaderLabelText: String?
    var accountDetail: AccountDetail!
    // --------- //
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Select Payment Method", comment: "")

        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        footerLabel.textColor = .blackText
        footerLabel.text = viewModel.footerLabelText
        
        addPaymentAccountBottomBar.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        addPaymentAccountLabel.textColor = .deepGray
        addPaymentAccountLabel.text = NSLocalizedString("Add Payment Method", comment: "")
        addPaymentAccountLabel.font = SystemFont.regular.of(textStyle: .headline)
        miniCreditCardButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniCreditCardButton.layer.cornerRadius = 8
        miniCreditCardButton.isEnabled = !creditCardsDisabled
        miniBankButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniBankButton.layer.cornerRadius = 8
        miniBankButton.isEnabled = !bankAccountsDisabled
        viewModel.isFetchingWalletItems.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowTableView.map(!).drive(mainStackView.rx.isHidden).disposed(by: disposeBag)
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
    
    // MARK: - Helper
    
    private func addAccessibility() {
        miniBankButton.isAccessibilityElement = true
        miniBankButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        
        miniCreditCardButton.isAccessibilityElement = true
        miniCreditCardButton.accessibilityLabel = NSLocalizedString("Add credit card", comment: "")
        
        addPaymentAccountBottomBar.accessibilityElements = [addPaymentAccountLabel, miniBankButton, miniCreditCardButton]
    }
    
    private func setupButtonTaps() {
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
    
    private func fetchWalletItems() {
        viewModel.fetchWalletItems(onSuccess: { [weak self] in
            guard let self = self else { return }
            
            if self.pushBankOnEmpty && self.viewModel.walletItems.value?.isEmpty ?? true {
                let paymentusVC = PaymentusFormViewController(bankOrCard: .bank,
                                                              temporary: false,
                                                              isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
                paymentusVC.delegate = self.delegate as? PaymentusFormViewControllerDelegate
                paymentusVC.popToViewController = self.popToViewController
                self.navigationController?.viewControllers = Array(self.navigationController!.viewControllers.dropLast()) + [paymentusVC]
            } else {
                self.tableView.reloadData()
            }
            
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }, onError: { [weak self] in
                guard let self = self else { return }
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
        })
    }
    
    private func presentPaymentusForm(bankOrCard: BankOrCard, temporary: Bool) {
        let paymentusVC = PaymentusFormViewController(bankOrCard: bankOrCard,
                                                      temporary: temporary,
                                                      isWalletEmpty: viewModel.walletItems.value!.isEmpty)
        paymentusVC.delegate = delegate as? PaymentusFormViewControllerDelegate
        paymentusVC.popToViewController = popToViewController
        navigationController?.pushViewController(paymentusVC, animated: true)
    }
    
    
    // MARK: - Actions
    
    @objc private func onWalletItemCellPress(sender: ButtonControl) {
        let walletItem = viewModel.tableViewWalletItems[sender.tag]
        delegate?.miniWalletViewController(self, didSelectWalletItem: walletItem)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func onAddBankAccountPress() {
        if allowTemporaryItems {
            let actionSheet = UIAlertController
                .saveToWalletActionSheet(bankOrCard: .bank, saveHandler: { [weak self] _ in
                    self?.presentPaymentusForm(bankOrCard: .bank, temporary: false)
                    }, dontSaveHandler: { [weak self] _ in
                        self?.presentPaymentusForm(bankOrCard: .bank, temporary: true)
                })
            
            present(actionSheet, animated: true, completion: nil)
        } else {
            presentPaymentusForm(bankOrCard: .bank, temporary: false)
        }
        
    }
    
    @objc private func onAddCreditCardPress() {
        let actionSheet = UIAlertController
            .saveToWalletActionSheet(bankOrCard: .card, saveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .card, temporary: false)
                }, dontSaveHandler: { [weak self] _ in
                    self?.presentPaymentusForm(bankOrCard: .card, temporary: true)
            })
        present(actionSheet, animated: true, completion: nil)
    }
    
}


// MARK: - Table View Delegate

extension MiniWalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tableViewWalletItems.count
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
        let item = viewModel.tableViewWalletItems[indexPath.row]
        
        cell.bindToWalletItem(item, isSelectedItem: item == viewModel.selectedItem.value)
        cell.innerContentView.tag = indexPath.row
        cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
        cell.innerContentView.addTarget(self, action: #selector(onWalletItemCellPress(sender:)), for: .touchUpInside)
        cell.innerContentView.isEnabled = true
        if item.bankOrCard == .bank && bankAccountsDisabled {
            cell.innerContentView.isEnabled = false
        } else {
            if creditCardsDisabled || item.isExpired {
                cell.innerContentView.isEnabled = false
            }
        }
        
        return cell
    }
}
