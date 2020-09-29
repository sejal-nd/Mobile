//
//  TapToPayReviewPaymentViewController.swift
//  Mobile
//
//  Created by Adarsh Maurya on 07/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TapToPayReviewPaymentViewController: UIViewController {
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    @IBOutlet weak var dueAmountDescriptionLabel: UILabel!
    
    @IBOutlet weak var activeSeveranceTextContainer: UIView!
    @IBOutlet weak var youArePayingLabel: UILabel!
    @IBOutlet weak var paymentsAssociatedTextLabel: UILabel!
    @IBOutlet weak var submitDescriptionLabel: UILabel!
    @IBOutlet weak var termsNConditionsButton: UIButton!
    
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
    
    @IBOutlet weak var bankAccount: ButtonControl!
    @IBOutlet weak var creditDebitCard: ButtonControl!
    @IBOutlet weak var bankAccountTitleLabel: UILabel!
    @IBOutlet weak var creditCardTitleLabel: UILabel!
    @IBOutlet weak var paymentMethodContainer: UIView!
    @IBOutlet weak var choosePaymentMethodContainer: UIView!
    @IBOutlet weak var cashOnlyPaymentMethodLabel: UILabel!
    @IBOutlet weak var cashOnlyChoosePaymentLabel: UILabel!
    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentMethodNicknameLabel: UILabel!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stickyPaymentFooterView: StickyFooterView!
    
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentDateTitleLabel: UILabel!
    @IBOutlet weak var paymentDateEditButton: UIButton!
    
    @IBOutlet weak var paymentDatePastDueLabel: UILabel!
    @IBOutlet weak var sameDayPaymentWarningLabel: UILabel!
    
    @IBOutlet weak var submitButton: PrimaryButton!
    @IBOutlet weak var bankAccountNotAvailableBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var bankAccountNotAvailable: NSLayoutConstraint!
    
    var viewModel: TapToPayViewModel!
    var accountDetail: AccountDetail! // Passed in from presenting view
    var billingHistoryItem: BillingHistoryItem? // Passed in from Billing History, indicates we are modifying a payment
    
    var bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = TapToPayViewModel(walletService: ServiceFactory.createWalletService(),
                                      paymentService: ServiceFactory.createPaymentService(),
                                      accountDetail: accountDetail,
                                      billingHistoryItem: billingHistoryItem)
        
        addCloseButton()
        title = NSLocalizedString("Review Payment", comment: "")
        
        youArePayingLabel.textColor = .deepGray
        youArePayingLabel.font = SystemFont.regular.of(size: 13)
        youArePayingLabel.text = NSLocalizedString("You’re Paying", comment: "")
        
        amountLabel.textColor = .deepGray
        amountLabel.font = SystemFont.semibold.of(size: 22)
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(size: 12)
        
        addAdditionaRecipientButton.setTitleColor(.deepGray, for: .normal)
        addAdditionaRecipientButton.titleLabel?.font = SystemFont.medium.of(size: 16)
        
        paymentsAssociatedTextLabel.textColor = .deepGray
        paymentsAssociatedTextLabel.font = SystemFont.regular.of(size: 12)
        
        submitDescriptionLabel.textColor = .deepGray
        submitDescriptionLabel.font = SystemFont.regular.of(size: 12)
        submitDescriptionLabel.text = NSLocalizedString("By tapping Submit, you agree to the payment", comment: "")
        
        termsNConditionsButton.setTitleColor(.actionBlue, for: .normal)
        termsNConditionsButton.titleLabel?.text = NSLocalizedString("Terms & Conditions.", comment: "")
        termsNConditionsButton.titleLabel?.font = SystemFont.semibold.of(size: 12)
        
        paymentMethodAccountNumberLabel.textColor = .deepGray
        paymentMethodAccountNumberLabel.font = SystemFont.regular.of(size: 16)
        
        paymentMethodNicknameLabel.textColor = .middleGray
        paymentMethodNicknameLabel.font = SystemFont.regular.of(size: 12)
        
        bankAccount.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        bankAccount.backgroundColorOnPress = .actionBlue
        bankAccount.accessibilityLabel = NSLocalizedString("Bank Account", comment: "")
        
        bankAccountTitleLabel.text = NSLocalizedString("Bank Account", comment: "")
        bankAccountTitleLabel.textColor = .actionBlue
        bankAccountTitleLabel.font = SystemFont.semibold.of(size: 12)
        
        creditDebitCard.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        creditDebitCard.backgroundColorOnPress = .actionBlue
        creditDebitCard.accessibilityLabel = NSLocalizedString("Credit/Debit Card", comment: "")
        
        creditCardTitleLabel.text = NSLocalizedString("Credit/Debit Card", comment: "")
        creditCardTitleLabel.textColor = .actionBlue
        creditCardTitleLabel.font = SystemFont.semibold.of(size: 12)
        
        paymentDateLabel.textColor = .deepGray
        paymentDateLabel.font = SystemFont.semibold.of(size: 16)
        
        paymentDatePastDueLabel.textColor = .deepGray
        paymentDatePastDueLabel.font = SystemFont.regular.of(size: 12)
        paymentDatePastDueLabel.text = NSLocalizedString("Past due payments cannot be scheduled for a later date.", comment: "")
        
        sameDayPaymentWarningLabel.textColor = .deepGray
        sameDayPaymentWarningLabel.font = SystemFont.regular.of(size: 12)
        sameDayPaymentWarningLabel.text = NSLocalizedString("Same-day payments cannot be edited or canceled after submission.", comment: "")
        
        viewModel.fetchData(initialFetch: true, onSuccess: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }, onError: { [weak self] in
                guard let self = self else { return }
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
        })
        
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentMethodImageView.rx.image).disposed(by: bag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentMethodAccountNumberLabel.rx.text).disposed(by: bag)
        viewModel.selectedWalletItemNickname.drive(paymentMethodNicknameLabel.rx.text).disposed(by: bag)
        viewModel.showSelectedWalletItemNickname.not().drive(paymentMethodNicknameLabel.rx.isHidden).disposed(by: bag)
        
        viewModel.isCashOnlyUser.not().drive(cashOnlyPaymentMethodLabel.rx.isHidden).disposed(by: bag)
        viewModel.isCashOnlyUser.not().drive(cashOnlyChoosePaymentLabel.rx.isHidden).disposed(by: bag)
        viewModel.isCashOnlyUser.not().drive(bankAccount.rx.isEnabled).disposed(by: bag)
        viewModel.isCashOnlyUser.not().drive(onNext: { [weak self] _ in
            self?.bankAccountNotAvailable.constant = 0
            self?.bankAccountNotAvailableBottomContraint.constant = 0
        }).disposed(by: bag)
        
        
        viewModel.hasWalletItems.drive(choosePaymentMethodContainer.rx.isHidden).disposed(by: bag)
        viewModel.hasWalletItems.not().drive(paymentMethodContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: bag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: bag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateLabel.rx.text).disposed(by: bag)
        viewModel.shouldShowPastDueLabel.not().drive(paymentDatePastDueLabel.rx.isHidden).disposed(by: bag)
        viewModel.enablePaymentDate.drive(paymentDateEditButton.rx.isEnabled).disposed(by: bag)
        
        viewModel.reviewPaymentSubmitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: bag)
        
        viewModel.shouldShowContent.drive(onNext: { [weak self] shouldShow in
            self?.stickyPaymentFooterView.isHidden = !shouldShow
        }).disposed(by: bag)
        
        configureAdditionalRecipientsView()
    }
    
    
    func configureAdditionalRecipientsView() {
        
        viewModel.totalPaymentDisplayString.drive(amountLabel.rx.text).disposed(by: bag)
        viewModel.convenienceDisplayString.drive(convenienceFeeLabel.rx.text).disposed(by: bag)
        viewModel.dueAmountDescriptionText.drive(dueAmountDescriptionLabel.rx.attributedText).disposed(by: bag)
        
        // Active Severance Label
        viewModel.isActiveSeveranceUser.not().drive(activeSeveranceTextContainer.rx.isHidden).disposed(by: bag)
        
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
        }).disposed(by: self.bag)
        
        alternateEmailTextField.textField.rx.text.orEmpty.bind(to: viewModel.emailAddress).disposed(by: bag)
        
        alternateEmailTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                // If we displayed an inline error, clear it when user edits the text
                if self.alternateEmailTextField.errorState {
                    self.alternateEmailTextField.setError(nil)
                }
            }).disposed(by: bag)
        
        alternateEmailTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { [weak self] in
                self?.alternateNumberTextField.textField.becomeFirstResponder()
            }).disposed(by: bag)
        
        alternateNumberTextField.placeholder = NSLocalizedString("Phone Number (Optional)",
                                                                 comment: "")
        alternateNumberTextField.textField.autocorrectionType = .no
        alternateNumberTextField.setKeyboardType(.phonePad)
        alternateNumberTextField.textField.delegate = self
        alternateNumberTextField.textField.isShowingAccessory = true
        
        alternateNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: bag)
        
        alternateNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let self = self else { return }
                if !phoneNumber.isEmpty && !hasTenDigits {
                    self.alternateNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                }
            }).disposed(by: bag)
        
        alternateNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.alternateNumberTextField.setError(nil)
        }).disposed(by: bag)
        
    }
    
    @IBAction func termsConditionPress(_ sender: Any) {
        FirebaseUtility.logEvent(.payment, parameters: [EventParameter(parameterName: .action, value: .view_terms)])
        
        let url = URL(string: "https://ipn2.paymentus.com/rotp/www/terms-and-conditions-exln.html")!
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""), url: url)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    @IBAction func collapseExpandAdditionalRecipients(_ sender: Any) {
        
        // Animate expand/collapse
        self.collapseButton.isSelected = !self.collapseButton.isSelected
        self.alternateContactDivider.isHidden = self.collapseButton.isSelected ? false : true
        self.view.layoutIfNeeded()
        self.alternateEmailNumberView.isHidden = self.collapseButton.isSelected ? false : true
    }
}

extension TapToPayReviewPaymentViewController: UITextFieldDelegate {
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
