//
//  RegistrationValidateAccountViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RegistrationValidateAccountViewController: KeyboardAvoidingStickyFooterViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var registrationFormView: UIView!

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberView: UIView!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var identifierTextField: FloatLabelTextField!

    @IBOutlet weak var questionMarkButton: UIButton!
    @IBOutlet weak var identifierDescriptionLabel: UILabel!
    
    @IBOutlet weak var continueButton: PrimaryButton!

    let viewModel = RegistrationViewModel(registrationService: ServiceFactory.createRegistrationService(), authenticationService: ServiceFactory.createAuthenticationService())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        
        viewModel.validateAccountContinueEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("Please help us validate your account.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        if Environment.shared.opco != .bge {
            accountNumberTextField.placeholder = NSLocalizedString("Account Number*", comment: "")
            accountNumberTextField.textField.autocorrectionType = .no
            accountNumberTextField.setKeyboardType(.numberPad)
            accountNumberTextField.textField.delegate = self
            accountNumberTextField.textField.isShowingAccessory = true
            accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
            questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
            
            accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
                .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasTenDigits))
                .drive(onNext: { [weak self] accountNumber, hasTenDigits in
                    guard let self = self else { return }
                    if !accountNumber.isEmpty && !hasTenDigits {
                        self.accountNumberTextField?.setError(NSLocalizedString("Account number must be 10 digits long", comment: ""))
                    }
                    self.accessibilityErrorLabel()
                }).disposed(by: disposeBag)
            
            accountNumberTextField?.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
                self?.accountNumberTextField?.setError(nil)
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        } else {
            accountNumberView.isHidden = true
        }
        
        phoneNumberTextField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let self = self else { return }
                if !phoneNumber.isEmpty && !hasTenDigits {
                    self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                }
                self.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        var identifierString = "Last 4 Digits of primary account holder’s Social Security Number"
        if Environment.shared.opco == .bge {
            identifierString.append(", Business Tax ID, or BGE Pin")
        } else {
            identifierString.append(" or Business Tax ID.")
        }
        identifierDescriptionLabel.textColor = .deepGray
        identifierDescriptionLabel.text = NSLocalizedString(identifierString, comment: "")
        identifierDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        let identifierPlaceholder: String
        if Environment.shared.opco == .bge {
            identifierPlaceholder = NSLocalizedString("SSN/Business Tax ID/BGE Pin*", comment: "")
        } else {
            identifierPlaceholder = NSLocalizedString("SSN/Business Tax ID*", comment: "")
        }
        
        identifierTextField.placeholder = NSLocalizedString(identifierPlaceholder, comment: "")
        identifierTextField.textField.autocorrectionType = .no
        identifierTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierKeyboardDonePress))
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
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.identifierTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.checkForMaintenance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .registerOffer)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += accountNumberTextField.getError()
        message += phoneNumberTextField.getError()
        message += identifierTextField.getError()
        
        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    @objc func onIdentifierKeyboardDonePress() {
		viewModel.validateAccountContinueEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
			.drive(onNext: { [weak self] enabled in
				if enabled {
					self?.onContinuePress()
				} else {
					self?.view.endEditing(true)
				}
			}).disposed(by: disposeBag)
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let description: String
        switch Environment.shared.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number may be found in the top right portion on your bill in the bill summary section. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)
            
            self?.performSegue(withIdentifier: "createCredentialsSegue", sender: self)
        }, onMultipleAccounts:  { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)
            
            self?.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
        }, onError: { [weak self] (title, message) in
            LoadingView.hide()
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? RegistrationCreateCredentialsViewController {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationBGEAccountNumberViewController {
            vc.viewModel = viewModel
        }
    }
    
}

extension RegistrationValidateAccountViewController: UITextFieldDelegate {
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
        } else if textField == identifierTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4
        } else if textField == accountNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 10
        }
        
        return true
    }
    
}
