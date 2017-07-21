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
    var accountDetail: AccountDetail! // Passed from BillViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PaymentViewModel(walletService: ServiceFactory.createWalletService(), paymentService: ServiceFactory.createPaymentService(), accountDetail: self.accountDetail, addBankFormViewModel: self.addBankFormView.viewModel, addCardFormViewModel: self.addCardFormView.viewModel)
        
        view.backgroundColor = .softGray
        
        // Put white background on stack view
        let bg = UIView(frame: stackView.bounds)
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bg.backgroundColor = .white
        stackView.addSubview(bg)
        stackView.sendSubview(toBack: bg)
        
        title = NSLocalizedString("Make a Payment", comment: "")
        
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
        viewModel.makePaymentNextButtonEnabled.drive(nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        addBankFormView.delegate = self
        addBankFormView.viewModel.paymentWorkflow.value = true
        addCardFormView.delegate = self
        addCardFormView.viewModel.paymentWorkflow.value = true
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
        paymentAccountNicknameLabel.textColor = .middleGray
        
        cvvTextField.textField.placeholder = NSLocalizedString("CVV2*", comment: "")
        cvvTextField.textField.delegate = self
        cvvTextField.textField.keyboardType = .numberPad
        cvvTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.cvv.value.isEmpty {
                self.viewModel.cvvIsCorrectLength.single().subscribe(onNext: { valid in
                    if !valid {
                        self.cvvTextField.setError(NSLocalizedString("Must be 3 or 4 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        cvvTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.cvvTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        cvvTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        amountDueTextLabel.text = NSLocalizedString("Amount Due", comment: "")
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueValueLabel.textColor = .blackText
        amountDueValueLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        paymentAmountFeeLabel.textColor = .blackText
        paymentAmountFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentAmountTextField.textField.placeholder = NSLocalizedString("Payment Amount*", comment: "")
        paymentAmountTextField.textField.keyboardType = .decimalPad
        paymentAmountTextField.textField.delegate = self
//        paymentAmountTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
//            self.viewModel.paymentAmountErrorMessage.asObservable().single().subscribe(onNext: { errorMessage in
//                self.paymentAmountTextField.setError(errorMessage)
//            }).addDisposableTo(self.disposeBag)
//        }).addDisposableTo(disposeBag)
//        paymentAmountTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
//            self.paymentAmountTextField.setError(nil)
//        }).addDisposableTo(disposeBag)
        viewModel.paymentAmountErrorMessage.asObservable().subscribe(onNext: { errorMessage in
            self.paymentAmountTextField.setError(errorMessage)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(self.disposeBag)
        
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
        
        addCreditCardFeeLabel.textColor = .blackText
        addCreditCardFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        switch Environment.sharedInstance.opco {
        case .comEd, .peco:
            addCreditCardFeeLabel.text = NSLocalizedString("Your payment includes a " + accountDetail.billingInfo.convenienceFee!.currencyString! + " convenience fee.", comment: "")
            break
        case .bge:
            let feeString = String(format: "Your payment includes a %@ convenience fee. ", accountDetail.isResidential ?
                accountDetail.billingInfo.residentialFee!.currencyString! : accountDetail.billingInfo.commercialFee!.percentString!)
            addCreditCardFeeLabel.text = NSLocalizedString(feeString, comment: "")
            break
        }
        addCreditCardButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        addCreditCardButton.backgroundColorOnPress = .softGray
        
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
        viewModel.fetchWalletItems(onSuccess: nil, onError: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += cvvTextField.getError()
        message += paymentAmountTextField.getError()
        self.nextButton.accessibilityLabel = NSLocalizedString(message, comment: "")
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
        viewModel.isFetching.asDriver().map(!).drive(loadingIndicator.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowContent.map(!).drive(scrollView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowContent.map(!).drive(stickyPaymentFooterView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Inline Bank/Card
        viewModel.inlineBank.asDriver().map(!).drive(addBankContainerView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.inlineCard.asDriver().map(!).drive(addCardContainerView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowInlinePaymentDivider.map(!).drive(inlinePaymentDividerLine.rx.isHidden).addDisposableTo(disposeBag)
        
        // Active Severance Label
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceLabel.rx.isHidden).addDisposableTo(disposeBag)
        
        // Cash Only Bank Accounts Unavailable Label
        viewModel.isCashOnlyUser.map(!).drive(bankAccountsUnavailableLabel.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Account
        viewModel.shouldShowPaymentAccountView.map(!).drive(paymentAccountView.rx.isHidden).addDisposableTo(disposeBag)
        
        // CVV (BGE credit card only)
        viewModel.shouldShowCvvTextField.map(!).drive(cvvView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Amount Text Field
        viewModel.shouldShowPaymentAmountTextField.map(!).drive(paymentAmountView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.shouldShowPaymentDateView.map(!).drive(paymentDateView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDate.drive(paymentDateButtonView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDate.map(!).drive(paymentDateFixedDateLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDatePastDue.map(!).drive(paymentDateFixedDatePastDueLabel.rx.isHidden).addDisposableTo(disposeBag)
        
        // Add bank/credit card empty wallet state
        viewModel.shouldShowAddBankAccount.map(!).drive(addBankAccountView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowAddCreditCard.map(!).drive(addCreditCardView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Bill Matrix
        viewModel.shouldShowBillMatrixView.map(!).drive(billMatrixView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Wallet empty state info footer
        viewModel.shouldShowWalletFooterView.map(!).drive(walletFooterView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowWalletFooterView.drive(walletFooterSpacerView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Sticky Footer
        viewModel.shouldShowStickyFooterView.drive(onNext: { shouldShow in
            self.stickyPaymentFooterHeightConstraint.constant = shouldShow ? 80 : 0
            // For some reason, just hiding stickyPaymentFooterView was not enough to hide the label...
            self.stickyPaymentFooterTextContainer.isHidden = !shouldShow
        }).addDisposableTo(disposeBag)
    }
    
    func bindViewContent() {
        // Inline payment
        viewModel.oneTouchPayDescriptionLabelText.drive(addBankFormView.oneTouchPayDescriptionLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.oneTouchPayDescriptionLabelText.drive(addCardFormView.oneTouchPayDescriptionLabel.rx.text).addDisposableTo(disposeBag)
        
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountAccountNumberLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).addDisposableTo(disposeBag)
        
        // CVV (BGE credit card only)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).addDisposableTo(disposeBag)
        
        // Amount Due
        viewModel.amountDueCurrencyString.asDriver().drive(amountDueValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Amount Text Field
        viewModel.paymentAmountFeeLabelText.asDriver().drive(paymentAmountFeeLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.paymentAmount.asDriver().drive(paymentAmountTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
        paymentAmountTextField.textField.rx.text.orEmpty.bind(to: viewModel.paymentAmount).addDisposableTo(disposeBag)
        paymentAmountTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.viewModel.formatPaymentAmount()
        }).addDisposableTo(disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateDateLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateButton.label.rx.text).addDisposableTo(disposeBag)
        viewModel.paymentDateString.asDriver().drive(paymentDateFixedDateLabel.rx.text).addDisposableTo(disposeBag)
        
        // Wallet Footer Label
        viewModel.walletFooterLabelText.drive(walletFooterLabel.rx.text).addDisposableTo(disposeBag)
        
        // Sticky Footer Payment View
        viewModel.totalPaymentDisplayString.map { String(format: NSLocalizedString("Total Payment: %@", comment: ""), $0) }.drive(stickyPaymentFooterPaymentLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.paymentAmountFeeFooterLabelText.drive(stickyPaymentFooterFeeLabel.rx.text).addDisposableTo(disposeBag)
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
            self.navigationController?.pushViewController(miniWalletVC, animated: true)
        }).addDisposableTo(disposeBag)
        
        paymentDateButton.rx.touchUpInside.subscribe(onNext: {
            self.view.endEditing(true)
            
            let calendarVC = PDTSimpleCalendarViewController()
            calendarVC.delegate = self
            calendarVC.title = NSLocalizedString("Select Payment Date", comment: "")
            calendarVC.selectedDate = self.viewModel.paymentDate.value
            
            self.navigationController?.pushViewController(calendarVC, animated: true)
        }).addDisposableTo(disposeBag)
        
        addBankAccountButton.rx.touchUpInside.subscribe(onNext: {
            self.viewModel.inlineBank.value = true
        }).addDisposableTo(disposeBag)
        
        addCreditCardButton.rx.touchUpInside.subscribe(onNext: {
            self.viewModel.inlineCard.value = true
        }).addDisposableTo(disposeBag)
        
        privacyPolicyButton.rx.touchUpInside.asDriver().drive(onNext: onPrivacyPolicyPress).addDisposableTo(disposeBag)
    }
    
    func onNextPress() {
        self.view.endEditing(true)
        performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
    }
    
    func onPrivacyPolicyPress() {
        let tacModal = WebViewController(title: NSLocalizedString("Privacy Policy", comment: ""),
                                         url: URL(string:"https://webpayments.billmatrix.com/HTML/privacy_notice_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
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
            
            return (CharacterSet.decimalDigits.isSuperset(of: characterSet) || containsDecimal) && newString.characters.count <= 7 && !containsBackslash
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
            if let walletItem = viewModel.selectedWalletItem.value {
                if walletItem.bankOrCard == .card {
                    let todayPlus90 = Calendar.current.date(byAdding: .day, value: 90, to: today)!
                    return date >= today && date <= todayPlus90
                } else {
                    let todayPlus180 = Calendar.current.date(byAdding: .day, value: 180, to: today)!
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
