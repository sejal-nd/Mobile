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
    
    @IBOutlet weak var addBankContainerView: UIView!
    @IBOutlet weak var addBankFormView: AddBankFormView!
    @IBOutlet weak var addCardContainerView: UIView!
    @IBOutlet weak var addCardFormView: AddCardFormView!
    @IBOutlet weak var inlinePaymentDividerLine: UIView!
    
    @IBOutlet weak var activeSeveranceLabel: UILabel!
    @IBOutlet weak var bankAccountsUnavailableLabel: UILabel!
    
    @IBOutlet weak var paymentAccountView: UIView! // Contains paymentAccountLabel and paymentAccountButton
    @IBOutlet weak var paymentAccountLabel: UILabel! // Label that says "Payment Method" above the button
    @IBOutlet weak var paymentAccountButton: ButtonControl!
    @IBOutlet weak var paymentAccountImageView: UIImageView!
    @IBOutlet weak var paymentAccountAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentAccountNicknameLabel: UILabel!
    @IBOutlet weak var paymentAccountExpiredSelectLabel: UILabel!
    @IBOutlet weak var fixedPaymentAccountView: UIView!
    @IBOutlet weak var fixedPaymentAccountImageView: UIImageView!
    @IBOutlet weak var fixedPaymentAccountAccountNumberLabel: UILabel!
    @IBOutlet weak var fixedPaymentAccountNicknameLabel: UILabel!
    
    @IBOutlet weak var cvvView: UIView!
    @IBOutlet weak var cvvTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTooltipButton: UIButton!
    
    @IBOutlet weak var amountDueView: UIView! // Contains amountDueTextLabel and amountDueValueLabel
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    
    @IBOutlet weak var paymentAmountView: UIView! // Contains paymentAmountFeeLabel and paymentAmountTextField
    @IBOutlet private weak var selectPaymentAmountStack: UIStackView!
    @IBOutlet private weak var selectPaymentAmountLabel: UILabel!
    @IBOutlet private weak var paymentAmountsStack: UIStackView!
    @IBOutlet weak var paymentAmountFeeLabel: UILabel!
    @IBOutlet weak var paymentAmountTextField: FloatLabelTextField!
    
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
    
    var cardIOViewController: CardIOPaymentViewController!
    
    var viewModel: PaymentViewModel!
    var accountDetail: AccountDetail! // Passed in from presenting view
    var paymentDetail: PaymentDetail? // Passed in from BillingHistoryViewController IF we had the data already (ComEd/PECO)
    var billingHistoryItem: BillingHistoryItem? // Passed in from BillingHistoryViewController, indicates we are modifying a payment
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PaymentViewModel(walletService: ServiceFactory.createWalletService(), paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormView.viewModel, addCardFormViewModel: addCardFormView.viewModel, paymentDetail: paymentDetail, billingHistoryItem: billingHistoryItem)
        
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
        viewModel.shouldShowNextButton.distinctUntilChanged()
            .filter(!)
            .drive(onNext: { [weak self] _ in
                self?.navigationItem.rightBarButtonItem = nil
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Inline bank fields
        addBankContainerView.isHidden = true
        addBankFormView.delegate = self
        addBankFormView.viewModel.paymentWorkflow.value = true
        bindInlineBankAccessibility()
        
        // Inline card fields
        addCardContainerView.isHidden = true
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
        
        cvvTextField.textField.placeholder = NSLocalizedString("CVV2*", comment: "")
        cvvTextField.textField.delegate = self
        cvvTextField.setKeyboardType(.numberPad)
        cvvTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.cvv.asDriver(), viewModel.cvvIsCorrectLength))
            .drive(onNext: { [weak self] (cvv, cvvIsCorrectLength) in
                if !cvv.isEmpty && !cvvIsCorrectLength {
                    self?.cvvTextField.setError(NSLocalizedString("Must be 3 or 4 digits", comment: ""))
                }
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        cvvTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] _ in
                self?.cvvTextField.setError(nil)
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        cvvTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
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
        
        configureCardIO()
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()
        
        viewModel.shouldShowSelectPaymentAmount.asObservable().single().subscribe(onNext: { [weak self] shouldShow in
            guard let self = self else { return }
            self.paymentAmountTextField.textField.text = shouldShow ?
                0.0.currencyString :
                self.viewModel.paymentAmount.value.currencyString
        }).disposed(by: disposeBag)

        fetchData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setColoredNavBar()
    }
    
    func fetchData() {
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
        }, onError: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }, onSpeedpayCutoff: { [weak self] in
                guard let self = self else { return }
                let alert = UIAlertController.speedpayCutoffAlert { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                
                self.present(alert, animated: true, completion: nil)
        })
    }
    
    func configureCardIO() {
        CardIOUtilities.preloadCardIO() // Speeds up subsequent launch
        cardIOViewController = CardIOPaymentViewController.init(paymentDelegate: self)
        cardIOViewController.disableManualEntryButtons = true
        cardIOViewController.guideColor = .successGreen
        cardIOViewController.hideCardIOLogo = true
        cardIOViewController.collectCardholderName = false
        cardIOViewController.collectExpiry = false
        cardIOViewController.collectCVV = false
        cardIOViewController.collectPostalCode = false
        cardIOViewController.navigationBarStyle = .black
        cardIOViewController.navigationBarTintColor = .primaryColor
        cardIOViewController.navigationBar.isTranslucent = false
        cardIOViewController.navigationBar.tintColor = .white
        let titleDict: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: OpenSans.bold.of(size: 18)
        ]
        cardIOViewController.navigationBar.titleTextAttributes = titleDict
    }
    
    func bindViewHiding() {
        // Loading
        viewModel.isFetching.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Inline Bank/Card
        viewModel.inlineBank.asDriver().drive(onNext: { [weak self] inlineBank in
            UIView.animate(withDuration: 0.33, animations: {
                self?.addBankContainerView.isHidden = !inlineBank
            })
        }).disposed(by: disposeBag)
        
        viewModel.inlineCard.asDriver().drive(onNext: { [weak self] inlineCard in
            UIView.animate(withDuration: 0.33, animations: {
                self?.addCardContainerView.isHidden = !inlineCard
            })
        }).disposed(by: disposeBag)
        
        viewModel.shouldShowInlinePaymentDivider.map(!).drive(inlinePaymentDividerLine.rx.isHidden).disposed(by: disposeBag)
        
        // Active Severance Label
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Cash Only Bank Accounts Unavailable Label
        viewModel.isCashOnlyUser.map(!).drive(bankAccountsUnavailableLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Method
        viewModel.shouldShowPaymentAccountView.map(!).drive(paymentAccountView.rx.isHidden).disposed(by: disposeBag)
        viewModel.allowEdits.asDriver().not().drive(paymentAccountButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.allowEdits.asDriver().drive(fixedPaymentAccountView.rx.isHidden).disposed(by: disposeBag)
        viewModel.wouldBeSelectedWalletItemIsExpired.asDriver().not().drive(paymentAccountExpiredSelectLabel.rx.isHidden).disposed(by: disposeBag)
        
        // CVV (BGE credit card only)
        viewModel.shouldShowCvvTextField.map(!).drive(cvvView.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Amount Text Field
        viewModel.shouldShowPaymentAmountTextField.map(!).drive(paymentAmountView.rx.isHidden).disposed(by: disposeBag)
        
        // Fixed Payment Amount - if allowEdits is false
        viewModel.allowEdits.asDriver().drive(fixedPaymentAmountView.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.shouldShowPaymentDateView.map(!).drive(paymentDateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isFixedPaymentDate.drive(paymentDateButtonView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isFixedPaymentDate.map(!).drive(paymentDateFixedDateLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowPastDueLabel.map(!).drive(paymentDateFixedDatePastDueLabel.rx.isHidden).disposed(by: disposeBag)
        
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
        
        if Environment.shared.opco != .bge && billingHistoryItem != nil {
            // ePay R1 ComEd/PECO modify tweaks
            amountDueView.isHidden = true
            dueDateView.isHidden = true
        }
    }
    
    func bindViewContent() {
        // Inline payment
        viewModel.oneTouchPayDescriptionLabelText.drive(addBankFormView.oneTouchPayDescriptionLabel.rx.text).disposed(by: disposeBag)
        viewModel.oneTouchPayDescriptionLabelText.drive(addCardFormView.oneTouchPayDescriptionLabel.rx.text).disposed(by: disposeBag)
        viewModel.bgeCommercialUserEnteringVisa.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] enteringVisa in
                self?.addCardFormView.cardNumberTextField.setError(enteringVisa ? NSLocalizedString("Business customers cannot use VISA to make a payment", comment: "") : nil)
        }).disposed(by: disposeBag)
        
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
        
        // CVV (BGE credit card only)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).disposed(by: disposeBag)
        
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
        
        // Wallet Footer Label
        viewModel.walletFooterLabelText.drive(walletFooterLabel.rx.text).disposed(by: disposeBag)
        
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
            miniWalletVC.viewModel.selectedItem.value = self.viewModel.selectedWalletItem.value
            miniWalletVC.viewModel.temporaryItem.value = self.viewModel.newlyAddedWalletItem.value
            miniWalletVC.accountDetail = self.viewModel.accountDetail.value
            miniWalletVC.sentFromPayment = true
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
                if Environment.shared.opco == .bge {
                    self.viewModel.inlineBank.value = true
                } else {
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
                }
            }).disposed(by: disposeBag)
        
        addCreditCardButton.rx.touchUpInside
            .do(onNext: { Analytics.log(event: .addCardNewWallet) })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if Environment.shared.opco == .bge {
                    self.viewModel.inlineCard.value = true
                } else {
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
                }
            }).disposed(by: disposeBag)
        
        cancelPaymentButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.onDeletePaymentPress()
        }).disposed(by: disposeBag)
    }
    
    func bindInlineBankAccessibility() {
        Driver.merge(
            addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
                .withLatestFrom(viewModel.addBankFormViewModel.routingNumber.asDriver())
                .filter { !$0.isEmpty }
                .map(to: ()),
            
            addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
            
            addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
                .withLatestFrom(viewModel.addBankFormViewModel.accountNumber.asDriver())
                .filter { !$0.isEmpty }
                .map(to: ()),
            
            addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
            
            viewModel.addBankFormViewModel.confirmAccountNumberMatches.map(to: ()),
            
            viewModel.addBankFormViewModel.nicknameErrorString.map(to: ())
            )
            .drive(onNext: { [weak self] in
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
    }
    
    func bindInlineCardAccessibility() {
        Driver.merge(addCardFormView.expMonthTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
                     addCardFormView.expMonthTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
                     addCardFormView.cardNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
                     addCardFormView.cardNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
                     addCardFormView.expYearTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
                     addCardFormView.expYearTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
                     addCardFormView.cvvTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
                     addCardFormView.cvvTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
                     addCardFormView.zipCodeTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
                     addCardFormView.zipCodeTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
                     viewModel.addCardFormViewModel.nicknameErrorString.map(to: ()))
            .drive(onNext: { [weak self] in
                self?.accessibilityErrorLabel()
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
            nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            nextButton.accessibilityLabel = String(format: NSLocalizedString("%@ Next", comment: ""), message)
        }
    }
    
    @objc func onNextPress() {
        view.endEditing(true)
        
        if viewModel.inlineBank.value {
            Analytics.log(event: .eCheckOffer)
        } else if viewModel.inlineCard.value {
            Analytics.log(event: .cardOffer)
        } else if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard { // Existing wallet item
            switch bankOrCard {
            case .bank:
                Analytics.log(event: .eCheckOffer)
            case .card:
                Analytics.log(event: .cardOffer)
            }
        }
        
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
            let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to replace your default payment method?", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
        }
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
    
    @IBAction func onCVVTooltipPress() {
        let messageText: String
        switch Environment.shared.opco {
        case .bge:
            messageText = NSLocalizedString("Your security code is usually a 3 or 4 digit number found on your card.", comment: "")
        case .comEd, .peco:
            messageText = NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""),
                                                image: #imageLiteral(resourceName: "cvv_info"),
                                                description: messageText)
        navigationController?.present(infoModal, animated: true, completion: nil)
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
        if let newlyAddedItem = viewModel.newlyAddedWalletItem.value, newlyAddedItem.isTemporary, newlyAddedItem != walletItem {
            // Clear temp item if user unselected it
            viewModel.newlyAddedWalletItem.value = nil
        }
        viewModel.selectedWalletItem.value = walletItem
    }
    
    func miniWalletViewControllerDidTapAddBank(_ miniWalletViewController: MiniWalletViewController) {
        viewModel.inlineBank.value = true
    }
    
    func miniWalletViewControllerDidTapAddCard(_ miniWalletViewController: MiniWalletViewController) {
        viewModel.inlineCard.value = true
    }
}

// MARK: - PaymentusFormViewControllerDelegate

extension MakePaymentViewController: PaymentusFormViewControllerDelegate {
    func didAddWalletItem(_ walletItem: WalletItem) {
        viewModel.newlyAddedWalletItem.value = walletItem
        fetchData()
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
        
        let today = Calendar.opCo.startOfDay(for: Date())
        switch Environment.shared.opco {
        case .bge:
            var minDate: Date
            if Calendar.opCo.component(.hour, from: Date()) >= 20 {
                minDate = Calendar.opCo.date(byAdding: .day, value: 1, to: today)!
            } else {
                minDate = today
            }
            
            guard let todayPlus90 = Calendar.opCo.date(byAdding: .day, value: 90, to: today),
                let todayPlus180 = Calendar.opCo.date(byAdding: .day, value: 180, to: today) else {
                    return false
            }
            
            var maxDate: Date
            if viewModel.inlineCard.value || viewModel.selectedWalletItem.value?.bankOrCard == .card {
                maxDate = todayPlus90
            } else if viewModel.inlineBank.value || viewModel.selectedWalletItem.value?.bankOrCard == .bank {
                maxDate = todayPlus180
            } else {
                return false
            }
            
            //TODO: Remove cutoff check with BGE switch to paymentus
            if let cutoffDate = viewModel.speedpayCutoffDate.value {
                if minDate > cutoffDate { // No valid dates in this case
                    return false
                }
                
                maxDate = min(cutoffDate, maxDate)
            }
            
            return DateInterval(start: minDate, end: maxDate).contains(opCoTimeDate)
        case .comEd, .peco:
            if billingHistoryItem != nil && opCoTimeDate == today  { // Modifying payment on ComEd/PECO disables changing date to today
                return false
            }
            
            if let dueDate = viewModel.accountDetail.value.billingInfo.dueByDate {
                let startOfDueDate = Calendar.opCo.startOfDay(for: dueDate)
                return opCoTimeDate >= today && opCoTimeDate <= startOfDueDate
            }
        }
        
        // Should never get called?
        return opCoTimeDate >= today
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return }
        viewModel.paymentDate.value = Calendar.opCo.isDateInToday(opCoTimeDate) ? Date() : opCoTimeDate
    }
}

// MARK: - AddBankFormViewDelegate

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

// MARK: - AddCardFormViewDelegate

extension MakePaymentViewController: AddCardFormViewDelegate {
    func addCardFormViewDidTapCardIOButton(_ addCardFormView: AddCardFormView) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        Analytics.log(event: .addWalletCameraOffer)
        if cameraAuthorizationStatus == .denied || cameraAuthorizationStatus == .restricted {
            let alertVC = UIAlertController(title: NSLocalizedString("Camera Access", comment: ""), message: NSLocalizedString("You must allow camera access in Settings to use this feature.", comment: ""), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Open Settings", comment: ""), style: .default, handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }))
            present(alertVC, animated: true, completion: nil)
        } else {
            present(cardIOViewController!, animated: true, completion: nil)
        }
    }
    
    func addCardFormViewDidTapCVVTooltip(_ addCardFormView: AddCardFormView) {
        let messageText: String
        switch Environment.shared.opco {
        case .bge:
            messageText = NSLocalizedString("Your security code is usually a 3 or 4 digit number found on your card.", comment: "")
        case .comEd, .peco:
            messageText = NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""),
                                                image: #imageLiteral(resourceName: "cvv_info"),
                                                description: messageText)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}

// MARK: - CardIOPaymentViewControllerDelegate

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
