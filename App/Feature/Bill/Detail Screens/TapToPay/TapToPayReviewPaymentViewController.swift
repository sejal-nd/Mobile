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
    
     var viewModel: HomeBillCardViewModel!
     var bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
