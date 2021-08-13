//
//  ForgotUsernameViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ForgotUsernameViewController: KeyboardAvoidingStickyFooterViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    
    @IBOutlet weak var identifierContainerView: UIView!
    @IBOutlet weak var identifierDescriptionLabel: UILabel!
    @IBOutlet weak var identifierTextField: FloatLabelTextField!
    
    @IBOutlet weak var accountNumberContainerView: UIView!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountLookupToolButton: UIButton!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    
    @IBOutlet weak var continueButton: PrimaryButton!
    
    let accountNumberLength = (Configuration.shared.opco == .bge || Configuration.shared.opco == .peco || Configuration.shared.opco == .comEd) ? 10 : 11
   
    let viewModel = ForgotUsernameViewModel()
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()
        let navigationTitle: String
              if Configuration.shared.opco != .bge {
                  navigationTitle = Configuration.shared.opco.isPHI ? "Forgot Username" : "Forgot Email"
              } else {
                  navigationTitle = "Forgot Username"
              }
        title = navigationTitle
        
        if Configuration.shared.opco == .bge {
            accountNumberContainerView.isHidden = true
        } else {
            identifierContainerView.isHidden = true
        }
        
        viewModel.continueButtonEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .deepGray
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        instructionLabel.text = NSLocalizedString("Please help us validate your account.", comment: "")
        
        phoneNumberTextField.placeholder = Configuration.shared.opco.isPHI ? NSLocalizedString("Phone Number*", comment: "") : NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let self = self else { return }
                if !phoneNumber.isEmpty {
                    if !hasTenDigits {
                        self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                    } else {
                        self.phoneNumberTextField.setError(nil)
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        identifierDescriptionLabel.textColor = .deepGray
        identifierDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        identifierDescriptionLabel.text = NSLocalizedString("Last 4 Digits of primary account holder’s Social Security Number, Business Tax ID, or BGE PIN", comment: "")
        
        identifierTextField.placeholder = NSLocalizedString("SSN/Business Tax ID/BGE Pin*", comment: "")
        identifierTextField.textField.autocorrectionType = .no
        identifierTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierAccountNumberKeyboardDonePress))
        identifierTextField.textField.delegate = self
        identifierTextField.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.identifierNumber.asDriver(), viewModel.identifierHasFourDigits, viewModel.identifierIsNumeric))
            .drive(onNext: { [weak self] identifierNumber, hasFourDigits, isNumeric in
                guard let self = self else { return }
                if !identifierNumber.isEmpty {
                    if !hasFourDigits {
                        self.identifierTextField.setError(NSLocalizedString("This number must be 4 digits long", comment: ""))
                    } else if !isNumeric {
                        self.identifierTextField.setError(NSLocalizedString("This number must be numeric", comment: ""))
                    } else {
                        self.identifierTextField.setError(nil)
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.identifierTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        accountNumberTextField.textField.isSecureTextEntry = true
        accountNumberTextField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierAccountNumberKeyboardDonePress))
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasValidLength))
            .drive(onNext: { [weak self] accountNumber, hasValidLength in
                guard let self = self else { return }
                if !accountNumber.isEmpty {
                    if !hasValidLength {
                        let errorMessage = String(format: "Account number must be %d digits long", self.accountNumberLength)
                        self.accountNumberTextField.setError(NSLocalizedString(errorMessage, comment: ""))
                    } else {
                        self.accountNumberTextField.setError(nil)
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.accountNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool Tip", comment: "")
        
        accountLookupToolButton.setTitle(NSLocalizedString("Account Lookup Tool", comment: ""), for: .normal)
        accountLookupToolButton.setTitleColor(.actionBlue, for: .normal)
        accountLookupToolButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        accountLookupToolButton.accessibilityLabel = NSLocalizedString("Account lookup tool", comment: "")        
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += phoneNumberTextField.getError()
        if Configuration.shared.opco == .bge {
            message += identifierTextField.getError()
        } else {
            message += accountNumberTextField.getError()
        }
        
        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.validateAccount(onSuccess: { [weak self] in
            LoadingView.hide()
            self?.performSegue(withIdentifier: "forgotUsernameResultSegue", sender: self)
            
            FirebaseUtility.logEvent(.forgotUsername(parameters: [.verification_complete]))
            
            GoogleAnalytics.log(event: .forgotUsernameCompleteAccountValidation)
        }, onNeedAccountNumber: { [weak self] in
            LoadingView.hide()
            self?.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
        }, onError: { [weak self] (title, message) in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let description: String
        switch Configuration.shared.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number may be found in the top right portion on your bill in the bill summary section. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        case .ace, .delmarva, .pepco:
            description = NSLocalizedString("Your Account Number is located in the upper-left portion of your bill. Please enter all 11 digits, but no spaces.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @objc func onIdentifierAccountNumberKeyboardDonePress() {
        viewModel.continueButtonEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] enabled in
                if enabled {
                    self?.onContinuePress()
                } else {
                    self?.view.endEditing(true)
                }
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? ForgotUsernameBGEAccountNumberViewController {
            vc.viewModel.phoneNumber.accept(viewModel.phoneNumber.value)
            vc.viewModel.identifierNumber.accept(viewModel.identifierNumber.value)
        } else if let navController = segue.destination as? LargeTitleNavigationController,
            let vc = navController.viewControllers.first as? AccountLookupToolViewController {
            vc.delegate = self
            vc.viewModel.phoneNumber.accept(viewModel.phoneNumber.value)
        } else if let vc = segue.destination as? ForgotUsernameResultViewController {
            vc.viewModel = viewModel
        }
    }
    
}

extension ForgotUsernameViewController: AccountLookupToolResultViewControllerDelegate {

    func accountLookupToolDidSelectAccount(accountNumber: String, phoneNumber: String) {
        phoneNumberTextField.textField.text = phoneNumber
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd)
        
        accountNumberTextField.textField.text = accountNumber
        accountNumberTextField.textField.sendActions(for: .editingDidEnd)
    }
    
}

extension ForgotUsernameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneNumberTextField.textField {
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
        } else if textField == identifierTextField.textField {
            return newString.count <= 4
        } else if textField == accountNumberTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= accountNumberLength
        }
        
        return true
    }
    
}
