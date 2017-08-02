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
    
    // Used in the payment workflow:
    func miniWalletViewControllerDidTapAddBank(_ miniWalletViewController: MiniWalletViewController)
    func miniWalletViewControllerDidTapAddCard(_ miniWalletViewController: MiniWalletViewController)
}

// Default implementation to make these protocol functions optional
extension MiniWalletViewControllerDelegate {
    func miniWalletViewControllerDidTapAddBank(_ miniWalletViewController: MiniWalletViewController) { }
    func miniWalletViewControllerDidTapAddCard(_ miniWalletViewController: MiniWalletViewController) { }
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

        title = NSLocalizedString("Select Payment Account", comment: "")
        
        tableView.rx.contentOffset.asDriver()
            .map { $0.y <= 0 ? .white: .softGray }
            .distinctUntilChanged()
            .drive(onNext: { self.tableView.backgroundColor = $0 })
            .addDisposableTo(disposeBag)
        
        tableHeaderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        tableHeaderLabel.textColor = .blackText
        tableHeaderLabel.text = tableHeaderLabelText
        
        tableFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        tableFooterLabel.textColor = .blackText
        tableFooterLabel.text = viewModel.footerLabelText
        
        tableView.estimatedSectionHeaderHeight = 16
        
        viewModel.isFetchingWalletItems.asDriver().map(!).drive(loadingIndicator.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowTableView.map(!).drive(tableView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowErrorLabel.map(!).drive(errorLabel.rx.isHidden).addDisposableTo(disposeBag)
        
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
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
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
            let height = footerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let oneTouchPayItem = viewModel.walletItems.value?.first(where: { $0.isDefault == true })
        
        if let vc = segue.destination as? AddBankAccountViewController {
            vc.accountDetail = accountDetail
            vc.oneTouchPayItem = oneTouchPayItem
            if let walletItems = viewModel.walletItems.value {
                vc.nicknamesInWallet = walletItems.map { $0.nickName ?? "" }.filter { !$0.isEmpty }
            }
            vc.delegate = self
        } else if let vc = segue.destination as? AddCreditCardViewController {
            vc.accountDetail = accountDetail
            vc.oneTouchPayItem = oneTouchPayItem
            if let walletItems = viewModel.walletItems.value {
                vc.nicknamesInWallet = walletItems.map { $0.nickName ?? "" }.filter { !$0.isEmpty }
            }
            vc.delegate = self
        }
    }
    
    func fetchWalletItems() {
        viewModel.fetchWalletItems(onSuccess: {
            self.tableView.reloadData()
            self.view.setNeedsLayout()
        }, onError: { errMessage in
            self.errorLabel.text = errMessage
        })
    }
    
    func onBankAccountPress(sender: ButtonControl) {
        let walletItem = viewModel.bankAccounts[sender.tag]
        delegate?.miniWalletViewController(self, didSelectWalletItem: walletItem)
        navigationController?.popViewController(animated: true)
    }
    
    func onAddBankAccountPress() {
        if sentFromPayment {
            delegate?.miniWalletViewControllerDidTapAddBank(self)
            navigationController?.popViewController(animated: true)
        } else {
            performSegue(withIdentifier: "miniWalletAddBankAccountSegue", sender: self)
        }
    }
    
    func onCreditCardPress(sender: ButtonControl) {
        let walletItem = viewModel.creditCards[sender.tag]
        delegate?.miniWalletViewController(self, didSelectWalletItem: walletItem)
        navigationController?.popViewController(animated: true)
    }
    
    func onAddCreditCardPress() {
        if sentFromPayment {
            delegate?.miniWalletViewControllerDidTapAddCard(self)
            navigationController?.popViewController(animated: true)
        } else {
            performSegue(withIdentifier: "miniWalletAddCreditCardSegue", sender: self)
        }
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
        return UITableViewAutomaticDimension
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SectionHeaderCell") as! MiniWalletSectionHeaderCell
        
        if section == 0 {
            cell.label.text = NSLocalizedString("No convenience fee will be applied.", comment: "")
            if bankAccountsDisabled {
                cell.label.alpha = 0.33
                cell.label.isAccessibilityElement = false
            } else {
                cell.label.alpha = 1
                cell.label.isAccessibilityElement = true
            }
        } else {
            var creditCardFeeString: String {
                switch Environment.sharedInstance.opco {
                case .bge:
                    return NSLocalizedString(accountDetail.billingInfo.convenienceFeeString(isComplete: true), comment: "")
                case .comEd, .peco:
                    let feeString = "A " + accountDetail.billingInfo.convenienceFee!.currencyString! + " convenience fee will be applied by Bill Matrix, our payment partner."
                    return NSLocalizedString(feeString, comment: "")
                }
            }
            cell.label.text = creditCardFeeString
            if creditCardsDisabled {
                cell.label.alpha = 0.33
                cell.label.isAccessibilityElement = false
            } else {
                cell.label.alpha = 1
                cell.label.isAccessibilityElement = true
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
                cell.innerContentView.isEnabled = !self.bankAccountsDisabled
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddAccountCell", for: indexPath) as! MiniWalletAddAccountCell
                cell.iconImageView.image = #imageLiteral(resourceName: "bank_building_mini")
                cell.label.text = NSLocalizedString("Add Bank Account", comment: "")
                viewModel.bankAccountLimitReached.map {
                    if self.bankAccountsDisabled {
                        return false
                    }
                    return !$0
                }.drive(cell.innerContentView.rx.isEnabled).addDisposableTo(disposeBag)
                cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
                cell.innerContentView.addTarget(self, action: #selector(onAddBankAccountPress), for: .touchUpInside)
                cell.innerContentView.accessibilityLabel = NSLocalizedString("Add Bank Account", comment: "")
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
                if let cardIssuer = cardItem.cardIssuer, cardIssuer == "Visa", sentFromPayment, !accountDetail.isResidential, Environment.sharedInstance.opco == .bge { // BGE Commercial cannot pay with VISA
                    cell.innerContentView.isEnabled = false
                }
                if creditCardsDisabled {
                    cell.innerContentView.isEnabled = false
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddAccountCell", for: indexPath) as! MiniWalletAddAccountCell
                cell.iconImageView.image = #imageLiteral(resourceName: "credit_card_mini")
                cell.label.text = NSLocalizedString("Add Credit/Debit Card", comment: "")
                viewModel.creditCardLimitReached.map {
                    if self.creditCardsDisabled {
                        return false
                    }
                    return !$0
                }.drive(cell.innerContentView.rx.isEnabled).addDisposableTo(disposeBag)
                cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
                cell.innerContentView.addTarget(self, action: #selector(onAddCreditCardPress), for: .touchUpInside)
                cell.innerContentView.accessibilityLabel = NSLocalizedString("Add Credit/Debit Card", comment: "")
                return cell
            }
        }
    }
    
    
}

extension MiniWalletViewController: AddBankAccountViewControllerDelegate {
    
    func addBankAccountViewControllerDidAddAccount(_ addBankAccountViewController: AddBankAccountViewController) {
        fetchWalletItems()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Bank account added", comment: ""))
        })
    }
    
}

extension MiniWalletViewController: AddCreditCardViewControllerDelegate {
    
    func addCreditCardViewControllerDidAddAccount(_ addCreditCardViewController: AddCreditCardViewController) {
        fetchWalletItems()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Card added", comment: ""))
        })
    }
}


