//
//  MiniWalletViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol MiniWalletViewControllerDelegate: class {
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem)
}

class MiniWalletViewController: UIViewController {
    
    weak var delegate: MiniWalletViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeaderLabel: UILabel!
    @IBOutlet weak var tableFooterLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    let viewModel = MiniWalletViewModel(walletService: ServiceFactory.createWalletService())
    
    // These should be passed by whatever VC is presenting MiniWalletViewController
    var sentFromPayment = false
    var bankAccountsDisabled = false
    var creditCardsDisabled = false
    var tableHeaderLabelText: String?
    var accountDetail: AccountDetail!
    // --------- //
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Select Payment Method", comment: "")
        
        tableView.rx.contentOffset.asDriver()
            .map { $0.y <= 0 ? .white: .softGray }
            .distinctUntilChanged()
            .drive(tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
        
        tableHeaderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        tableHeaderLabel.textColor = .blackText
        tableHeaderLabel.text = tableHeaderLabelText
        
        tableFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        tableFooterLabel.textColor = .blackText
        tableFooterLabel.text = viewModel.footerLabelText
        
        tableView.estimatedSectionHeaderHeight = 16
        tableView.estimatedRowHeight = 74 // Required for iOS 9
        
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the table header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
        
        // Dynamic sizing for the table footer view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var footerFrame = footerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != footerFrame.size.height {
                var gap: CGFloat = 0
                let contentHeightWithoutFooter = tableView.contentSize.height - footerFrame.size.height
                if contentHeightWithoutFooter < view.frame.size.height {
                    gap = view.frame.size.height - contentHeightWithoutFooter // Gap between the table's content height and the bottom of the screen
                }
                
                if gap > height {
                    footerFrame.size.height = gap
                } else {
                    footerFrame.size.height = height
                }

                footerView.frame = footerFrame
                tableView.tableFooterView = footerView
            }
        }
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
        let walletItem = viewModel.bankAccounts[sender.tag]
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
        let walletItem = viewModel.creditCards[sender.tag]
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


extension MiniWalletViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return viewModel.bankAccounts.count + 1
        } else {
            return viewModel.creditCards.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 23
    }
    
}

extension MiniWalletViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SectionHeaderCell") as! MiniWalletSectionHeaderCell
        
        if section == 0 {
            cell.label.text = NSLocalizedString("Bank Accounts", comment: "")
            if bankAccountsDisabled {
                cell.label.alpha = 0.33
                cell.accessibilityElementsHidden = true
            } else {
                cell.label.alpha = 1
                cell.accessibilityElementsHidden = false
            }
        } else {
            cell.label.text = NSLocalizedString("Credit/Debit Cards", comment: "")
            if creditCardsDisabled {
                cell.label.alpha = 0.33
                cell.accessibilityElementsHidden = true
            } else {
                cell.label.alpha = 1
                cell.accessibilityElementsHidden = false
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row < viewModel.bankAccounts.count {
                let bankItem = viewModel.bankAccounts[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "MiniWalletItemCell", for: indexPath) as! MiniWalletTableViewCell
                cell.bindToWalletItem(bankItem, isSelectedItem: bankItem == viewModel.selectedItem.value)
                cell.innerContentView.tag = indexPath.row
                cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
                cell.innerContentView.addTarget(self, action: #selector(onBankAccountPress(sender:)), for: .touchUpInside)
                cell.innerContentView.isEnabled = !bankAccountsDisabled
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddAccountCell", for: indexPath) as! MiniWalletAddAccountCell
                cell.iconImageView.image = #imageLiteral(resourceName: "bank_building_mini")
                cell.label.text = NSLocalizedString("Add Bank Account", comment: "")
                cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
                cell.innerContentView.addTarget(self, action: #selector(onAddBankAccountPress), for: .touchUpInside)
                cell.innerContentView.accessibilityLabel = NSLocalizedString("Add Bank Account", comment: "")
                cell.innerContentView.isEnabled = !bankAccountsDisabled
                return cell
            }
        } else {
            if indexPath.row < viewModel.creditCards.count {
                let cardItem = viewModel.creditCards[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "MiniWalletItemCell", for: indexPath) as! MiniWalletTableViewCell
                cell.bindToWalletItem(cardItem, isSelectedItem: cardItem == viewModel.selectedItem.value)
                cell.innerContentView.tag = indexPath.row
                cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
                cell.innerContentView.addTarget(self, action: #selector(onCreditCardPress(sender:)), for: .touchUpInside)
                
                cell.innerContentView.isEnabled = true
                if cardItem.paymentMethodType == .visa, sentFromPayment, !accountDetail.isResidential, Environment.shared.opco == .bge {
                    // BGE Commercial cannot pay with VISA
                    cell.innerContentView.isEnabled = false
                }
                if creditCardsDisabled || cardItem.isExpired {
                    cell.innerContentView.isEnabled = false
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddAccountCell", for: indexPath) as! MiniWalletAddAccountCell
                cell.iconImageView.image = #imageLiteral(resourceName: "credit_card_mini")
                cell.label.text = NSLocalizedString("Add Credit/Debit Card", comment: "")
                cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
                cell.innerContentView.addTarget(self, action: #selector(onAddCreditCardPress), for: .touchUpInside)
                cell.innerContentView.accessibilityLabel = NSLocalizedString("Add Credit/Debit Card", comment: "")
                cell.innerContentView.isEnabled = !creditCardsDisabled
                return cell
            }
        }
    }
    
    
}
