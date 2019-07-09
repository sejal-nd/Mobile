//
//  WalletViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class WalletViewController: UIViewController {

    let disposeBag = DisposeBag()

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!

    // Empty state stuff
    @IBOutlet weak var emptyStateScrollView: UIScrollView!
    @IBOutlet weak var emptyStateCashOnlyLabel: UILabel!
    @IBOutlet weak var emptyStateCashOnlyTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var choosePaymentMethodLabel: UILabel!
    @IBOutlet weak var bankButton: ButtonControl!
    @IBOutlet weak var bankButtonLabel: UILabel!
    @IBOutlet weak var creditCardButton: ButtonControl!
    @IBOutlet weak var creditCardButtonLabel: UILabel!
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

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("My Wallet", comment: "")
        view.backgroundColor = .softGray

        // Empty state stuff
        choosePaymentMethodLabel.textColor = .blackText
        choosePaymentMethodLabel.font = OpenSans.semibold.of(textStyle: .headline)
        choosePaymentMethodLabel.text = NSLocalizedString("Choose a payment method:", comment: "")

        bankButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        bankButton.layer.cornerRadius = 10
        bankButtonLabel.textColor = .blackText
        bankButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        bankButtonLabel.text = NSLocalizedString("Bank Account", comment: "")

        creditCardButton.addShadow(color: .black, opacity: 0.22, offset: .zero, radius: 4)
        creditCardButton.layer.cornerRadius = 10
        creditCardButtonLabel.textColor = .blackText
        creditCardButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        creditCardButtonLabel.text = NSLocalizedString("Credit/Debit Card", comment: "")

        emptyStateFooter.textColor = .blackText
        emptyStateFooter.text = viewModel.footerLabelText
        emptyStateFooter.font = SystemFont.regular.of(textStyle: .footnote)
        emptyStateFooter.setLineHeight(lineHeight: 17)

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

    
    // MARK: - Helper
    
    private func addAccessibility() {
        bankButton.isAccessibilityElement = true
        bankButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        miniBankButton.isAccessibilityElement = true
        miniBankButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        
        creditCardButton.isAccessibilityElement = true
        creditCardButton.accessibilityLabel = NSLocalizedString("Add credit card", comment: "")
        miniCreditCardButton.isAccessibilityElement = true
        miniCreditCardButton.accessibilityLabel = NSLocalizedString("Add credit card", comment: "")
        
        addPaymentAccountBottomBar.accessibilityElements = [addPaymentAccountLabel, miniBankButton, miniCreditCardButton] as [UIView]
    }
    
    private func setupBinding() {
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

    private func setupButtonTaps() {
        Driver.merge(bankButton.rx.touchUpInside.asDriver(), miniBankButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let paymentusVC = PaymentusFormViewController(bankOrCard: .bank, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
                paymentusVC.delegate = self
                paymentusVC.shouldPopToRootOnSave = self.shouldPopToRootOnSave
                self.navigationController?.pushViewController(paymentusVC, animated: true)
            }).disposed(by: disposeBag)

        Driver.merge(creditCardButton.rx.touchUpInside.asDriver(), miniCreditCardButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let paymentusVC = PaymentusFormViewController(bankOrCard: .card, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
                paymentusVC.delegate = self
                paymentusVC.shouldPopToRootOnSave = self.shouldPopToRootOnSave
                self.navigationController?.pushViewController(paymentusVC, animated: true)
            }).disposed(by: disposeBag)
    }
    
    private func didChangeAccount(toastMessage: String) {
        didUpdateSubject.onNext(toastMessage)
        if !shouldPopToRootOnSave {
            viewModel.fetchWalletItems.onNext(())
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.view.showToast(toastMessage)
            })
        }
    }

    
    // MARK: - Actions
    
    @objc private func onEditWalletItemPress(sender: UIButton) {
        if let walletItems = viewModel.walletItems.value, sender.tag < walletItems.count {
            selectedWalletItem = walletItems[sender.tag]
            let paymentusVC = PaymentusFormViewController(bankOrCard: selectedWalletItem!.bankOrCard, temporary: false, walletItemId: selectedWalletItem!.walletItemId)
            paymentusVC.delegate = self
            paymentusVC.shouldPopToRootOnSave = shouldPopToRootOnSave
            paymentusVC.editingDefaultItem = selectedWalletItem!.isDefault
            self.navigationController?.pushViewController(paymentusVC, animated: true)
        }
    }

    @objc private func onDeleteWalletItemPress(sender: UIButton) {
        if let walletItems = viewModel.walletItems.value, sender.tag < walletItems.count {
            selectedWalletItem = walletItems[sender.tag]

            let title: String
            var message = NSLocalizedString("All one-time payments scheduled with this payment method will still be processed. You can review and edit your scheduled payments in Bill & Payment Activity.", comment: "")
            let toast: String
            if selectedWalletItem!.bankOrCard == .bank {
                title = NSLocalizedString("Delete Bank Account?", comment: "")
                toast = NSLocalizedString("Bank Account deleted", comment: "")
                if Environment.shared.opco == .bge {
                    message += NSLocalizedString(" Utility Accounts enrolled in AutoPay using this payment method will be unenrolled.", comment: "")
                }
            } else {
                title = NSLocalizedString("Delete Card?", comment: "")
                toast = NSLocalizedString("Card deleted", comment: "")
            }

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
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

    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}


// MARK: - Table View Delegate

extension WalletViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let walletItems = viewModel.walletItems.value else {
            return 0
        }
        return walletItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.walletItems.value != nil ? 1 : 0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 14
    }
}


// MARK: - Table View Data Source

extension WalletViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WalletCell", for: indexPath) as? WalletTableViewCell else {
            fatalError("Invalid Table View Cell.")
        }

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


// MARK: - Paymentus Form Delegate

extension WalletViewController: PaymentusFormViewControllerDelegate {
    func didEditWalletItem() {
        didChangeAccount(toastMessage: NSLocalizedString("Changes saved", comment: ""))
    }
    
    func didAddWalletItem(_ walletItem: WalletItem) {
        Analytics.log(event: .addWalletComplete)

        let toastMessage = walletItem.bankOrCard == .bank ?
            NSLocalizedString("Bank account added", comment: "") :
            NSLocalizedString("Card added", comment: "")
        didChangeAccount(toastMessage: toastMessage)
    }
}
