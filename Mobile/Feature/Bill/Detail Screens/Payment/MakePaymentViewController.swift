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

class MakePaymentViewController: KeyboardAvoidingStickyFooterViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var activeSeveranceLabel: UILabel!
    @IBOutlet weak var bankAccountsUnavailableLabel: UILabel!
    
    // Contains Total Amount Due and Due Date
    @IBOutlet weak var billInfoBox: UIView!
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    @IBOutlet weak var billInfoBoxDivider: UIView!
    @IBOutlet weak var dueDateTextLabel: UILabel!
    @IBOutlet weak var dueDateDateLabel: UILabel!
    
    // Contains Payment Status and Confirmation Number
    @IBOutlet weak var editPaymentInfoBox: UIView!
    @IBOutlet weak var paymentStatusView: UIView!
    @IBOutlet weak var paymentStatusTextLabel: UILabel!
    @IBOutlet weak var paymentStatusValueLabel: UILabel!
    @IBOutlet weak var editPaymentInfoBoxDivider: UIView!
    @IBOutlet weak var confirmationNumberView: UIView!
    @IBOutlet weak var confirmationNumberTextLabel: UILabel!
    @IBOutlet weak var confirmationNumberValueTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var paymentMethodContainerView: UIView!
    @IBOutlet weak var paymentMethodButton: ButtonControl!
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentMethodNicknameLabel: UILabel!
    @IBOutlet weak var paymentMethodFeeLabel: UILabel!
    
    @IBOutlet weak var paymentMethodExpiredButton: ButtonControl!
    @IBOutlet weak var paymentMethodExpiredSelectLabel: UILabel!
    
    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet private weak var selectPaymentAmountStack: UIStackView!
    @IBOutlet private weak var selectPaymentAmountLabel: UILabel!
    @IBOutlet private weak var paymentAmountsStack: UIStackView!

    @IBOutlet weak var paymentAmountTextField: FloatLabelTextField!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateButton: DisclosureButton!
    @IBOutlet weak var paymentDateErrorView: UIView!
    @IBOutlet weak var paymentDateErrorLabel: UILabel!
    @IBOutlet weak var paymentDatePastDueLabel: UILabel!
    @IBOutlet weak var sameDayPaymentWarningView: UIView!
    @IBOutlet weak var sameDayPaymentWarningLabel: UILabel!
    
    @IBOutlet weak var addPaymentMethodView: UIView!
    @IBOutlet weak var addPaymentMethodLabel: UILabel!
    @IBOutlet weak var addBankAccountButton: ButtonControl!
    @IBOutlet weak var addBankAccountLabel: UILabel!
    @IBOutlet weak var addCreditCardButton: ButtonControl!
    @IBOutlet weak var addCreditCardLabel: UILabel!
    
    @IBOutlet weak var cancelPaymentButton: ButtonControl!
    @IBOutlet weak var cancelPaymentLabel: UILabel!
    
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var stickyPaymentFooterStackView: UIStackView!
    @IBOutlet weak var stickyPaymentFooterView: StickyFooterView!
    @IBOutlet weak var stickyPaymentFooterTextContainer: UIView!
    @IBOutlet weak var stickyPaymentFooterTotalPaymentLabel: UILabel!
    @IBOutlet weak var stickyPaymentFooterAmountLabel: UILabel!
    @IBOutlet weak var stickyPaymentFooterFeeLabel: UILabel!
    @IBOutlet weak var continueButton: PrimaryButton!

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    var viewModel: PaymentViewModel!
    var accountDetail: AccountDetail! // Passed in from presenting view
    var billingHistoryItem: BillingHistoryItem? // Passed in from Billing History, indicates we are modifying a payment
    
    var hasPrecariousOtherAmountBeenSelected = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PaymentViewModel(walletService: ServiceFactory.createWalletService(), paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail, billingHistoryItem: billingHistoryItem)
        
        navigationItem.backBarButtonItem?.accessibilityLabel = "Back"
        
        if billingHistoryItem != nil {
            title = NSLocalizedString("Edit Payment", comment: "")
        } else {
            title = NSLocalizedString("Make a Payment", comment: "")
        }
        
        viewModel.makePaymentContinueButtonEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        activeSeveranceLabel.textColor = .deepGray
        activeSeveranceLabel.font = SystemFont.semibold.of(textStyle: .headline)
        activeSeveranceLabel.text = NSLocalizedString("Due to the status of this account, online payments are limited to the current date. Payments also may not be edited or deleted.", comment: "")
        
        bankAccountsUnavailableLabel.textColor = .deepGray
        bankAccountsUnavailableLabel.font = SystemFont.semibold.of(textStyle: .headline)
        bankAccountsUnavailableLabel.text = NSLocalizedString("Bank account payments are not available for this account.", comment: "")

        billInfoBox.layer.borderColor = UIColor.accentGray.cgColor
        billInfoBox.layer.borderWidth = 1
        stackView.setCustomSpacing(40, after: billInfoBox)
        amountDueTextLabel.text = NSLocalizedString("Total Amount Due", comment: "")
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueValueLabel.textColor = .deepGray
        amountDueValueLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        billInfoBoxDivider.backgroundColor = .accentGray
        dueDateTextLabel.text = NSLocalizedString("Due Date", comment: "")
        dueDateTextLabel.textColor = .deepGray
        dueDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateDateLabel.textColor = .deepGray
        dueDateDateLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        
        editPaymentInfoBox.layer.borderColor = UIColor.accentGray.cgColor
        editPaymentInfoBox.layer.borderWidth = 1
        paymentStatusTextLabel.text = NSLocalizedString("Payment Status", comment: "")
        paymentStatusTextLabel.textColor = .deepGray
        paymentStatusTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentStatusValueLabel.textColor = .deepGray
        paymentStatusValueLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        editPaymentInfoBoxDivider.backgroundColor = .accentGray
        confirmationNumberTextLabel.text = NSLocalizedString("Confirmation Number", comment: "")
        confirmationNumberTextLabel.textColor = .deepGray
        confirmationNumberTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberValueTextView.textColor = .deepGray
        confirmationNumberValueTextView.dataDetectorTypes.remove(.all) // Some confirmation numbers are detected as phone numbers
        confirmationNumberValueTextView.font = SystemFont.semibold.of(textStyle: .subheadline)
        
        paymentMethodLabel.text = NSLocalizedString("Payment Method*", comment: "")
        paymentMethodLabel.accessibilityLabel = "Payment Method*"
        paymentMethodLabel.textColor = .middleGray
        paymentMethodLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        
        paymentMethodButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        paymentMethodButton.backgroundColorOnPress = .softGray
        paymentMethodAccountNumberLabel.textColor = .deepGray
        paymentMethodAccountNumberLabel.font = SystemFont.regular.of(textStyle: .callout)
        paymentMethodNicknameLabel.textColor = .middleGray
        paymentMethodNicknameLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        paymentMethodExpiredButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        paymentMethodExpiredButton.backgroundColorOnPress = .softGray
        paymentMethodExpiredSelectLabel.textColor = .deepGray
        paymentMethodExpiredSelectLabel.font = SystemFont.regular.of(textStyle: .callout)
        paymentMethodExpiredSelectLabel.text = NSLocalizedString("Select Payment Method", comment: "")
        
        paymentMethodFeeLabel.textColor = .deepGray
        paymentMethodFeeLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        selectPaymentAmountLabel.textColor = .deepGray
        selectPaymentAmountLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        paymentAmountTextField.placeholder = NSLocalizedString("Payment Amount*", comment: "")
        paymentAmountTextField.textField.text = viewModel.paymentAmount.value.currencyString
        paymentAmountTextField.setKeyboardType(.decimalPad)
        viewModel.paymentAmountErrorMessage.asDriver().drive(onNext: { [weak self] errorMessage in
            self?.paymentAmountTextField.setError(errorMessage)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        paymentDateErrorLabel.textColor = .errorRed
        paymentDateErrorLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentDateErrorLabel.text = NSLocalizedString("Error: Invalid payment date.", comment: "")
        
        paymentDatePastDueLabel.textColor = .deepGray
        paymentDatePastDueLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentDatePastDueLabel.text = NSLocalizedString("Past due payments cannot be scheduled.", comment: "")
        
        sameDayPaymentWarningLabel.textColor = .deepGray
        sameDayPaymentWarningLabel.font = SystemFont.regular.of(textStyle: .footnote)
        sameDayPaymentWarningLabel.text = NSLocalizedString("Same day payments cannot be edited or canceled after submission.", comment: "")
        
        addPaymentMethodLabel.textColor = .deepGray
        addPaymentMethodLabel.font = OpenSans.regular.of(textStyle: .headline)
        addPaymentMethodLabel.text = NSLocalizedString("Choose a payment method", comment: "")

        addBankAccountButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        addBankAccountButton.backgroundColorOnPress = .softGray
        addBankAccountButton.accessibilityLabel = NSLocalizedString("Add bank account", comment: "")
        
        addBankAccountLabel.textColor = .deepGray
        addBankAccountLabel.font = SystemFont.regular.of(textStyle: .callout)
        
        addCreditCardButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        addCreditCardButton.backgroundColorOnPress = .softGray
        addCreditCardButton.accessibilityLabel = NSLocalizedString("Add credit/debit card", comment: "")
        
        addCreditCardLabel.textColor = .deepGray
        addCreditCardLabel.font = SystemFont.regular.of(textStyle: .callout)
        
        let cancelPaymentText = NSLocalizedString("Cancel Payment", comment: "")
        cancelPaymentButton.accessibilityLabel = cancelPaymentText
        cancelPaymentLabel.text = cancelPaymentText
        cancelPaymentLabel.font = SystemFont.semibold.of(textStyle: .headline)
        cancelPaymentLabel.textColor = .actionBlue
        
        footerLabel.textColor = .deepGray
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        stickyPaymentFooterTotalPaymentLabel.textColor = .deepGray
        stickyPaymentFooterTotalPaymentLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        stickyPaymentFooterAmountLabel.textColor = .deepGray
        stickyPaymentFooterAmountLabel.font = SystemFont.semibold.of(textStyle: .callout)
        stickyPaymentFooterFeeLabel.textColor = .deepGray
        stickyPaymentFooterFeeLabel.font = SystemFont.regular.of(textStyle: .caption1)
        stickyPaymentFooterView.accessibilityElements = [
            stickyPaymentFooterTotalPaymentLabel, stickyPaymentFooterAmountLabel,
            stickyPaymentFooterFeeLabel, continueButton
        ] as [UIView]
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .deepGray
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()

        fetchData(initialFetch: true)
        
        FirebaseUtility.logEvent(.makePaymentStart)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
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
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Active Severance Label
        viewModel.isActiveSeveranceUser.not().drive(activeSeveranceLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Cash Only Bank Accounts Unavailable Label
        viewModel.isCashOnlyUser.not().drive(bankAccountsUnavailableLabel.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Method
        viewModel.shouldShowPaymentMethodButton.not().drive(paymentMethodContainerView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowPaymentMethodExpiredButton.not().drive(paymentMethodExpiredButton.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Amount Text Field
        viewModel.shouldShowPaymentAmountTextField.not().drive(paymentAmountView.rx.isHidden).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.shouldShowPaymentDateView.not().drive(paymentDateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowPastDueLabel.not().drive(paymentDatePastDueLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isPaymentDateValid.drive(paymentDateErrorView.rx.isHidden).disposed(by: disposeBag)
        paymentDateButton.descriptionText = NSLocalizedString("Payment Date*", comment: "")
        paymentDateButton.isEnabled = viewModel.canEditPaymentDate
        viewModel.shouldShowSameDayPaymentWarning.not().drive(sameDayPaymentWarningView.rx.isHidden).disposed(by: disposeBag)
        
        // Add bank/credit card empty wallet state
        viewModel.shouldShowAddPaymentMethodView.not().drive(addPaymentMethodView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAddBankAccount.not().drive(addBankAccountButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowAddCreditCard.not().drive(addCreditCardButton.rx.isHidden).disposed(by: disposeBag)
        
        // Cancel Payment
        viewModel.shouldShowCancelPaymentButton.not().drive(cancelPaymentButton.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowStickyFooterView.drive(onNext: { [weak self] shouldShow in
            self?.stickyPaymentFooterView.isHidden = !shouldShow
            
            // Needed for correct sizing
            self?.stickyPaymentFooterStackView.setNeedsLayout()
            self?.stickyPaymentFooterStackView.layoutIfNeeded()
        }).disposed(by: disposeBag)
        
        // Edit Payment Stuff
        if let billingHistoryItem = billingHistoryItem {
            billInfoBox.isHidden = true
            paymentStatusView.isHidden = billingHistoryItem.statusString == nil
            confirmationNumberView.isHidden = billingHistoryItem.confirmationNumber == nil
        } else {
            editPaymentInfoBox.isHidden = true
        }
    }
    
    func bindViewContent() {
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentMethodImageView.rx.image).disposed(by: disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentMethodAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentMethodNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.showSelectedWalletItemNickname.not().drive(paymentMethodNicknameLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(paymentMethodButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
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
                    let shouldHideOtherTextField = control != radioControls.last
                    if shouldHideOtherTextField != self.paymentAmountTextField.isHidden {
                        if !shouldHideOtherTextField && !self.hasPrecariousOtherAmountBeenSelected {
                            // If user selects "Other", default the payment amount to $0.00. We use `hasPrecariousOtherAmountBeenSelected` to
                            // ensure this only happens once, i.e. if the user enters a custom amount, then selects another radio button,
                            // then selects "Other" again, the previously entered amount should persist.
                            self.hasPrecariousOtherAmountBeenSelected = true
                            self.paymentAmountTextField.textField.text = 0.currencyString
                            self.viewModel.paymentAmount.accept(0)
                        }
                        UIView.animate(withDuration: 0.2) {
                            self.paymentAmountTextField.isHidden = shouldHideOtherTextField
                        }
                    }
                    
                    radioControls.forEach { $0.isSelected = $0 == control }
                    
                    if let amount = amount {
                        self.paymentAmountTextField.textField.resignFirstResponder()
                        self.viewModel.paymentAmount.accept(amount)
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
        viewModel.paymentMethodFeeLabelText.asDriver()
            .drive(paymentMethodFeeLabel.rx.text)
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
                self.viewModel.paymentAmount.accept(amount)
            })
            .disposed(by: disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateDateLabel.rx.text).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateButton.rx.valueText).disposed(by: disposeBag)
        viewModel.paymentDateA11yString.asDriver().drive(paymentDateButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        // Edit Payment Detail View
        paymentStatusValueLabel.text = billingHistoryItem?.statusString?.capitalized
        confirmationNumberValueTextView.text = billingHistoryItem?.confirmationNumber
        
        footerLabel.text = viewModel.walletFooterLabelText
        
        // Sticky Footer Payment View
        viewModel.totalPaymentDisplayString.map { $0 ?? "--" }
            .drive(stickyPaymentFooterAmountLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.paymentAmountFeeFooterLabelText.drive(stickyPaymentFooterFeeLabel.rx.text).disposed(by: disposeBag)
    }
    
    func bindButtonTaps() {
        Driver.merge(paymentMethodButton.rx.touchUpInside.asDriver(),
                     paymentMethodExpiredButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
                
                FirebaseUtility.logEvent(.payment, parameters: [EventParameter(parameterName: .action, value: .switch_payment_method)])
                
                guard let miniWalletVC = UIStoryboard(name: "MiniWalletSheet", bundle: .main).instantiateInitialViewController() as? MiniWalletSheetViewController else { return }
                miniWalletVC.modalPresentationStyle = .overCurrentContext
                
                miniWalletVC.viewModel.walletItems = self.viewModel.walletItems.value!
                if let selectedItem = self.viewModel.selectedWalletItem.value {
                    miniWalletVC.viewModel.selectedWalletItem = selectedItem
                    if selectedItem.isTemporary {
                        miniWalletVC.viewModel.temporaryWalletItem = selectedItem
                    } else if selectedItem.isEditingItem {
                        miniWalletVC.viewModel.editingWalletItem = selectedItem
                    }
                }
                miniWalletVC.accountDetail = self.viewModel.accountDetail.value
                miniWalletVC.delegate = self

                self.present(miniWalletVC, animated: false, completion: nil)
            }).disposed(by: disposeBag)

        paymentDateButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            
            let calendarVC = PDTSimpleCalendarViewController()
            calendarVC.extendedLayoutIncludesOpaqueBars = true
            calendarVC.calendar = .opCo
            calendarVC.delegate = self
            calendarVC.title = NSLocalizedString("Select Payment Date", comment: "")
            calendarVC.selectedDate = self.viewModel.paymentDate.value
            
            self.navigationController?.pushViewController(calendarVC, animated: true)
        }).disposed(by: disposeBag)
        
        addBankAccountButton.rx.touchUpInside
            .do(onNext: { GoogleAnalytics.log(event: .addBankNewWallet) })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let actionSheet = UIAlertController
                    .saveToWalletActionSheet(bankOrCard: .bank, saveHandler: { [weak self] _ in
                        self?.presentPaymentusForm(bankOrCard: .bank, temporary: false)
                    }, dontSaveHandler: { [weak self] _ in
                        self?.presentPaymentusForm(bankOrCard: .bank, temporary: true)
                    })
                self.present(actionSheet, animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        addCreditCardButton.rx.touchUpInside
            .do(onNext: { GoogleAnalytics.log(event: .addCardNewWallet) })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let actionSheet = UIAlertController
                    .saveToWalletActionSheet(bankOrCard: .card, saveHandler: { [weak self] _ in
                        self?.presentPaymentusForm(bankOrCard: .card, temporary: false)
                    }, dontSaveHandler: { [weak self] _ in
                        self?.presentPaymentusForm(bankOrCard: .card, temporary: true)
                    })
                self.present(actionSheet, animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        cancelPaymentButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.onCancelPaymentPress()
        }).disposed(by: disposeBag)
    }
    
    private func presentPaymentusForm(bankOrCard: BankOrCard, temporary: Bool) {
        let paymentusVC = PaymentusFormViewController(bankOrCard: bankOrCard,
                                                      temporary: temporary,
                                                      isWalletEmpty: viewModel.walletItems.value!.isEmpty)
        paymentusVC.delegate = self
        let largeTitleNavController = LargeTitleNavigationController(rootViewController: paymentusVC)
        present(largeTitleNavController, animated: true, completion: nil)
    }
    
    private func accessibilityErrorLabel() {
        let message = paymentAmountTextField.getError()
        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard {
            switch bankOrCard {
            case .bank:
                GoogleAnalytics.log(event: .eCheckOffer)
            case .card:
                GoogleAnalytics.log(event: .cardOffer)
            }
        }
        
        FirebaseUtility.logEvent(.makePaymentNext)
        
        performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
    }
    
    func onCancelPaymentPress() {
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
                for vc in navigationController.viewControllers {
                    // Always pop back to the root billing history screen here (hence the check for viewingMoreActivity)
                    guard let dest = vc as? BillingHistoryViewController, !dest.viewModel.viewingMoreActivity else {
                        continue
                    }
                    dest.onPaymentCancel()
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

extension MakePaymentViewController: MiniWalletSheetViewControllerDelegate {
    func miniWalletSheetViewController(_ miniWalletSheetViewController: MiniWalletSheetViewController, didSelect walletItem: WalletItem) {
        viewModel.selectedWalletItem.accept(walletItem)
    }
    
    func miniWalletSheetViewControllerDidSelectAddBank(_ miniWalletSheetViewController: MiniWalletSheetViewController) {
        dismissModal()
        let actionSheet = UIAlertController
            .saveToWalletActionSheet(bankOrCard: .bank, saveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .bank, temporary: false)
            }, dontSaveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .bank, temporary: true)
            })
        present(actionSheet, animated: true, completion: nil)
    }
    
    func miniWalletSheetViewControllerDidSelectAddCard(_ miniWalletSheetViewController: MiniWalletSheetViewController) {
        dismissModal()
        let actionSheet = UIAlertController
            .saveToWalletActionSheet(bankOrCard: .card, saveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .card, temporary: false)
            }, dontSaveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .card, temporary: true)
            })
        present(actionSheet, animated: true, completion: nil)
    }
    
}

// MARK: - PaymentusFormViewControllerDelegate

extension MakePaymentViewController: PaymentusFormViewControllerDelegate {
    func didAddWalletItem(_ walletItem: WalletItem) {
        viewModel.selectedWalletItem.accept(walletItem)
        fetchData(initialFetch: false)
        if !walletItem.isTemporary {
            GoogleAnalytics.log(event: walletItem.bankOrCard == .bank ? .eCheckAddNewWallet : .cardAddNewWallet, dimensions: [.otpEnabled: walletItem.isDefault ? "enabled" : "disabled"])
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
        return viewModel.shouldCalendarDateBeEnabled(date)
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return }
        viewModel.paymentDate.accept(opCoTimeDate.isInToday(calendar: .opCo) ? .now : opCoTimeDate)
    }
}
