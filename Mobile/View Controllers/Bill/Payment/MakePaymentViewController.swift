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

class MakePaymentViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var addBankContainerView: UIView!
    @IBOutlet weak var addBankFormView: AddBankFormView!
    @IBOutlet weak var addCardContainerView: UIView!
    @IBOutlet weak var addCardFormView: AddCardFormView!
    @IBOutlet weak var inlinePaymentDividerLine: UIView!
    
    @IBOutlet weak var activeSeveranceLabel: UILabel!
    @IBOutlet weak var bankAccountsUnavailableLabel: UILabel!
    
    @IBOutlet weak var paymentAccountView: UIView! // Contains paymentAccountLabel and paymentAccountButton
    @IBOutlet weak var paymentAccountLabel: UILabel! // Label that says "Payment Account" above the button
    @IBOutlet weak var paymentAccountButton: ButtonControl!
    @IBOutlet weak var paymentAccountImageView: UIImageView!
    @IBOutlet weak var paymentAccountAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentAccountNicknameLabel: UILabel!
    
    @IBOutlet weak var cvvView: UIView!
    @IBOutlet weak var cvvTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTooltipButton: UIButton!
    
    @IBOutlet weak var amountDueView: UIView! // Contains amountDueTextLabel and amountDueValueLabel
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    
    @IBOutlet weak var paymentAmountView: UIView! // Contains paymentAmountFeeLabel and paymentAmountTextField
    @IBOutlet weak var paymentAmountFeeLabel: UILabel!
    @IBOutlet weak var paymentAmountTextField: FloatLabelTextField!
    
    @IBOutlet weak var dueDateView: UIView!
    @IBOutlet weak var dueDateTextLabel: UILabel!
    @IBOutlet weak var dueDateDateLabel: UILabel!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateButtonView: UIView!
    @IBOutlet weak var paymentDateButton: DisclosureButton!
    @IBOutlet weak var paymentDateFixedDateLabel: UILabel!
    @IBOutlet weak var paymentDateFixedDatePastDueLabel: UILabel!
    
    @IBOutlet weak var addBankAccountView: UIView!
    @IBOutlet weak var addBankAccountFeeLabel: UILabel!
    @IBOutlet weak var addBankAccountButton: ButtonControl!
    
    @IBOutlet weak var addCreditCardView: UIView!
    @IBOutlet weak var addCreditCardFeeLabel: UILabel!
    @IBOutlet weak var addCreditCardButton: ButtonControl!
    
    @IBOutlet weak var deletePaymentButton: ButtonControl!
    @IBOutlet weak var deletePaymentLabel: UILabel!
    
    @IBOutlet weak var billMatrixView: UIView!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    @IBOutlet weak var walletFooterSpacerView: UIView! // Only used for spacing when footerView is hidden
    @IBOutlet weak var walletFooterView: UIView!
    @IBOutlet weak var walletFooterLabel: UILabel!
    
    @IBOutlet weak var stickyPaymentFooterHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stickyPaymentFooterView: UIView!
    @IBOutlet weak var stickyPaymentFooterTextContainer: UIView!
    @IBOutlet weak var stickyPaymentFooterPaymentLabel: UILabel!
    @IBOutlet weak var stickyPaymentFooterFeeLabel: UILabel!

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    var nextButton = UIBarButtonItem()
    
    var cardIOViewController: CardIOPaymentViewController!
    
    var viewModel: PaymentViewModel!
    var accountDetail: AccountDetail! // Passed in from presenting view
    var paymentId: String? // Passed in from BillingHistoryViewController, indicates we are modifying a payment
    var paymentDetail: PaymentDetail? // Passed in from BillingHistoryViewController IF we had the data already (ComEd/PECO)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PaymentViewModel(walletService: ServiceFactory.createWalletService(), paymentService: ServiceFactory.createPaymentService(), accountDetail: self.accountDetail, addBankFormViewModel: self.addBankFormView.viewModel, addCardFormViewModel: self.addCardFormView.viewModel, paymentId: paymentId, paymentDetail: paymentDetail)
        
        view.backgroundColor = .softGray
        
        // Put white background on stack view
        let bg = UIView(frame: stackView.bounds)
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bg.backgroundColor = .white
        stackView.addSubview(bg)
        stackView.sendSubview(toBack: bg)
        
        if paymentId != nil {
            title = NSLocalizedString("Modify Payment", comment: "")
        } else {
            title = NSLocalizedString("Make a Payment", comment: "")
        }
        
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
        viewModel.makePaymentNextButtonEnabled.drive(nextButton.rx.isEnabled).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        // Inline bank fields
        addBankFormView.delegate = self
        addBankFormView.viewModel.paymentWorkflow.value = true
        bindInlineBankAccessibility()
        
        // Inline card fields
        addCardFormView.delegate = self
        addCardFormView.viewModel.paymentWorkflow.value = true
        bindInlineCardAccessibility()
        
        inlinePaymentDividerLine.backgroundColor = .lightGray
        
        activeSeveranceLabel.textColor = .blackText
        activeSeveranceLabel.font = SystemFont.semibold.of(textStyle: .headline)
        activeSeveranceLabel.text = NSLocalizedString("Due to the status of this account, online payments are limited to the current date. Payments also may not be edited or deleted.", comment: "")
        
        bankAccountsUnavailableLabel.textColor = .blackText
        bankAccountsUnavailableLabel.font = SystemFont.semibold.of(textStyle: .headline)
        bankAccountsUnavailableLabel.text = NSLocalizedString("Bank account payments are not available for this account.", comment: "")

        paymentAccountLabel.text = NSLocalizedString("Payment Account", comment: "")
        paymentAccountLabel.textColor = .deepGray
        paymentAccountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentAccountButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        paymentAccountButton.backgroundColorOnPress = .softGray
        paymentAccountAccountNumberLabel.textColor = .blackText
        paymentAccountAccountNumberLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentAccountNicknameLabel.textColor = .middleGray
        paymentAccountNicknameLabel.font = SystemFont.medium.of(textStyle: .footnote)
        
        cvvTextField.textField.placeholder = NSLocalizedString("CVV2*", comment: "")
        cvvTextField.textField.delegate = self
        cvvTextField.setKeyboardType(.numberPad)
        cvvTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.cvv.value.isEmpty {
                self.viewModel.cvvIsCorrectLength.single().subscribe(onNext: { valid in
                    if !valid {
                        self.cvvTextField.setError(NSLocalizedString("Must be 3 or 4 digits", comment: ""))
                    }
                }).disposed(by: self.disposeBag)
            }
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        cvvTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.cvvTextField.setError(nil)
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        cvvTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        amountDueTextLabel.text = NSLocalizedString("Amount Due", comment: "")
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueValueLabel.textColor = .blackText
        amountDueValueLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        paymentAmountFeeLabel.textColor = .blackText
        paymentAmountFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentAmountTextField.textField.placeholder = NSLocalizedString("Payment Amount*", comment: "")
        paymentAmountTextField.setKeyboardType(.decimalPad)
        viewModel.paymentAmountErrorMessage.asObservable().subscribe(onNext: { errorMessage in
            self.paymentAmountTextField.setError(errorMessage)
            self.accessibilityErrorLabel()
            
        }).disposed(by: self.disposeBag)
        
        dueDateTextLabel.text = NSLocalizedString("Due Date", comment: "")
        dueDateTextLabel.textColor = .deepGray
        dueDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateDateLabel.textColor = .blackText
        dueDateDateLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateTextLabel.textColor = .deepGray
        paymentDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentDateButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        paymentDateFixedDateLabel.textColor = .blackText
        paymentDateFixedDateLabel.font = SystemFont.semibold.of(textStyle: .title1)
        paymentDateFixedDatePastDueLabel.textColor = .blackText
        paymentDateFixedDatePastDueLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        addBankAccountFeeLabel.textColor = .blackText
        addBankAccountFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        addBankAccountFeeLabel.text = NSLocalizedString("No convenience fee will be applied.", comment: "")
        addBankAccountButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        addBankAccountButton.backgroundColorOnPress = .softGray
        addBankAccountButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        
        addCreditCardFeeLabel.textColor = .blackText
        addCreditCardFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        switch Environment.sharedInstance.opco {
        case .comEd, .peco:
            addCreditCardFeeLabel.text = String(format: NSLocalizedString("A %@ convenience fee will be applied by Bill matrix, our payment partner.", comment: ""), accountDetail.billingInfo.convenienceFee!.currencyString!)
            break
        case .bge:
            //let feeString = String(format: "Your payment includes a %@ convenience fee. ", accountDetail.isResidential ? accountDetail.billingInfo.residentialFee!.currencyString! : accountDetail.billingInfo.commercialFee!.percentString!)
            addCreditCardFeeLabel.text = String(format: NSLocalizedString("A convenience fee will be applied by Western Union Speedpay, our payment partner. Residential accounts: %@. Business accounts: %@.", comment: ""), accountDetail.billingInfo.residentialFee!.currencyString!, accountDetail.billingInfo.commercialFee!.percentString!)
            break
        }
        addCreditCardButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        addCreditCardButton.backgroundColorOnPress = .softGray
        addCreditCardButton.accessibilityLabel = NSLocalizedString("Add credit/debit card", comment: "")
        
        deletePaymentButton.accessibilityLabel = NSLocalizedString("Delete payment", comment: "")
        deletePaymentLabel.font = SystemFont.regular.of(textStyle: .headline)
        deletePaymentLabel.textColor = .actionBlue
        
        privacyPolicyButton.setTitleColor(.actionBlue, for: .normal)
        privacyPolicyButton.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
        
        walletFooterView.backgroundColor = .softGray
        walletFooterLabel.textColor = .deepGray
        walletFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        stickyPaymentFooterView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        stickyPaymentFooterPaymentLabel.textColor = .blackText
        stickyPaymentFooterFeeLabel.textColor = .deepGray
        
        configureCardIO()
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()
        addDoneButtonOnKeyboard()

        viewModel.formatPaymentAmount() // Initial formatting
        viewModel.fetchData(onSuccess: nil, onError: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: self, action: #selector(doneButtonAction))
        done.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.actionBlue], for: .normal)
        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()
        paymentAmountTextField.textField.inputAccessoryView = doneToolbar
        cvvTextField.textField.inputAccessoryView = doneToolbar
    }
    
    func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    func configureCardIO() {
        CardIOUtilities.preloadCardIO() // Speeds up subsequent launch
        cardIOViewController = CardIOPaymentViewController.init(paymentDelegate: self)
        cardIOViewController.disableManualEntryButtons = true
        cardIOViewController.guideColor = UIColor.successGreen
        cardIOViewController.hideCardIOLogo = true
        cardIOViewController.collectCardholderName = false
        cardIOViewController.collectExpiry = false
        cardIOViewController.collectCVV = false
        cardIOViewController.collectPostalCode = false
        cardIOViewController.navigationBarStyle = .black
        cardIOViewController.navigationBarTintColor = .primaryColor
        cardIOViewController.navigationBar.isTranslucent = false
        cardIOViewController.navigationBar.tintColor = .white
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        cardIOViewController.navigationBar.titleTextAttributes = titleDict
    }
    
    func bindViewHiding() {
        // Loading
        viewModel.isFetching.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowContent.map(!).drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowContent.map(!).drive(stickyPaymentFooterView.rx.isHidden).disposed(by: disposeBag)
        
        // Inline Bank/Card
        viewModel.inlineBank.asDriver().map(!).drive(addBankContainerView.rx.isHidden).disposed(by: disposeBag)
        viewModel.inlineCard.asDriver().map(!).drive(addCardContainerView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowInlinePaymentDivider.map(!).drive(inlinePaymentDividerLine.rx.isHidden).disposed(by: disposeBag)
        
        // Active Severance Label
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Cash Only Bank Accounts Unavailable Label
        viewModel.isCashOnlyUser.map(!).drive(bankAccountsUnavailableLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Account
        viewModel.shouldShowPaymentAccountView.map(!).drive(paymentAccountView.rx.isHidden).disposed(by: disposeBag)
        
        // CVV (BGE credit card only)
        viewModel.shouldShowCvvTextField.map(!).drive(cvvView.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Amount Text Field
        viewModel.shouldShowPaymentAmountTextField.map(!).drive(paymentAmountView.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.shouldShowPaymentDateView.map(!).drive(paymentDateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isFixedPaymentDate.drive(paymentDateButtonView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isFixedPaymentDate.map(!).drive(paymentDateFixedDateLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isFixedPaymentDatePastDue.map(!).drive(paymentDateFixedDatePastDueLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Add bank/credit card empty wallet state
        viewModel.shouldShowAddBankAccount.map(!).drive(addBankAccountView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAddCreditCard.map(!).drive(addCreditCardView.rx.isHidden).disposed(by: disposeBag)
        
        // Delete Payment
        viewModel.shouldShowDeletePaymentButton.map(!).drive(deletePaymentButton.rx.isHidden).disposed(by: disposeBag)
        
        // Bill Matrix
        viewModel.shouldShowBillMatrixView.map(!).drive(billMatrixView.rx.isHidden).disposed(by: disposeBag)
        
        // Wallet empty state info footer
        viewModel.shouldShowWalletFooterView.map(!).drive(walletFooterView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowWalletFooterView.drive(walletFooterSpacerView.rx.isHidden).disposed(by: disposeBag)
        
        // Sticky Footer
        viewModel.shouldShowStickyFooterView.drive(onNext: { shouldShow in
            self.stickyPaymentFooterHeightConstraint.constant = shouldShow ? 80 : 0
            // For some reason, just hiding stickyPaymentFooterView was not enough to hide the label...
            self.stickyPaymentFooterTextContainer.isHidden = !shouldShow
        }).disposed(by: disposeBag)
    }
    
    func bindViewContent() {
        // Inline payment
        viewModel.oneTouchPayDescriptionLabelText.drive(addBankFormView.oneTouchPayDescriptionLabel.rx.text).disposed(by: disposeBag)
        viewModel.oneTouchPayDescriptionLabelText.drive(addCardFormView.oneTouchPayDescriptionLabel.rx.text).disposed(by: disposeBag)
        viewModel.bgeCommercialUserEnteringVisa.asObservable().subscribe(onNext: { enteringVisa in
            self.addCardFormView.cardNumberTextField.setError(enteringVisa ? NSLocalizedString("Business customers cannot use VISA to make a payment", comment: "") : nil)
        }).disposed(by: disposeBag)
        
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).disposed(by: disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(paymentAccountButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        // CVV (BGE credit card only)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).disposed(by: disposeBag)
        
        // Amount Due
        viewModel.amountDueCurrencyString.asDriver().drive(amountDueValueLabel.rx.text).disposed(by: disposeBag)
        
        // Payment Amount Text Field
        viewModel.paymentAmountFeeLabelText.asDriver().drive(paymentAmountFeeLabel.rx.text).disposed(by: disposeBag)
        viewModel.paymentAmount.asDriver().drive(paymentAmountTextField.textField.rx.text.orEmpty).disposed(by: disposeBag)
        paymentAmountTextField.textField.rx.text.orEmpty.bind(to: viewModel.paymentAmount).disposed(by: disposeBag)
        paymentAmountTextField.textField.rx.controlEvent(.editingChanged).subscribe(onNext: {
            self.viewModel.formatPaymentAmount()
        }).disposed(by: disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateDateLabel.rx.text).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateButton.label.rx.text).disposed(by: disposeBag)
        viewModel.paymentDateString.asDriver().drive(paymentDateFixedDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.paymentDateString.asDriver().drive(paymentDateButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        // Wallet Footer Label
        viewModel.walletFooterLabelText.drive(walletFooterLabel.rx.text).disposed(by: disposeBag)
        
        // Sticky Footer Payment View
        viewModel.totalPaymentDisplayString.map { String(format: NSLocalizedString("Total Payment: %@", comment: ""), $0) }.drive(stickyPaymentFooterPaymentLabel.rx.text).disposed(by: disposeBag)
        viewModel.paymentAmountFeeFooterLabelText.drive(stickyPaymentFooterFeeLabel.rx.text).disposed(by: disposeBag)
    }
    
    func bindButtonTaps() {
        paymentAccountButton.rx.touchUpInside.subscribe(onNext: {
            self.view.endEditing(true)
            let miniWalletVC = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "miniWallet") as! MiniWalletViewController
            miniWalletVC.viewModel.walletItems.value = self.viewModel.walletItems.value
            miniWalletVC.viewModel.selectedItem.value = self.viewModel.selectedWalletItem.value
            miniWalletVC.accountDetail = self.viewModel.accountDetail.value
            miniWalletVC.sentFromPayment = true
            miniWalletVC.delegate = self
            if self.paymentId != nil, let walletItem = self.viewModel.selectedWalletItem.value {
                if Environment.sharedInstance.opco == .bge {
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
        
        paymentDateButton.rx.touchUpInside.subscribe(onNext: {
            self.view.endEditing(true)
            
            let calendarVC = PDTSimpleCalendarViewController()
            calendarVC.delegate = self
            calendarVC.title = NSLocalizedString("Select Payment Date", comment: "")
            calendarVC.selectedDate = self.viewModel.paymentDate.value
            
            self.navigationController?.pushViewController(calendarVC, animated: true)
        }).disposed(by: disposeBag)
        
        addBankAccountButton.rx.touchUpInside.subscribe(onNext: {
            self.viewModel.inlineBank.value = true
        }).disposed(by: disposeBag)
        
        addCreditCardButton.rx.touchUpInside.subscribe(onNext: {
            self.viewModel.inlineCard.value = true
        }).disposed(by: disposeBag)
        
        deletePaymentButton.rx.touchUpInside.subscribe(onNext: {
            self.onDeletePaymentPress()
        }).disposed(by: disposeBag)
        
        privacyPolicyButton.rx.touchUpInside.asDriver().drive(onNext: onPrivacyPolicyPress).disposed(by: disposeBag)
    }
    
    func bindInlineBankAccessibility() {
        addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.addBankFormViewModel.routingNumber.value.isEmpty {
                self.viewModel.addBankFormViewModel.routingNumberIsValid().single().subscribe(onNext: { valid in
                    self.accessibilityErrorLabel()
                }).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.addBankFormViewModel.accountNumber.value.isEmpty {
                self.viewModel.addBankFormViewModel.accountNumberIsValid().single().subscribe(onNext: { valid in
                    self.accessibilityErrorLabel()
                }).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.addBankFormViewModel.confirmAccountNumberMatches().subscribe(onNext: { matches in
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.addBankFormViewModel.nicknameErrorString().subscribe(onNext: { valid in
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    func bindInlineCardAccessibility() {
        addCardFormView.expMonthTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.expMonthTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.cardNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.cardNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.expYearTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.expYearTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.cvvTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.cvvTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.zipCodeTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addCardFormView.zipCodeTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.addCardFormViewModel.nicknameErrorString().map{ $0 == nil }.subscribe(onNext: { valid in
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        
        // Inline Bank
        message += addBankFormView.routingNumberTextField.getError()
        message += addBankFormView.accountNumberTextField.getError()
        message += addBankFormView.confirmAccountNumberTextField.getError()
        message += addBankFormView.nicknameTextField.getError()
        
        // Inline Card
        message += addCardFormView.cardNumberTextField.getError()
        message += addCardFormView.expMonthTextField.getError()
        message += addCardFormView.expYearTextField.getError()
        message += addCardFormView.cvvTextField.getError()
        message += addCardFormView.zipCodeTextField.getError()
        message += addCardFormView.nicknameTextField.getError()
        
        // Payment Fields
        message += cvvTextField.getError()
        message += paymentAmountTextField.getError()
        
        if message.isEmpty {
            self.nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            self.nextButton.accessibilityLabel = NSLocalizedString(message + " Next", comment: "")
        }
    }
    
    func onNextPress() {
        self.view.endEditing(true)
        
        var shouldShowOneTouchPayWarning = false
        if viewModel.inlineBank.value {
            if viewModel.addBankFormViewModel.oneTouchPay.value {
                if viewModel.oneTouchPayItem != nil {
                    shouldShowOneTouchPayWarning = true
                }
            }
        } else if viewModel.inlineCard.value {
            if viewModel.addCardFormViewModel.oneTouchPay.value {
                if viewModel.oneTouchPayItem != nil {
                    shouldShowOneTouchPayWarning = true
                }
            }
        }
        
        if shouldShowOneTouchPayWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("One Touch Pay", comment: ""), message: NSLocalizedString("Are you sure you want to replace your current One Touch Pay payment account?", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                self.performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
        }
    }
    
    func onPrivacyPolicyPress() {
        let tacModal = WebViewController(title: NSLocalizedString("Privacy Policy", comment: ""),
                                         url: URL(string:"https://webpayments.billmatrix.com/HTML/privacy_notice_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    func onDeletePaymentPress() {
        let confirmAlert = UIAlertController(title: NSLocalizedString("Delete Scheduled Payment", comment: ""), message: NSLocalizedString("Are you sure you want to delete this scheduled payment?", comment: ""), preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
            LoadingView.show()
            self.viewModel.cancelPayment(onSuccess: { 
                LoadingView.hide()

                // Always pop back to the root billing history screen here (because MoreBillingHistoryViewController does not refetch data)
                for vc in (self.navigationController?.viewControllers)! {
                    guard let dest = vc as? BillingHistoryViewController else {
                        continue
                    }
                    dest.onPaymentDelete()
                    self.navigationController?.popToViewController(dest, animated: true)
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }, onError: { errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })
        }))
        present(confirmAlert, animated: true, completion: nil)
    }
    
    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height - stickyPaymentFooterHeightConstraint.constant, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReviewPaymentViewController {
            vc.viewModel = viewModel
        }
    }
    
    @IBAction func onCVVTooltipPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""), image: #imageLiteral(resourceName: "cvv_info"), description: NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }

}

extension MakePaymentViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.characters.count == 0 { // Allow backspace
            return true
        }
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == paymentAmountTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            
            let numDec = newString.components(separatedBy:".")
            
            if numDec.count > 2 {
                return false
            } else if numDec.count == 2 && numDec[1].characters.count > 2 {
                return false
            }
            
            let containsDecimal = newString.contains(".")
            let containsBackslash = newString.contains("\\")
            
            return (CharacterSet.decimalDigits.isSuperset(of: characterSet) || containsDecimal) && newString.characters.count <= 8 && !containsBackslash
        }
        return true
    }
}

extension MakePaymentViewController: MiniWalletViewControllerDelegate {
    
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem) {
        viewModel.selectedWalletItem.value = walletItem
    }
    
    func miniWalletViewControllerDidTapAddBank(_ miniWalletViewController: MiniWalletViewController) {
        viewModel.inlineBank.value = true
    }
    
    func miniWalletViewControllerDidTapAddCard(_ miniWalletViewController: MiniWalletViewController) {
        viewModel.inlineCard.value = true
    }
}

extension MakePaymentViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        if Environment.sharedInstance.opco == .bge {
            let todayPlus90 = Calendar.current.date(byAdding: .day, value: 90, to: today)!
            let todayPlus180 = Calendar.current.date(byAdding: .day, value: 180, to: today)!
            if viewModel.inlineCard.value {
                return date >= today && date <= todayPlus90
            } else if viewModel.inlineBank.value {
                return date >= today && date <= todayPlus180
            } else if let walletItem = viewModel.selectedWalletItem.value {
                if walletItem.bankOrCard == .card {
                    return date >= today && date <= todayPlus90
                } else {
                    return date >= today && date <= todayPlus180
                }
            }
        } else {
            if let dueDate = viewModel.accountDetail.value.billingInfo.dueByDate {
                let startOfDueDate = Calendar.current.startOfDay(for: dueDate)
                if Environment.sharedInstance.opco == .peco {
                    let isInWorkdaysArray = viewModel.workdayArray.contains(date)
                    return date >= today && date <= startOfDueDate && isInWorkdaysArray
                } else {
                    return date >= today && date <= startOfDueDate
                }
            }
        }
        
        // Should never get called?
        return date >= today
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        viewModel.paymentDate.value = date
    }
}

extension MakePaymentViewController: AddBankFormViewDelegate {
    func addBankFormViewDidTapRoutingNumberTooltip(_ addBankFormView: AddBankFormView) {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Routing Number", comment: ""), image: #imageLiteral(resourceName: "routing_number_info"), description: NSLocalizedString("This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    func addBankFormViewDidTapAccountNumberTooltip(_ addBankFormView: AddBankFormView) {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Account Number", comment: ""), image: #imageLiteral(resourceName: "account_number_info"), description: NSLocalizedString("This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}

extension MakePaymentViewController: AddCardFormViewDelegate {
    func addCardFormViewDidTapCardIOButton(_ addCardFormView: AddCardFormView) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        Analytics().logScreenView(AnalyticsPageView.AddWalletCameraOffer.rawValue)
        if cameraAuthorizationStatus == .denied || cameraAuthorizationStatus == .restricted {
            let alertVC = UIAlertController(title: NSLocalizedString("Camera Access", comment: ""), message: NSLocalizedString("You must allow camera access in Settings to use this feature.", comment: ""), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Open Settings", comment: ""), style: .default, handler: { _ in
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url)
                }
            }))
            present(alertVC, animated: true, completion: nil)
        } else {
            present(cardIOViewController!, animated: true, completion: nil)
        }
    }
    
    func addCardFormViewDidTapCVVTooltip(_ addCardFormView: AddCardFormView) {
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""), image: #imageLiteral(resourceName: "cvv_info"), description: NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}

extension MakePaymentViewController: CardIOPaymentViewControllerDelegate {
    func userDidCancel(_ paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
    }
    
    func userDidProvide(_ cardInfo: CardIOCreditCardInfo!, in paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
        addCardFormView.cardNumberTextField.textField.text = cardInfo.cardNumber
        addCardFormView.cardNumberTextField.textField.sendActions(for: .editingChanged) // updates viewModel
    }
}
