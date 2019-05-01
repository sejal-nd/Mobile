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
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    // Edit Payment TableView Header
    @IBOutlet weak var editPaymentHeaderView: UIView!
    @IBOutlet weak var currPaymentMethodView: UIView!
    @IBOutlet weak var currPaymentMethodLabel: UILabel!
    @IBOutlet weak var currPaymentMethodIconImageView: UIImageView!
    @IBOutlet weak var currPaymentMethodAccountNumberLabel: UILabel!
    @IBOutlet weak var currPaymentMethodDividerLineConstraint: NSLayoutConstraint!
    
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
        viewModel.shouldShowTableView.map(!).drive(tableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowTableView.map(!).drive(addPaymentAccountBottomBar.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorLabel.map(!).drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        currPaymentMethodLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        currPaymentMethodLabel.textColor = .deepGray
        currPaymentMethodLabel.text = NSLocalizedString("Current Payment Method", comment: "")
        currPaymentMethodAccountNumberLabel.font = SystemFont.medium.of(textStyle: .headline)
        currPaymentMethodAccountNumberLabel.textColor = .blackText
        if let editingItem = viewModel.editingItem.value {
            currPaymentMethodView.accessibilityLabel = editingItem.accessibilityDescription()
            currPaymentMethodIconImageView.image = editingItem.paymentMethodType.imageMini
            currPaymentMethodAccountNumberLabel.text = "**** \(editingItem.maskedWalletItemAccountNumber!)"
        } else {
            editPaymentHeaderView.isHidden = true
        }
        
        currPaymentMethodIconImageView.image = viewModel.editingItem.value?.paymentMethodType.imageMini
        
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
        
        // Dynamic sizing for the table header view
        if let headerView = tableView.tableHeaderView {
            if viewModel.editingItem.value != nil {
                let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                var headerFrame = headerView.frame
                
                // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
                if height != headerFrame.size.height {
                    headerFrame.size.height = height
                    headerView.frame = headerFrame
                }
            } else {
                headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.01) // Must be 0.01 to remove empty space when hidden
            }
            tableView.tableHeaderView = headerView
        }
        
        // Dynamic sizing for the table footer view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var footerFrame = footerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != footerFrame.size.height {
                footerFrame.size.height = height
                footerView.frame = footerFrame
                tableView.tableFooterView = footerView
            }
        }
    }
    
    override func updateViewConstraints() {
        currPaymentMethodDividerLineConstraint.constant = 1.0 / UIScreen.main.scale
        super.updateViewConstraints()
    }
    
    // MARK: - Helper
    
    private func addAccessibility() {
        miniBankButton.isAccessibilityElement = true
        miniBankButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        
        miniCreditCardButton.isAccessibilityElement = true
        miniCreditCardButton.accessibilityLabel = NSLocalizedString("Add credit card", comment: "")
        
        addPaymentAccountBottomBar.accessibilityElements = [addPaymentAccountLabel, miniBankButton, miniCreditCardButton] as [UIView]
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
        guard let walletItems = viewModel.walletItems.value else { return }
        
        let paymentusVC = PaymentusFormViewController(bankOrCard: bankOrCard,
                                                      temporary: temporary,
                                                      isWalletEmpty: walletItems.isEmpty)
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
        switch item.bankOrCard {
        case .bank:
            cell.innerContentView.isEnabled = !bankAccountsDisabled
        case .card:
            cell.innerContentView.isEnabled = !creditCardsDisabled && !item.isExpired
        }
        
        return cell
    }
}
