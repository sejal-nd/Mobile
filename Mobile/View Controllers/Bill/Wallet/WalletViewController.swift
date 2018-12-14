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
    @IBOutlet weak var errorLabel: UILabel!
    
    // Empty state stuff
    @IBOutlet weak var emptyStateScrollView: UIScrollView!
    @IBOutlet weak var emptyStateCashOnlyLabel: UILabel!
    @IBOutlet weak var emptyStateCashOnlyTopConstraint: NSLayoutConstraint!
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
    @IBOutlet weak var cashOnlyTableHeaderLabel: UILabel!
    @IBOutlet weak var tableViewFooter: UILabel!
    
    let viewModel = WalletViewModel(walletService: ServiceFactory.createWalletService())
    
    var selectedWalletItem: WalletItem?
    var shouldPopToRootOnSave = false
    var shouldSetOneTouchPayByDefault = false
    
    fileprivate let didUpdateSubject = PublishSubject<String>()
    private(set) lazy var didUpdate: Observable<String> = self.didUpdateSubject.asObservable()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("My Wallet", comment: "")
        view.backgroundColor = .softGray
        
        // Empty state stuff
        choosePaymentAccountLabel.textColor = .blackText
        choosePaymentAccountLabel.font = OpenSans.regular.of(textStyle: .headline)
        choosePaymentAccountLabel.text = NSLocalizedString("Choose a payment method:", comment: "")
        
        bankButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        bankButton.layer.cornerRadius = 10
        bankButtonLabel.textColor = .blackText
        bankButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        bankButtonLabel.text = NSLocalizedString("Bank Account", comment: "")
        bankFeeLabel.textColor = .deepGray
        bankFeeLabel.text = NSLocalizedString("No fees applied to your payments.", comment: "")
        
        creditCardButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        creditCardButton.layer.cornerRadius = 10
        creditCardButtonLabel.textColor = .blackText
        creditCardButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        creditCardButtonLabel.text = NSLocalizedString("Credit/Debit Card", comment: "")
        creditCardFeeLabel.textColor = .deepGray
        creditCardFeeLabel.text = viewModel.emptyStateCreditFeeLabelText
        
        emptyStateFooter.textColor = .blackText
        emptyStateFooter.text = viewModel.footerLabelText
        emptyStateFooter.font = SystemFont.regular.of(textStyle: .footnote)
        
        // Non-empty state stuff
        tableView.backgroundColor = StormModeStatus.shared.isOn ? .stormModeBlack : .primaryColor
        tableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        tableView.indicatorStyle = .white
        
        addPaymentAccountBottomBar.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        addPaymentAccountLabel.textColor = .deepGray
        addPaymentAccountLabel.text = NSLocalizedString("Add Payment Method", comment: "")
        addPaymentAccountLabel.font = SystemFont.regular.of(textStyle: .headline)
        miniCreditCardButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniCreditCardButton.layer.cornerRadius = 8
        miniBankButton.addShadow(color: .black, opacity: 0.17, offset: .zero, radius: 3)
        miniBankButton.layer.cornerRadius = 8

        tableViewFooter.text = viewModel.footerLabelText
        tableViewFooter.font = OpenSans.semibold.of(textStyle: .footnote)
        
        emptyStateScrollView.isHidden = true
        nonEmptyStateView.isHidden = true
        
        // Cash only stuff
        emptyStateCashOnlyLabel.font = OpenSans.semibold.of(textStyle: .headline)
        emptyStateCashOnlyLabel.textColor = .blackText
        if viewModel.accountDetail.isCashOnly {
            emptyStateCashOnlyLabel.text = NSLocalizedString("Bank account payments are not available for this account.", comment: "")
        } else {
            emptyStateCashOnlyLabel.text = nil
            emptyStateCashOnlyTopConstraint.constant = 0
        }

        cashOnlyTableHeaderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        cashOnlyTableHeaderLabel.textColor = .white
        cashOnlyTableHeaderLabel.text = NSLocalizedString("Bank account payments are not available for this account.", comment: "")
        cashOnlyTableHeaderLabel.isHidden = !viewModel.accountDetail.isCashOnly
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        setupBinding()
        setupButtonTaps()
        
        viewModel.fetchWalletItems.onNext(()) // Fetch the items!
        
        addAccessibility()
    }
    
    func addAccessibility() {
        bankButton.isAccessibilityElement = true
        bankButton.accessibilityLabel = NSLocalizedString("Add Bank Account. " + bankFeeLabel.text!, comment: "")
        miniBankButton.isAccessibilityElement = true
        miniBankButton.accessibilityLabel = NSLocalizedString("Add Bank account", comment: "")
        
        creditCardButton.isAccessibilityElement = true
        creditCardButton.accessibilityLabel = NSLocalizedString("Add Credit Card. " + creditCardFeeLabel.text!, comment: "")
        miniCreditCardButton.isAccessibilityElement = true
        miniCreditCardButton.accessibilityLabel = NSLocalizedString("Add Credit card", comment: "")
        
        addPaymentAccountBottomBar.accessibilityElements = [addPaymentAccountLabel, miniBankButton, miniCreditCardButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the table header view
        if let headerView = tableView.tableHeaderView {
            if viewModel.accountDetail.isCashOnly {
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
    
    func setupBinding() {
        viewModel.isFetchingWalletItems.map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowEmptyState.map(!).drive(emptyStateScrollView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowEmptyState.drive(onNext: { [weak self] shouldShow in
            guard let self = self else { return }
            if shouldShow {
                UIAccessibility.post(notification: .screenChanged, argument: self.emptyStateScrollView)
            }
        }).disposed(by: disposeBag)
        viewModel.shouldShowWallet.map(!).drive(nonEmptyStateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowWallet.filter { $0 }.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
            UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
        }).disposed(by: disposeBag)
        
        if viewModel.addBankDisabled {
            miniBankButton.isEnabled = false
            bankButton.isEnabled = false
        }
        
        viewModel.hasExpiredWalletItem
            .drive(onNext: { [weak self] in
                let alert = UIAlertController(title: nil,
                                              message: NSLocalizedString("Please update your Wallet as one or more of your saved payment methods have expired.", comment: ""),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    func setupButtonTaps() {
        Driver.merge(bankButton.rx.touchUpInside.asDriver(), miniBankButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                if Environment.shared.opco == .bge {
                    self.performSegue(withIdentifier: "addBankAccountSegue", sender: self)
                } else {
                    let paymentusVC = PaymentusFormViewController(bankOrCard: .bank, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
                    paymentusVC.delegate = self
                    paymentusVC.shouldPopToRootOnSave = self.shouldPopToRootOnSave
                    self.navigationController?.pushViewController(paymentusVC, animated: true)
                }
            }).disposed(by: disposeBag)
        
        Driver.merge(creditCardButton.rx.touchUpInside.asDriver(), miniCreditCardButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                if Environment.shared.opco == .bge {
                    self.performSegue(withIdentifier: "addCreditCardSegue", sender: self)
                } else {
                    let paymentusVC = PaymentusFormViewController(bankOrCard: .card, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
                    paymentusVC.delegate = self
                    paymentusVC.shouldPopToRootOnSave = self.shouldPopToRootOnSave
                    self.navigationController?.pushViewController(paymentusVC, animated: true)
                }
            }).disposed(by: disposeBag)
    }
    
    @objc func onWalletItemPress(sender: ButtonControl) {
        if let walletItems = viewModel.walletItems.value, sender.tag < walletItems.count {
            selectedWalletItem = walletItems[sender.tag]
            if selectedWalletItem!.bankOrCard == .card {
                performSegue(withIdentifier: "editCreditCardSegue", sender: self)
            } else {
                performSegue(withIdentifier: "editBankAccountSegue", sender: self)
            }
        }
    }
    
    @objc func onEditWalletItemPress(sender: UIButton) {
        if let walletItems = viewModel.walletItems.value, sender.tag < walletItems.count {
            selectedWalletItem = walletItems[sender.tag]
            let paymentusVC = PaymentusFormViewController(bankOrCard: selectedWalletItem!.bankOrCard, temporary: false, walletItemId: selectedWalletItem!.walletItemID)
            paymentusVC.delegate = self
            paymentusVC.shouldPopToRootOnSave = shouldPopToRootOnSave
            paymentusVC.editingDefaultItem = selectedWalletItem!.isDefault
            self.navigationController?.pushViewController(paymentusVC, animated: true)
        }
    }
    
    @objc func onDeleteWalletItemPress(sender: UIButton) {
        if let walletItems = viewModel.walletItems.value, sender.tag < walletItems.count {
            selectedWalletItem = walletItems[sender.tag]
            
            var title: String
            var toast: String
            if selectedWalletItem!.bankOrCard == .bank {
                title = NSLocalizedString("Delete Bank Account?", comment: "")
                toast = NSLocalizedString("Bank Account deleted", comment: "")
            } else {
                title = NSLocalizedString("Delete Card?", comment: "")
                toast = NSLocalizedString("Card deleted", comment: "")
            }
            let messageString = NSLocalizedString("All one-time payments scheduled with this payment method will still be processed. You can review and edit your scheduled payments in Payment Activity.", comment: "")
            
            let alertController = UIAlertController(title: title, message: messageString, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                LoadingView.show()
                self.viewModel.deleteWalletItem(walletItem: self.selectedWalletItem!, onSuccess: { [weak self] in
                    LoadingView.hide()
                    
                    guard let self = self else { return }
                    
                    self.viewModel.fetchWalletItems.onNext(())
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                        self.view.showToast(toast)
                    })
                }, onError: { errMessage in
                    LoadingView.hide()
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
                })
            }))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let oneTouchPayItem = viewModel.walletItems.value?.first(where: { $0.isDefault == true })

        if let vc = segue.destination as? AddBankAccountViewController {
            vc.accountDetail = viewModel.accountDetail
            vc.oneTouchPayItem = oneTouchPayItem
            if let walletItems = viewModel.walletItems.value {
                vc.nicknamesInWallet = walletItems.map { $0.nickName ?? "" }.filter { !$0.isEmpty }
            }
            vc.delegate = self
            vc.shouldPopToRootOnSave = shouldPopToRootOnSave
            vc.shouldSetOneTouchPayByDefault = shouldSetOneTouchPayByDefault
        } else if let vc = segue.destination as? AddCreditCardViewController {
            vc.accountDetail = viewModel.accountDetail
            vc.oneTouchPayItem = oneTouchPayItem
            if let walletItems = viewModel.walletItems.value {
                vc.nicknamesInWallet = walletItems.map { $0.nickName ?? "" }.filter { !$0.isEmpty }
            }
            vc.delegate = self
            vc.shouldPopToRootOnSave = shouldPopToRootOnSave
            vc.shouldSetOneTouchPayByDefault = shouldSetOneTouchPayByDefault
        } else if let vc = segue.destination as? EditBankAccountViewController {
            vc.viewModel.accountDetail = viewModel.accountDetail
            vc.viewModel.walletItem = selectedWalletItem
            vc.viewModel.oneTouchPayItem = oneTouchPayItem
            vc.delegate = self
            vc.shouldPopToRootOnSave = shouldPopToRootOnSave
        } else if let vc = segue.destination as? EditCreditCardViewController {
            vc.viewModel.accountDetail = viewModel.accountDetail
            vc.viewModel.walletItem = selectedWalletItem
            vc.viewModel.oneTouchPayItem = oneTouchPayItem
            vc.delegate = self
            vc.shouldPopToRootOnSave = shouldPopToRootOnSave
        }
    }
    
    func didChangeAccount(toastMessage: String) {
        didUpdateSubject.onNext(toastMessage)
        if !shouldPopToRootOnSave {
            viewModel.fetchWalletItems.onNext(())
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.view.showToast(toastMessage)
            })
        }
    }
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        if Environment.shared.opco == .bge {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WalletCell", for: indexPath) as! WalletTableViewCell
            
            let walletItem = viewModel.walletItems.value![indexPath.section]
            cell.bindToWalletItem(walletItem, billingInfo: viewModel.accountDetail.billingInfo)
            
            cell.innerContentView.tag = indexPath.section
            cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.innerContentView.addTarget(self, action: #selector(onWalletItemPress(sender:)), for: .touchUpInside)
            
            cell.oneTouchPayView.isHidden = !walletItem.isDefault
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ePayWalletCell", for: indexPath) as! ePayWalletTableViewCell
            
            let walletItem = viewModel.walletItems.value![indexPath.section]
            cell.bindToWalletItem(walletItem, billingInfo: viewModel.accountDetail.billingInfo)
            
            cell.editButton.tag = indexPath.section
            cell.editButton.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.editButton.addTarget(self, action: #selector(onEditWalletItemPress(sender:)), for: .touchUpInside)
            cell.editButton.isEnabled = !(walletItem.bankOrCard == .bank && viewModel.accountDetail.isCashOnly)
            
            cell.deleteButton.tag = indexPath.section
            cell.deleteButton.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.deleteButton.addTarget(self, action: #selector(onDeleteWalletItemPress(sender:)), for: .touchUpInside)
            
            cell.oneTouchPayView.isHidden = !walletItem.isDefault
            
            return cell
        }
    }
    
}

extension WalletViewController: AddBankAccountViewControllerDelegate {
    
    func addBankAccountViewControllerDidAddAccount(_ addBankAccountViewController: AddBankAccountViewController) {
        didChangeAccount(toastMessage: NSLocalizedString("Bank account added", comment: ""))
        Analytics.log(event: .addWalletComplete)
    }
    
}

extension WalletViewController: EditBankAccountViewControllerDelegate {
    
    func editBankAccountViewControllerDidEditAccount(_ editBankAccountViewController: EditBankAccountViewController, message: String) {
        didChangeAccount(toastMessage: message)
    }
    
}

extension WalletViewController: AddCreditCardViewControllerDelegate {
    
    func addCreditCardViewControllerDidAddAccount(_ addCreditCardViewController: AddCreditCardViewController) {
        didChangeAccount(toastMessage: NSLocalizedString("Card added", comment: ""))
        Analytics.log(event: .addWalletComplete)
    }
}

extension WalletViewController: EditCreditCardViewControllerDelegate {
    
    func editCreditCardViewControllerDidEditAccount(_ editCreditCardViewController: EditCreditCardViewController, message: String) {
        didChangeAccount(toastMessage: message)
    }
    
}

extension WalletViewController: PaymentusFormViewControllerDelegate {
    func didEditWalletItem() {
        didChangeAccount(toastMessage: NSLocalizedString("Changes saved", comment: ""))
    }
    
    func didAddBank(_ walletItem: WalletItem?) {
        didChangeAccount(toastMessage: NSLocalizedString("Bank account added", comment: ""))
        Analytics.log(event: .addWalletComplete)
    }
    
    func didAddCard(_ walletItem: WalletItem?) {
        didChangeAccount(toastMessage: NSLocalizedString("Card added", comment: ""))
        Analytics.log(event: .addWalletComplete)
    }
}
