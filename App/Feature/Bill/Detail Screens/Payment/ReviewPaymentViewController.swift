//
//  ReviewPaymentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 7/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class ReviewPaymentViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    var viewModel: PaymentViewModel! // Passed from MakePaymentViewController

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var activeSeveranceLabel: UILabel!
    @IBOutlet weak var overpaymentLabel: UILabel!
    
    @IBOutlet weak var paymentMethodTextLabel: UILabel!
    @IBOutlet weak var paymentMethodA11yView: UIView!
    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodMaskedAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentMethodNicknameLabel: UILabel!
    
    // -- Receipt View -- //
    @IBOutlet weak var receiptView: UIView!
    
    // -- Additional Recipients View -- //
    @IBOutlet weak var addAdditionalRecipients: UIView!
    @IBOutlet weak var collapseButton: UIButton!
    @IBOutlet weak var alternateEmailNumberView: UIView!
    @IBOutlet weak var alternateEmailTextField: FloatLabelTextField!
    @IBOutlet weak var alternateNumberTextField: FloatLabelTextField!
    @IBOutlet weak var alternateViewTextView: UITextView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var alternateContactDivider: UIView!
    @IBOutlet weak var addAdditionaRecipientButton: UIButton!
    
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    @IBOutlet weak var dueDateTextLabel: UILabel!
    @IBOutlet weak var dueDateValueLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeView: UIView!
    @IBOutlet weak var paymentAmountTextLabel: UILabel!
    @IBOutlet weak var paymentAmountValueLabel: UILabel!
    @IBOutlet weak var convenienceFeeTextLabel: UILabel!
    @IBOutlet weak var convenienceFeeValueLabel: UILabel!
    
    @IBOutlet weak var cardOverpayingView: UIView!
    @IBOutlet weak var cardOverpayingTextLabel: UILabel!
    @IBOutlet weak var cardOverpayingValueLabel: UILabel!
    
    @IBOutlet weak var bankOverpayingView: UIView!
    @IBOutlet weak var bankOverpayingTextLabel: UILabel!
    @IBOutlet weak var bankOverpayingValueLabel: UILabel!
    
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateValueLabel: UILabel!
    @IBOutlet weak var totalPaymentTextLabel: UILabel!
    @IBOutlet weak var totalPaymentValueLabel: UILabel!
    // ------------------ //
    
    @IBOutlet weak var termsConditionsCheckbox: Checkbox!
    @IBOutlet weak var termsConditionsCheckboxLabel: UILabel!
    @IBOutlet weak var termsConditionsButton: UIButton!
    
    @IBOutlet weak var overpayingCheckboxView: UIView!
    @IBOutlet weak var overpayingCheckbox: Checkbox!
    @IBOutlet weak var overpayingCheckboxLabel: UILabel!
    
    @IBOutlet weak var activeSeveranceCheckboxView: UIView!
    @IBOutlet weak var activeSeveranceCheckbox: Checkbox!
    @IBOutlet weak var activeSeveranceCheckboxLabel: UILabel!
    
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var submitPaymentButton: PrimaryButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Review Payment", comment: "")
        
        viewModel.reviewPaymentSubmitButtonEnabled.drive(submitPaymentButton.rx.isEnabled).disposed(by: disposeBag)
        
        activeSeveranceLabel.textColor = .deepGray
        activeSeveranceLabel.font = SystemFont.regular.of(textStyle: .headline)
        activeSeveranceLabel.text = NSLocalizedString("Due to the status of this account, this payment cannot be edited or deleted once it is submitted.", comment: "")
        activeSeveranceLabel.setLineHeight(lineHeight: 24)
        
        overpaymentLabel.textColor = .deepGray
        overpaymentLabel.font = SystemFont.regular.of(textStyle: .headline)
        overpaymentLabel.text = NSLocalizedString("You are scheduling a payment that may result in overpaying your total amount due.", comment: "")
        overpaymentLabel.setLineHeight(lineHeight: 24)
        
        paymentMethodTextLabel.textColor = .deepGray
        paymentMethodTextLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentMethodTextLabel.text = NSLocalizedString("Payment Method", comment: "")
        paymentMethodMaskedAccountNumberLabel.textColor = .deepGray
        paymentMethodMaskedAccountNumberLabel.font = SystemFont.regular.of(textStyle: .callout)
        paymentMethodNicknameLabel.textColor = .middleGray
        paymentMethodNicknameLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        receiptView.layer.borderWidth = 1
        receiptView.layer.borderColor = UIColor.accentGray.cgColor
        
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueTextLabel.text = NSLocalizedString("Total Amount Due", comment: "")
        amountDueValueLabel.textColor = .deepGray
        amountDueValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateTextLabel.textColor = .deepGray
        dueDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateTextLabel.text = NSLocalizedString("Due Date", comment: "")
        dueDateValueLabel.textColor = .deepGray
        dueDateValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentAmountTextLabel.textColor = .deepGray
        paymentAmountTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountTextLabel.text = NSLocalizedString("Payment Amount", comment: "")
        paymentAmountValueLabel.textColor = .deepGray
        paymentAmountValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeTextLabel.textColor = .deepGray
        convenienceFeeTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeTextLabel.text = NSLocalizedString("Convenience Fee", comment: "")
        convenienceFeeValueLabel.textColor = .deepGray
        convenienceFeeValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        cardOverpayingTextLabel.textColor = .deepGray
        cardOverpayingTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        cardOverpayingTextLabel.text = NSLocalizedString("Overpaying", comment: "")
        cardOverpayingValueLabel.textColor = .deepGray
        cardOverpayingValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        bankOverpayingTextLabel.textColor = .deepGray
        bankOverpayingTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        bankOverpayingTextLabel.text = NSLocalizedString("Overpaying", comment: "")
        bankOverpayingValueLabel.textColor = .deepGray
        bankOverpayingValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentDateTextLabel.textColor = .deepGray
        paymentDateTextLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateValueLabel.textColor = .deepGray
        paymentDateValueLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        totalPaymentTextLabel.textColor = .deepGray
        totalPaymentTextLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        totalPaymentValueLabel.textColor = .deepGray
        totalPaymentValueLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        
        termsConditionsCheckboxLabel.textColor = .deepGray
        termsConditionsCheckboxLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        termsConditionsCheckboxLabel.text = NSLocalizedString("Yes, I have read, understand, and agree to the terms and conditions provided below:", comment: "")
        termsConditionsButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
        termsConditionsButton.setTitleColor(.actionBlue, for: .normal)
        termsConditionsButton.setTitle(NSLocalizedString("View terms and conditions", comment: ""), for: .normal)
        termsConditionsButton.accessibilityLabel = termsConditionsButton.titleLabel?.text
        termsConditionsCheckboxLabel.isAccessibilityElement = false
        termsConditionsCheckbox.accessibilityLabel = termsConditionsCheckboxLabel.text!
        
        overpayingCheckboxLabel.textColor = .deepGray
        overpayingCheckboxLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        overpayingCheckboxLabel.text = NSLocalizedString("Yes, I acknowledge I am scheduling a payment for more than is currently due on my account.", comment: "")
        overpayingCheckboxLabel.isAccessibilityElement = false
        overpayingCheckbox.accessibilityLabel = overpayingCheckboxLabel.text!
        
        activeSeveranceCheckboxLabel.textColor = .deepGray
        activeSeveranceCheckboxLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        activeSeveranceCheckboxLabel.text = NSLocalizedString("I acknowledge I will not be able to edit or delete this payment once submitted.", comment: "")
        activeSeveranceCheckboxLabel.isAccessibilityElement = false
        activeSeveranceCheckbox.accessibilityLabel = activeSeveranceCheckboxLabel.text!
        
        footerLabel.textColor = .deepGray
        footerLabel.font = SystemFont.regular.of(textStyle: .footnote)
        let reviewPaymentFooterLabelText = viewModel.reviewPaymentFooterLabelText
        footerLabel.text = reviewPaymentFooterLabelText
        
        // Hide additional recipient view for edit payment flow
        if let _ = viewModel.billingHistoryItem {
            addAdditionalRecipients.isHidden = true
            alternateEmailNumberView.isHidden = true
            alternateContactDivider.isHidden = true
        } else {
            configureAdditionalRecipientsView()
        }
        
        bindViewHiding()
        bindViewContent()
    }
    
    func configureAdditionalRecipientsView() {
        stackView.setCustomSpacing(20, after: receiptView)
        stackView.setCustomSpacing(20, after: addAdditionalRecipients)
        stackView.setCustomSpacing(47, after: alternateContactDivider)
        
        collapseButton.isSelected = false
        collapseButton.setImage(#imageLiteral(resourceName: "ic_caret_down"), for: .normal)
        collapseButton.setImage(#imageLiteral(resourceName: "ic_caret_up"), for: .selected)
        
        alternateEmailNumberView.isHidden = true
        alternateEmailNumberView.backgroundColor = .softGray
        
        alternateViewTextView.backgroundColor = .softGray
        alternateViewTextView.textColor = .deepGray
        alternateViewTextView.font = SystemFont.regular.of(textStyle: .callout)
        alternateViewTextView.text = NSLocalizedString("A confirmation will be sent to the email address associated with your My Account. If you'd like to send this payment confirmation to an additional email or via text message, add the recipients below. Standard messaging rates apply.", comment: "")
        
        addAdditionaRecipientButton.setTitleColor(.deepGray, for: .normal)
        addAdditionaRecipientButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        alternateEmailTextField.placeholder = NSLocalizedString("Email Address (Optional)",
                                                                comment: "")
        alternateEmailTextField.textField.autocorrectionType = .no
        alternateEmailTextField.textField.returnKeyType = .next
        alternateEmailTextField.setKeyboardType(.emailAddress)
        alternateEmailTextField.textField.isShowingAccessory = true
        alternateEmailTextField.setError(nil)
        alternateEmailTextField.textField.delegate = self
        
        viewModel.emailIsValid.drive(onNext: { [weak self] errorMessage in
            self?.alternateEmailTextField.setError(errorMessage)
        }).disposed(by: self.disposeBag)
        
        alternateEmailTextField.textField.rx.text.orEmpty.bind(to: viewModel.emailAddress).disposed(by: disposeBag)
        
        alternateEmailTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                // If we displayed an inline error, clear it when user edits the text
                if self.alternateEmailTextField.errorState {
                    self.alternateEmailTextField.setError(nil)
                }
            }).disposed(by: disposeBag)
        
        alternateEmailTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { [weak self] in
                self?.alternateNumberTextField.textField.becomeFirstResponder()
            }).disposed(by: disposeBag)
        
        alternateNumberTextField.placeholder = NSLocalizedString("Phone Number (Optional)",
                                                                 comment: "")
        alternateNumberTextField.textField.autocorrectionType = .no
        alternateNumberTextField.setKeyboardType(.phonePad)
        alternateNumberTextField.textField.delegate = self
        alternateNumberTextField.textField.isShowingAccessory = true
        
        alternateNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        
        alternateNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let self = self else { return }
                if !phoneNumber.isEmpty && !hasTenDigits {
                    self.alternateNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                }
            }).disposed(by: disposeBag)
        
        alternateNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.alternateNumberTextField.setError(nil)
        }).disposed(by: disposeBag)
    }
    
    func bindViewHiding() {
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpaying.map(!).drive(overpaymentLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpayingCard.map(!).drive(cardOverpayingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpayingBank.map(!).drive(bankOverpayingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.reviewPaymentShouldShowConvenienceFeeBox.map(!).drive(convenienceFeeView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpaying.map(!).drive(overpayingCheckboxView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceCheckboxView.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindViewContent() {
        // Payment Method
        viewModel.selectedWalletItemImage.drive(paymentMethodImageView.rx.image).disposed(by: disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentMethodMaskedAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentMethodNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(paymentMethodA11yView.rx.accessibilityLabel).disposed(by: disposeBag)
        
        // Amount Due
        viewModel.amountDueCurrencyString.asDriver().drive(amountDueValueLabel.rx.text).disposed(by: disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateValueLabel.rx.text).disposed(by: disposeBag)
        
        // Payment Amount
        viewModel.paymentAmountString.asDriver().drive(paymentAmountValueLabel.rx.text).disposed(by: disposeBag)
        
        // Overpaying
        viewModel.overpayingValueDisplayString.drive(cardOverpayingValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.overpayingValueDisplayString.drive(bankOverpayingValueLabel.rx.text).disposed(by: disposeBag)
        
        // Convenience Fee
        convenienceFeeValueLabel.text = viewModel.convenienceFee.currencyString
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateValueLabel.rx.text).disposed(by: disposeBag)
        
        // Total Payment
        viewModel.totalPaymentLabelText.drive(totalPaymentTextLabel.rx.text).disposed(by: disposeBag)
        viewModel.totalPaymentDisplayString.drive(totalPaymentValueLabel.rx.text).disposed(by: disposeBag)
        
        // Switches
        termsConditionsCheckbox.rx.isChecked.bind(to: viewModel.termsConditionsSwitchValue).disposed(by: disposeBag)
        overpayingCheckbox.rx.isChecked.bind(to: viewModel.overpayingSwitchValue).disposed(by: disposeBag)
        activeSeveranceCheckbox.rx.isChecked.bind(to: viewModel.activeSeveranceSwitchValue).disposed(by: disposeBag)
    }
    
    @IBAction func onSubmitPress() {
        LoadingView.show()
        
        if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard, let temp = viewModel.selectedWalletItem.value?.isTemporary {
            switch bankOrCard {
            case .bank:
                GoogleAnalytics.log(event: .eCheckSubmit, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
            case .card:
                GoogleAnalytics.log(event: .cardSubmit, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
            }
        }
        
        FirebaseUtility.logEvent(.reviewPaymentSubmit)
        FirebaseUtility.logEvent(.payment(parameters: [.submit]))
        
        let handleError = { [weak self] (error: NetworkingError) in
            guard let self = self else { return }
            
            LoadingView.hide()
            let paymentusAlertVC = UIAlertController.paymentusErrorAlertController(
                forError: error,
                walletItem: self.viewModel.selectedWalletItem.value!,
                okHandler: { [weak self] _ in
                    guard let self = self else { return }
                    if error == .walletItemIdTimeout {
                        guard let navCtl = self.navigationController else { return }
                        
                        let makePaymentVC = UIStoryboard(name: "Payment", bundle: nil)
                            .instantiateInitialViewController() as! MakePaymentViewController
                        makePaymentVC.accountDetail = self.viewModel.accountDetail.value
                        navCtl.viewControllers = [navCtl.viewControllers.first!, makePaymentVC]
                    }
                },
                callHandler: { _ in
                    UIApplication.shared.openPhoneNumberIfCan(self.viewModel.errorPhoneNumber)
                }
            )
            self.present(paymentusAlertVC, animated: true, completion: nil)
        }
        
        if viewModel.paymentId.value != nil { // Modify
            viewModel.modifyPayment(onSuccess: { [weak self] in
                LoadingView.hide()
                
                FirebaseUtility.logEvent(.paymentNetworkComplete)
                
                if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard {
                    switch bankOrCard {
                    case .bank:
                        FirebaseUtility.logEvent(.payment(parameters: [.bank_complete]))
                    case .card:
                        FirebaseUtility.logEvent(.payment(parameters: [.card_complete]))
                    }
                }
                
                self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
            }, onError: { error in
                handleError(error)
            })
        } else { // Schedule
            viewModel.schedulePayment(onDuplicate: { [weak self] (errTitle, errMessage) in
                LoadingView.hide()
                let alertVc = UIAlertController(title: errTitle, message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
                }, onSuccess: { [weak self] in
                    LoadingView.hide()
                    
                    FirebaseUtility.logEvent(.paymentNetworkComplete)
                                        
                    if let viewModel = self?.viewModel,
                        viewModel.billingHistoryItem == nil {
                        var contactType = PaymentParameter.AlternateContact.none
                        if !viewModel.emailAddress.value.isEmpty &&
                            !viewModel.phoneNumber.value.isEmpty {
                            contactType = .both
                        } else if !viewModel.emailAddress.value.isEmpty {
                            contactType = .email
                        } else if !viewModel.phoneNumber.value.isEmpty {
                            contactType = .text
                        } else {
                            contactType = .none
                        }
                                                
                        FirebaseUtility.logEvent(.payment(parameters: [.alternateContact(contactType)]))
                    }
                    
                    if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard {
                        let temp = self?.viewModel.selectedWalletItem.value?.isTemporary ?? false
                        switch bankOrCard {
                        case .bank:
                            GoogleAnalytics.log(event: .eCheckComplete, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
                            FirebaseUtility.logEvent(.payment(parameters: [.bank_complete]))
                        case .card:
                            GoogleAnalytics.log(event: .cardComplete, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
                            FirebaseUtility.logEvent(.payment(parameters: [.card_complete]))
                        }
                    }
                    
                    self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
                }, onError: { [weak self] error in
                    if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard {
                        let temp = self?.viewModel.selectedWalletItem.value?.isTemporary ?? false
                        switch bankOrCard {
                        case .bank:
                            GoogleAnalytics.log(event: .eCheckError, dimensions: [
                                .errorCode: error.title ,
                                .paymentTempWalletItem: temp ? "true" : "false"
                            ])
                        case .card:
                            GoogleAnalytics.log(event: .cardError, dimensions: [
                                .errorCode: error.title,
                                .paymentTempWalletItem: temp ? "true" : "false"
                            ])
                        }
                    }
                    handleError(error)
            })
        }
    }
    
    @IBAction func onTermsConditionsPress() {
        FirebaseUtility.logEvent(.payment(parameters: [.view_terms]))
        
        let url = URL(string: "https://ipn2.paymentus.com/rotp/www/terms-and-conditions-exln.html")!
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""), url: url)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PaymentConfirmationViewController {
            vc.presentingNavController = navigationController
            vc.viewModel = viewModel
        }
    }

    @IBAction func collapseExpandAdditionalRecipients(_ sender: Any) {
        self.collapseButton.isSelected = !self.collapseButton.isSelected
        self.alternateContactDivider.isHidden = self.collapseButton.isSelected ? true : false
        
        // Animate expand/collapse
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.view.layoutIfNeeded()
            self?.alternateEmailNumberView.isHidden = (self?.collapseButton.isSelected ?? false) ? false : true
        }
    }
}

extension ReviewPaymentViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == alternateEmailTextField.textField && (string == " ") {
            return false
        }
        
        if textField == alternateNumberTextField.textField {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 10 {
                return false
            }
            
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if length - index > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            
            textField.sendActions(for: .valueChanged) // Send rx events
            
            return false
        }
        
        return true
    }
}
