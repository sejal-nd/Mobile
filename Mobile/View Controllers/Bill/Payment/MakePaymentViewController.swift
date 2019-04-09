//
//  MakePaymentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import AVFoundation
import PDTSimpleCalendar
import UIKit

class MakePaymentViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var activeSeveranceLabel: UILabel!
    @IBOutlet weak var bankAccountsUnavailableLabel: UILabel!
    
    @IBOutlet weak var paymentAccountView: UIView! // Contains paymentAccountLabel and paymentAccountButton
    @IBOutlet weak var paymentAccountLabel: UILabel! // Label that says "Payment Method" above the button
    @IBOutlet weak var paymentAccountButton: ButtonControl!
    @IBOutlet weak var paymentAccountImageView: UIImageView!
    @IBOutlet weak var paymentAccountAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentAccountNicknameLabel: UILabel!
    @IBOutlet weak var paymentAccountExpiredSelectLabel: UILabel!
    
    // TODO: Confirm if still needed for ePay R2 - Remove here + Storyboard if not
    @IBOutlet weak var fixedPaymentAccountView: UIView!
    @IBOutlet weak var fixedPaymentAccountImageView: UIImageView!
    @IBOutlet weak var fixedPaymentAccountAccountNumberLabel: UILabel!
    @IBOutlet weak var fixedPaymentAccountNicknameLabel: UILabel!
    
    @IBOutlet weak var amountDueView: UIView! // Contains amountDueTextLabel and amountDueValueLabel
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    
    @IBOutlet weak var paymentAmountView: UIView! // Contains paymentAmountFeeLabel and paymentAmountTextField
    @IBOutlet private weak var selectPaymentAmountStack: UIStackView!
    @IBOutlet private weak var selectPaymentAmountLabel: UILabel!
    @IBOutlet private weak var paymentAmountsStack: UIStackView!
    @IBOutlet weak var paymentAmountFeeLabel: UILabel!
    @IBOutlet weak var paymentAmountTextField: FloatLabelTextField!
    
    // TODO: Confirm if still needed for ePay R2 - Remove here + Storyboard if not
    @IBOutlet weak var fixedPaymentAmountView: UIView!
    @IBOutlet weak var fixedPaymentAmountTextLabel: UILabel!
    @IBOutlet weak var fixedPaymentAmountValueLabel: UILabel!
    
    @IBOutlet weak var dueDateView: UIView!
    @IBOutlet weak var dueDateTextLabel: UILabel!
    @IBOutlet weak var dueDateDateLabel: UILabel!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateButtonView: UIView!
    @IBOutlet weak var paymentDateButton: DisclosureButton!
    @IBOutlet weak var paymentDateFixedDateLabel: UILabel!
    @IBOutlet weak var paymentDateFixedDatePastDueLabel: UILabel!
    
    @IBOutlet weak var editPaymentDetailView: UIView!
    @IBOutlet weak var paymentStatusView: UIView!
    @IBOutlet weak var paymentStatusTextLabel: UILabel!
    @IBOutlet weak var paymentStatusValueLabel: UILabel!
    @IBOutlet weak var confirmationNumberView: UIView!
    @IBOutlet weak var confirmationNumberTextLabel: UILabel!
    @IBOutlet weak var confirmationNumberValueLabel: UILabel!
    
    @IBOutlet weak var addPaymentMethodView: UIView!
    @IBOutlet weak var addPaymentMethodLabel: UILabel!
    @IBOutlet weak var addBankAccountButton: ButtonControl!
    @IBOutlet weak var addBankAccountLabel: UILabel!
    @IBOutlet weak var addCreditCardButton: ButtonControl!
    @IBOutlet weak var addCreditCardLabel: UILabel!
    
    @IBOutlet weak var cancelPaymentButton: ButtonControl!
    @IBOutlet weak var cancelPaymentLabel: UILabel!
    
    @IBOutlet weak var walletFooterSpacerView: UIView! // Only used for spacing when footerView is hidden
    @IBOutlet weak var walletFooterView: UIView!
    @IBOutlet weak var walletFooterLabel: UILabel!
    
    @IBOutlet weak var stickyPaymentFooterStackView: UIStackView!
    @IBOutlet weak var stickyPaymentFooterView: UIView!
    @IBOutlet weak var stickyPaymentFooterTextContainer: UIView!
    @IBOutlet weak var stickyPaymentFooterPaymentLabel: UILabel!
    @IBOutlet weak var stickyPaymentFooterFeeLabel: UILabel!

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    var nextButton = UIBarButtonItem()
    
    var viewModel: PaymentViewModel!
    var accountDetail: AccountDetail! // Passed in from presenting view
    var billingHistoryItem: BillingHistoryItem? // Passed in from Billing History, indicates we are modifying a payment
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PaymentViewModel(walletService: ServiceFactory.createWalletService(), paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail, billingHistoryItem: billingHistoryItem)
        
        view.backgroundColor = .softGray
        
        // Put white background on stack view
        let bg = UIView(frame: stackView.bounds)
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bg.backgroundColor = .white
        stackView.addSubview(bg)
        stackView.sendSubviewToBack(bg)
        
        if billingHistoryItem != nil {
            title = NSLocalizedString("Modify Payment", comment: "")
        } else {
            title = NSLocalizedString("Make a Payment", comment: "")
        }
        
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
        viewModel.makePaymentNextButtonEnabled.drive(nextButton.rx.isEnabled).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        activeSeveranceLabel.textColor = .blackText
        activeSeveranceLabel.font = SystemFont.semibold.of(textStyle: .headline)
        activeSeveranceLabel.text = NSLocalizedString("Due to the status of this account, online payments are limited to the current date. Payments also may not be edited or deleted.", comment: "")
        
        bankAccountsUnavailableLabel.textColor = .blackText
        bankAccountsUnavailableLabel.font = SystemFont.semibold.of(textStyle: .headline)
        bankAccountsUnavailableLabel.text = NSLocalizedString("Bank account payments are not available for this account.", comment: "")

        paymentAccountLabel.text = NSLocalizedString("Payment Method", comment: "")
        paymentAccountLabel.textColor = .deepGray
        paymentAccountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentAccountButton.layer.cornerRadius = 10
        paymentAccountButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        paymentAccountButton.backgroundColorOnPress = .softGray
        paymentAccountAccountNumberLabel.textColor = .blackText
        paymentAccountAccountNumberLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentAccountNicknameLabel.textColor = .middleGray
        paymentAccountNicknameLabel.font = SystemFont.medium.of(textStyle: .footnote)
        
        amountDueTextLabel.text = NSLocalizedString("Total Amount Due", comment: "")
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueValueLabel.textColor = .blackText
        amountDueValueLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        selectPaymentAmountLabel.textColor = .blackText
        selectPaymentAmountLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        
        paymentAmountFeeLabel.textColor = .blackText
        paymentAmountFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentAmountTextField.textField.placeholder = NSLocalizedString("Payment Amount*", comment: "")
        paymentAmountTextField.setKeyboardType(.decimalPad)
        viewModel.paymentAmountErrorMessage.asDriver().drive(onNext: { [weak self] errorMessage in
            self?.paymentAmountTextField.setError(errorMessage)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        fixedPaymentAmountTextLabel.text = NSLocalizedString("Payment Amount", comment: "")
        fixedPaymentAmountTextLabel.textColor = .deepGray
        fixedPaymentAmountTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        fixedPaymentAmountValueLabel.textColor = .blackText
        fixedPaymentAmountValueLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        dueDateTextLabel.text = NSLocalizedString("Due Date", comment: "")
        dueDateTextLabel.textColor = .deepGray
        dueDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateDateLabel.textColor = .blackText
        dueDateDateLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateTextLabel.textColor = .deepGray
        paymentDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentDateFixedDateLabel.textColor = .blackText
        paymentDateFixedDateLabel.font = SystemFont.semibold.of(textStyle: .title1)
        paymentDateFixedDatePastDueLabel.textColor = .blackText
        paymentDateFixedDatePastDueLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        addPaymentMethodLabel.textColor = .deepGray
        addPaymentMethodLabel.font = OpenSans.semibold.of(textStyle: .title2)
        addPaymentMethodLabel.text = NSLocalizedString("Choose a payment method:", comment: "")

        addBankAccountButton.layer.cornerRadius = 10
        addBankAccountButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        addBankAccountButton.backgroundColorOnPress = .softGray
        addBankAccountButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        
        addBankAccountLabel.font = SystemFont.medium.of(textStyle: .title1)
        
        addCreditCardButton.layer.cornerRadius = 10
        addCreditCardButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        addCreditCardButton.backgroundColorOnPress = .softGray
        addCreditCardButton.accessibilityLabel = NSLocalizedString("Add credit/debit card", comment: "")
        
        addCreditCardLabel.font = SystemFont.medium.of(textStyle: .title1)
        
        let cancelPaymentText = NSLocalizedString("Cancel Payment", comment: "")
        cancelPaymentButton.accessibilityLabel = cancelPaymentText
        cancelPaymentLabel.text = cancelPaymentText
        cancelPaymentLabel.font = SystemFont.regular.of(textStyle: .headline)
        cancelPaymentLabel.textColor = .actionBlue
        
        walletFooterView.backgroundColor = .softGray
        walletFooterLabel.textColor = .deepGray
        walletFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        stickyPaymentFooterView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        stickyPaymentFooterPaymentLabel.textColor = .blackText
        stickyPaymentFooterPaymentLabel.font = SystemFont.semibold.of(textStyle: .title1)
        stickyPaymentFooterFeeLabel.textColor = .deepGray
        stickyPaymentFooterFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()
        
        viewModel.shouldShowSelectPaymentAmount.asObservable().single().subscribe(onNext: { [weak self] shouldShow in
            guard let self = self else { return }
            self.paymentAmountTextField.textField.text = shouldShow ?
                0.0.currencyString :
                self.viewModel.paymentAmount.value.currencyString
        }).disposed(by: disposeBag)

        fetchData(initialFetch: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setColoredNavBar()
    }
    
    func fetchData(initialFetch: Bool) {
        viewModel.fetchData(initialFetch: initialFetch, onSuccess: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
        }, onError: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
        })
    }
    
    func bindViewHiding() {
        // Loading
        viewModel.isFetching.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Active Severance Label
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Cash Only Bank Accounts Unavailable Label
        viewModel.isCashOnlyUser.map(!).drive(bankAccountsUnavailableLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Method
        viewModel.shouldShowPaymentAccountView.map(!).drive(paymentAccountView.rx.isHidden).disposed(by: disposeBag)
        viewModel.wouldBeSelectedWalletItemIsExpired.asDriver().not().drive(paymentAccountExpiredSelectLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Amount Text Field
        viewModel.shouldShowPaymentAmountTextField.map(!).drive(paymentAmountView.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.shouldShowPaymentDateView.map(!).drive(paymentDateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowPastDueLabel.map(!).drive(paymentDateFixedDatePastDueLabel.rx.isHidden).disposed(by: disposeBag)
        paymentDateButtonView.isHidden = !viewModel.canEditPaymentDate
        paymentDateFixedDateLabel.isHidden = viewModel.canEditPaymentDate
        
        // Add bank/credit card empty wallet state
        viewModel.shouldShowAddPaymentMethodView.map(!).drive(addPaymentMethodView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAddBankAccount.map(!).drive(addBankAccountButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAddCreditCard.map(!).drive(addCreditCardButton.rx.isHidden).disposed(by: disposeBag)
        
        // Cancel Payment
        viewModel.shouldShowCancelPaymentButton.map(!).drive(cancelPaymentButton.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowStickyFooterView.drive(onNext: { [weak self] shouldShow in
            if Environment.shared.opco != .bge && self?.billingHistoryItem != nil {
                // ePay R1 ComEd/PECO modify tweaks
                self?.stickyPaymentFooterView.isHidden = true
            } else {
                self?.stickyPaymentFooterView.isHidden = !shouldShow
            }
            
            // Needed for correct sizing
            self?.stickyPaymentFooterStackView.setNeedsLayout()
            self?.stickyPaymentFooterStackView.layoutIfNeeded()
        }).disposed(by: disposeBag)
        
        // Edit Payment Stuff
        if billingHistoryItem != nil {
            amountDueView.isHidden = true
            dueDateView.isHidden = true
        } else {
            editPaymentDetailView.isHidden = true
        }
        
        // Currently not using. Keeping around in case payment method/amount become not editable in some cases
        fixedPaymentAccountView.isHidden = true
        fixedPaymentAmountView.isHidden = true
    }
    
    func bindViewContent() {
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).disposed(by: disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.showSelectedWalletItemNickname.not().drive(paymentAccountNicknameLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(paymentAccountButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.selectedWalletItemImage.drive(fixedPaymentAccountImageView.rx.image).disposed(by: disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(fixedPaymentAccountAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemNickname.drive(fixedPaymentAccountNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.showSelectedWalletItemNickname.not().drive(fixedPaymentAccountNicknameLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(fixedPaymentAccountView.rx.accessibilityLabel).disposed(by: disposeBag)
        
        // Amount Due
        viewModel.amountDueCurrencyString.asDriver().drive(amountDueValueLabel.rx.text).disposed(by: disposeBag)
        
        // Select Payment Amount - Radio Button Selection View
        viewModel.shouldShowSelectPaymentAmount.drive(onNext: { [weak self] shouldShow in
            guard let self = self else { return }
            self.selectPaymentAmountStack.isHidden = !shouldShow
            self.paymentAmountTextField.isHidden = shouldShow
            
            self.paymentAmountsStack.arrangedSubviews.forEach {
                self.paymentAmountsStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            
            if shouldShow {
                let radioControls = self.viewModel.paymentAmounts.map { (amount, subtitle) -> RadioSelectControl in
                    let title = amount?.currencyString ?? NSLocalizedString("Other", comment: "")
                    return RadioSelectControl.create(withTitle: title, subtitle: subtitle, showSeparator: true)
                }
                
                let radioPress = { [weak self] (control: RadioSelectControl, amount: Double?) -> () in
                    guard let self = self else { return }
                    
                    // Only set and animate `isHidden` if the value should change.
                    // Otherwise we get weird animation queue issues 🤷‍♂️
                    let shouldHide = control != radioControls.last
                    if shouldHide != self.paymentAmountTextField.isHidden {
                        UIView.animate(withDuration: 0.2) {
                            self.paymentAmountTextField.isHidden = shouldHide
                        }
                    }
                    
                    radioControls.forEach { $0.isSelected = $0 == control }
                    
                    if let amount = amount {
                        self.paymentAmountTextField.textField.resignFirstResponder()
                        self.viewModel.paymentAmount.value = amount
                    } else {
                        self.paymentAmountTextField.textField.becomeFirstResponder()
                    }
                }
                
                zip(radioControls, self.viewModel.paymentAmounts.map { $0.0 }).forEach { control, amount in
                    control.rx.touchUpInside.asDriver()
                        .drive(onNext: { radioPress(control, amount) })
                        .disposed(by: control.bag)
                    
                    self.paymentAmountsStack.addArrangedSubview(control)
                }
                
                if let firstControl = radioControls.first, let firstAmount = self.viewModel.paymentAmounts.first?.0 {
                    radioPress(firstControl, firstAmount)
                }
            }
        }).disposed(by: disposeBag)
        
        // Payment Amount Text Field
        viewModel.paymentAmountFeeLabelText.asDriver()
            .drive(paymentAmountFeeLabel.rx.text)
            .disposed(by: disposeBag)
        
        paymentAmountTextField.textField.rx.text.orEmpty.asObservable()
            .skip(1)
            .subscribe(onNext: { [weak self] entry in
                guard let self = self else { return }
                
                let amount: Double
                let textStr = String(entry.filter { "0123456789".contains($0) })
                if let intVal = Double(textStr) {
                    amount = intVal / 100
                } else {
                    amount = 0
                }
                
                self.paymentAmountTextField.textField.text = amount.currencyString
                self.viewModel.paymentAmount.value = amount
            })
            .disposed(by: disposeBag)
        
        // Fixed Payment Amount - if allowEdits is false
        viewModel.paymentAmountString.asDriver().drive(fixedPaymentAmountValueLabel.rx.text).disposed(by: disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateDateLabel.rx.text).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateButton.label.rx.text).disposed(by: disposeBag)
        viewModel.paymentDateString.asDriver().drive(paymentDateFixedDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.paymentDateString.asDriver().drive(paymentDateButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        // Edit Payment Detail View
        paymentStatusValueLabel.text = billingHistoryItem?.statusString?.capitalized
        confirmationNumberValueLabel.text = billingHistoryItem?.confirmationNumber ?? "--" // TODO - confirmation number is always null currently
        
        // Wallet Footer Label
        walletFooterLabel.text = viewModel.walletFooterLabelText
        
        // Sticky Footer Payment View
        viewModel.totalPaymentDisplayString.map { String(format: NSLocalizedString("Total Payment: %@", comment: ""), $0 ?? "--") }
            .drive(stickyPaymentFooterPaymentLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.paymentAmountFeeFooterLabelText.drive(stickyPaymentFooterFeeLabel.rx.text).disposed(by: disposeBag)
    }
    
    func bindButtonTaps() {
        paymentAccountButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            let miniWalletVC = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "miniWallet") as! MiniWalletViewController
            miniWalletVC.viewModel.walletItems.value = self.viewModel.walletItems.value
            if let selectedItem = self.viewModel.selectedWalletItem.value {
                miniWalletVC.viewModel.selectedItem.value = selectedItem
                if selectedItem.isTemporary {
                     miniWalletVC.viewModel.temporaryItem.value = selectedItem
                }
            }
            miniWalletVC.accountDetail = self.viewModel.accountDetail.value
            miniWalletVC.popToViewController = self
            miniWalletVC.delegate = self
            if self.billingHistoryItem != nil, let walletItem = self.viewModel.selectedWalletItem.value {
                if Environment.shared.opco == .bge {
                    if walletItem.bankOrCard == .bank {
                        miniWalletVC.tableHeaderLabelText = NSLocalizedString("When modifying a bank account payment, you may only select another bank account as your method of payment.", comment: "")
                        miniWalletVC.creditCardsDisabled = true
                    } else {
                        miniWalletVC.tableHeaderLabelText = NSLocalizedString("When modifying a card payment, you may only select another card as your method of payment.", comment: "")
                        miniWalletVC.bankAccountsDisabled = true
                    }
                } else {
                    miniWalletVC.tableHeaderLabelText = NSLocalizedString("When modifying a bank account payment, you may only select another bank account as your method of payment.", comment: "")
                    miniWalletVC.creditCardsDisabled = true
                }
            }
            self.navigationController?.pushViewController(miniWalletVC, animated: true)
        }).disposed(by: disposeBag)
        
        paymentDateButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            
            let calendarVC = PDTSimpleCalendarViewController()
            calendarVC.calendar = .opCo
            calendarVC.delegate = self
            calendarVC.title = NSLocalizedString("Select Payment Date", comment: "")
            calendarVC.selectedDate = self.viewModel.paymentDate.value
            
            self.navigationController?.pushViewController(calendarVC, animated: true)
        }).disposed(by: disposeBag)
        
        addBankAccountButton.rx.touchUpInside
            .do(onNext: { Analytics.log(event: .addBankNewWallet) })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let actionSheet = UIAlertController.saveToWalletActionSheet(bankOrCard: .bank, saveHandler: { [weak self] _ in
                    guard let self = self else { return }
                    let paymentusVC = PaymentusFormViewController(bankOrCard: .bank, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
                    paymentusVC.delegate = self
                    self.navigationController?.pushViewController(paymentusVC, animated: true)
                }, dontSaveHandler: { [weak self] _ in
                    let paymentusVC = PaymentusFormViewController(bankOrCard: .bank, temporary: true)
                    paymentusVC.delegate = self
                    self?.navigationController?.pushViewController(paymentusVC, animated: true)
                })
                self.present(actionSheet, animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        addCreditCardButton.rx.touchUpInside
            .do(onNext: { Analytics.log(event: .addCardNewWallet) })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let actionSheet = UIAlertController.saveToWalletActionSheet(bankOrCard: .card, saveHandler: { [weak self] _ in
                    guard let self = self else { return }
                    let paymentusVC = PaymentusFormViewController(bankOrCard: .card, temporary: false, isWalletEmpty: self.viewModel.walletItems.value!.isEmpty)
                    paymentusVC.delegate = self
                    self.navigationController?.pushViewController(paymentusVC, animated: true)
                }, dontSaveHandler: { [weak self] _ in
                    let paymentusVC = PaymentusFormViewController(bankOrCard: .card, temporary: true)
                    paymentusVC.delegate = self
                    self?.navigationController?.pushViewController(paymentusVC, animated: true)
                })
                self.present(actionSheet, animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        cancelPaymentButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.onDeletePaymentPress()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        let message = paymentAmountTextField.getError()
        if message.isEmpty {
            nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            nextButton.accessibilityLabel = String(format: NSLocalizedString("%@ Next", comment: ""), message)
        }
    }
    
    @objc func onNextPress() {
        view.endEditing(true)
        
        if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard {
            switch bankOrCard {
            case .bank:
                Analytics.log(event: .eCheckOffer)
            case .card:
                Analytics.log(event: .cardOffer)
            }
        }
        
        performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
    }
    
    func onDeletePaymentPress() {
        let alertTitle = NSLocalizedString("Cancel Payment", comment: "")
        let alertMessage = NSLocalizedString("Are you sure you want to cancel this payment?", comment: "")
        let alertConfirm = NSLocalizedString("Yes", comment: "")
        let alertDeny = NSLocalizedString("No", comment: "")
        
        let confirmAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: alertDeny, style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: alertConfirm, style: .destructive, handler: { [weak self] _ in
            LoadingView.show()
            self?.viewModel.cancelPayment(onSuccess: { [weak self] in
                LoadingView.hide()

                guard let self = self, let navigationController = self.navigationController else { return }
                // Always pop back to the root billing history screen here (because MoreBillingHistoryViewController does not refetch data)
                for vc in navigationController.viewControllers {
                    guard let dest = vc as? BillingHistoryViewController else {
                        continue
                    }
                    dest.onPaymentDelete()
                    navigationController.popToViewController(dest, animated: true)
                    return
                }
                navigationController.popViewController(animated: true)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })
        }))
        present(confirmAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReviewPaymentViewController {
            vc.viewModel = viewModel
        }
    }
        
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - ScrollView
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - stickyPaymentFooterView.frame.size.height, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
}

// MARK: - UITextFieldDelegate

extension MakePaymentViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count == 0 { // Allow backspace
            return true
        }
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == paymentAmountTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            
            let numDec = newString.components(separatedBy:".")
            
            if numDec.count > 2 {
                return false
            } else if numDec.count == 2 && numDec[1].count > 2 {
                return false
            }
            
            let containsDecimal = newString.contains(".")
            let containsBackslash = newString.contains("\\")
            
            return (CharacterSet.decimalDigits.isSuperset(of: characterSet) || containsDecimal) && newString.count <= 8 && !containsBackslash
        }
        return true
    }
}

// MARK: - MiniWalletViewControllerDelegate

extension MakePaymentViewController: MiniWalletViewControllerDelegate {
    
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem) {
        if let existingWalletItem = viewModel.selectedWalletItem.value, existingWalletItem != walletItem {
            viewModel.computeDefaultPaymentDate()
        }
        viewModel.selectedWalletItem.value = walletItem
    }
    
}

// MARK: - PaymentusFormViewControllerDelegate

extension MakePaymentViewController: PaymentusFormViewControllerDelegate {
    func didAddWalletItem(_ walletItem: WalletItem) {
        if let existingWalletItem = viewModel.selectedWalletItem.value, existingWalletItem != walletItem {
            viewModel.computeDefaultPaymentDate()
        }
        viewModel.selectedWalletItem.value = walletItem
        fetchData(initialFetch: false)
        if !walletItem.isTemporary {
            Analytics.log(event: walletItem.bankOrCard == .bank ? .eCheckAddNewWallet : .cardAddNewWallet, dimensions: [.otpEnabled: walletItem.isDefault ? "enabled" : "disabled"])
            let toastMessage = walletItem.bankOrCard == .bank ?
                NSLocalizedString("Bank account added", comment: "") :
                NSLocalizedString("Card added", comment: "")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.view.showToast(toastMessage)
            })
        }
    }
}

// MARK: - PDTSimpleCalendarViewDelegate

extension MakePaymentViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return false }
        
        let today = Calendar.opCo.startOfDay(for: .now)
        switch Environment.shared.opco {
        case .bge:
            let minDate = today
            var maxDate: Date
            switch viewModel.selectedWalletItem.value?.bankOrCard {
            case .card?:
                maxDate = Calendar.opCo.date(byAdding: .day, value: 90, to: today) ?? today
            case .bank?:
                maxDate = Calendar.opCo.date(byAdding: .day, value: 180, to: today) ?? today
            default:
                return false
            }
            
            return DateInterval(start: minDate, end: maxDate).contains(opCoTimeDate)
        case .comEd, .peco:
            if billingHistoryItem != nil && opCoTimeDate == today  { // Modifying payment on ComEd/PECO disables changing date to today
                return false
            }
            
            if let dueDate = viewModel.accountDetail.value.billingInfo.dueByDate {
                let startOfDueDate = Calendar.opCo.startOfDay(for: dueDate)
                return DateInterval(start: today, end: startOfDueDate).contains(opCoTimeDate)
            }
        }
        
        // Should never get called?
        return opCoTimeDate >= today
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return }
        viewModel.paymentDate.value = opCoTimeDate.isInToday(calendar: .opCo) ? .now : opCoTimeDate
    }
}
