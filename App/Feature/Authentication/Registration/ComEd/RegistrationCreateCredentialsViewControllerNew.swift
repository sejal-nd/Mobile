//
//  RegistrationCreateCredentialsViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Toast_Swift

class RegistrationCreateCredentialsViewControllerNew: KeyboardAvoidingStickyFooterViewController {

    let disposeBag = DisposeBag()

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var createUsernameTextField: FloatLabelTextField!
    @IBOutlet weak var createPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var confirmPasswordTextField: FloatLabelTextField!
    
    // Specific fields to PHI
    @IBOutlet weak var firstNameTextField: FloatLabelTextField!
    @IBOutlet weak var lastNameTextField: FloatLabelTextField!
    @IBOutlet weak var accountNicknameTextField: FloatLabelTextField!
    
    @IBOutlet var passwordRequirementLabels: [UILabel]!
    @IBOutlet var mustAlsoContainLabel: UILabel!

    @IBOutlet weak var passwordStrengthLabel: UILabel!
    @IBOutlet weak var passwordStrengthView: UIView!
    @IBOutlet weak var passwordStrengthMeterView: PasswordStrengthMeterView!
    
    @IBOutlet weak var characterCountCheck: UIImageView!
    @IBOutlet weak var uppercaseCheck: UIImageView!
    @IBOutlet weak var lowercaseCheck: UIImageView!
    @IBOutlet weak var numberCheck: UIImageView!
    @IBOutlet weak var specialCharacterCheck: UIImageView!
    
    @IBOutlet weak var primaryProfileSwitchView: UIView!
    @IBOutlet weak var primaryProfileLabel: UILabel!
    @IBOutlet weak var primaryProfileCheckbox: Checkbox!
    
    @IBOutlet weak var eBillEnrollView: UIView!
    @IBOutlet weak var eBillCheckBox: Checkbox!
    @IBOutlet weak var eBillEnrollInstructions: UILabel!
    
    @IBOutlet weak var passwordEyeBall: UIButton!
    @IBOutlet weak var confirmPasswordEyeBall: UIButton!
    
    @IBOutlet weak var continueButton: PrimaryButton!
    
    var viewModel: RegistrationViewModel!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("Then, set up your profile.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        passwordStrengthLabel.textColor = .deepGray
        passwordStrengthLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        mustAlsoContainLabel.textColor = .deepGray
        mustAlsoContainLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        for label in passwordRequirementLabels {
            label.textColor = .deepGray
            label.font = SystemFont.regular.of(textStyle: .subheadline)
        }
        
        setupValidation()
        prepareTextFieldsForInput()
        
        passwordStrengthView.isHidden = true
        createPasswordTextField.bringSubviewToFront(passwordEyeBall)
        confirmPasswordTextField.bringSubviewToFront(confirmPasswordEyeBall)
        
        if Environment.shared.opco == .bge || viewModel.accountType.value == "residential" {
            primaryProfileSwitchView.isHidden = true
        }

        if self.viewModel.isPaperlessEbillEligible {
            eBillEnrollView.isHidden = false
            eBillCheckBox.rx.isChecked.bind(to: viewModel.paperlessEbill).disposed(by: disposeBag)
            eBillCheckBox.isChecked = true
        } else {
            eBillEnrollView.isHidden = true
        }
        
        eBillEnrollInstructions.textColor = .deepGray
        eBillEnrollInstructions.text = NSLocalizedString("Enroll me in Paperless eBill - an easy, convenient, simple, and secure way to receive your bill online instead of in the mail.", comment: "")
        eBillEnrollInstructions.font = SystemFont.regular.of(textStyle: .headline)
        
        primaryProfileLabel.textColor = .deepGray
        primaryProfileLabel.font = SystemFont.regular.of(textStyle: .headline)
        primaryProfileLabel.text = NSLocalizedString("Set as primary profile for this account", comment: "")
        
        primaryProfileCheckbox.rx.isChecked.bind(to: viewModel.primaryProfile).disposed(by: disposeBag)
        
        primaryProfileLabel.isAccessibilityElement = false
        primaryProfileCheckbox.isAccessibilityElement = true
        primaryProfileCheckbox.accessibilityLabel = NSLocalizedString("Set as primary profile for this account", comment: "")
        setupAccessibility()
    }
    
    // MARK: - Actions
    
    @IBAction func primaryProfileSwitchToggled(_ sender: Any) {
        viewModel.primaryProfile.accept(!viewModel.primaryProfile.value)
    }
    
    @IBAction func enrollIneBillToggle(_ sender: Any) {
        viewModel.paperlessEbill.accept(!viewModel.paperlessEbill.value)
        if eBillCheckBox.isChecked {
            GoogleAnalytics.log(event: .registerEBillEnroll)
        }
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.verifyUniqueUsername(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountSetup)
            
            self?.performSegue(withIdentifier: "loadSecretQuestionsSegue", sender: self)
        }, onEmailAlreadyExists: { [weak self] in
            LoadingView.hide()
            self?.createUsernameTextField.setError(NSLocalizedString("Email already exists. Please select a different email to login to view your account", comment: ""))
            self?.accessibilityErrorLabel()
        }, onError: { [weak self] (title, message) in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    @objc private func suggestPassword() {
        guard let strongPassword = SharedWebCredentials.generatePassword() else { return }
        
        GoogleAnalytics.log(event: .strongPasswordOffer)
        
        presentAlert(title: "Suggested Password:\n\n\(strongPassword)\n",
            message: "This password will be saved in your iCloud keychain so it is available for AutoFill on all your devices.",
            style: .actionSheet,
            actions: [
                UIAlertAction(title: "Use Suggested Password", style: .default) { [weak self] action in
                    self?.viewModel.hasStrongPassword = true
                    self?.viewModel.newPassword.accept(strongPassword)
                    self?.viewModel.confirmPassword.accept(strongPassword)
                    self?.createPasswordTextField.textField.text = strongPassword
                    self?.confirmPasswordTextField.textField.text = strongPassword
                    self?.createPasswordTextField.textField.backgroundColor = .autoFillYellow
                    self?.confirmPasswordTextField.textField.backgroundColor = .autoFillYellow
                    self?.createPasswordTextField.textField.resignFirstResponder()
                },
                UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            ])
    }
    
    // MARK: - Helper

    func prepareTextFieldsForInput() {
        firstNameTextField.isHidden = !viewModel.shouldShowFirstAndLastName
        lastNameTextField.isHidden = !viewModel.shouldShowFirstAndLastName
        accountNicknameTextField.isHidden = !viewModel.shouldShowAccountNickname

        firstNameTextField.textField.textContentType = .name
        firstNameTextField.placeholder = NSLocalizedString("First Name*", comment: "")
        firstNameTextField.setKeyboardType(.default)
        firstNameTextField.textField.returnKeyType = .next
        firstNameTextField.textField.delegate = self
        firstNameTextField.textField.isShowingAccessory = true
        firstNameTextField.setError(nil)
        accessibilityErrorLabel()
        
        lastNameTextField.textField.textContentType = .name
        lastNameTextField.placeholder = NSLocalizedString("Last Name*", comment: "")
        lastNameTextField.setKeyboardType(.emailAddress)
        lastNameTextField.textField.returnKeyType = .next
        lastNameTextField.textField.delegate = self
        lastNameTextField.textField.isShowingAccessory = true
        lastNameTextField.setError(nil)
        accessibilityErrorLabel()
        
        createUsernameTextField.textField.textContentType = .username
        createUsernameTextField.placeholder = NSLocalizedString("Email*", comment: "")
        createUsernameTextField.setKeyboardType(.emailAddress)
        createUsernameTextField.textField.returnKeyType = .next
        createUsernameTextField.textField.delegate = self
        createUsernameTextField.textField.isShowingAccessory = true
        createUsernameTextField.setError(nil)
        accessibilityErrorLabel()
        
        
        createUsernameTextField.textField.textContentType = .username
        createUsernameTextField.placeholder = NSLocalizedString("Email*", comment: "")
        createUsernameTextField.setKeyboardType(.emailAddress)
        createUsernameTextField.textField.returnKeyType = .next
        createUsernameTextField.textField.delegate = self
        createUsernameTextField.textField.isShowingAccessory = true
        createUsernameTextField.setError(nil)
        accessibilityErrorLabel()
        
        viewModel.newUsernameIsValid.drive(onNext: { [weak self] errorMessage in
            self?.createUsernameTextField.setError(errorMessage)
            self?.accessibilityErrorLabel()
            
        }).disposed(by: self.disposeBag)
        
        viewModel.newPasswordIsValid.drive(onNext: { [weak self] valid in
            self?.createPasswordTextField.setValidated(valid, accessibilityLabel: NSLocalizedString("Minimum password criteria met", comment: ""))
        }).disposed(by: disposeBag)
        
        createPasswordTextField.placeholder = NSLocalizedString("Password*", comment: "")
        createPasswordTextField.textField.isSecureTextEntry = true
        createPasswordTextField.textField.returnKeyType = .next
        createPasswordTextField.textField.delegate = self
        
        createPasswordTextField.textField.textContentType = .newPassword
        confirmPasswordTextField.textField.textContentType = .newPassword
        let rulesDescriptor = "required: lower, upper, digit, special; minlength: 8; maxlength: 16;"
        createPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
        confirmPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
        
        
        confirmPasswordTextField.placeholder = NSLocalizedString("Confirm Password*", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = Environment.shared.opco.isPHI ? .next : .done
        confirmPasswordTextField.textField.delegate = self
        
        accountNicknameTextField.placeholder = NSLocalizedString("Account Nickname", comment: "")
        accountNicknameTextField.textField.returnKeyType = .done
        accountNicknameTextField.textField.delegate = self
        
        createUsernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.username).disposed(by: disposeBag)
        createPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.newPassword).disposed(by: disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmPassword).disposed(by: disposeBag)
        
        if Environment.shared.opco.isPHI {
            
            firstNameTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
                .drive(onNext: { [weak self] in
                    guard let self = self else { return }
                    // If we displayed an inline error, clear it when user edits the text
                    if self.firstNameTextField.errorState {
                        self.firstNameTextField.setError(nil)
                    }
                    self.accessibilityErrorLabel()
                }).disposed(by: disposeBag)
            
            firstNameTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
                .drive(onNext: { [weak self] in
                    self?.lastNameTextField.textField.becomeFirstResponder()
                }).disposed(by: disposeBag)
            
            lastNameTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
                .drive(onNext: { [weak self] in
                    guard let self = self else { return }
                    // If we displayed an inline error, clear it when user edits the text
                    if self.lastNameTextField.errorState {
                        self.lastNameTextField.setError(nil)
                    }
                    self.accessibilityErrorLabel()
                }).disposed(by: disposeBag)
            
            lastNameTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
                .drive(onNext: { [weak self] in
                    self?.createUsernameTextField.textField.becomeFirstResponder()
                }).disposed(by: disposeBag)
        }
        
        createUsernameTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                // If we displayed an inline error, clear it when user edits the text
                if self.createUsernameTextField.errorState {
                    self.createUsernameTextField.setError(nil)
                }
                self.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        createUsernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { [weak self] in
                self?.createPasswordTextField.textField.becomeFirstResponder()
            }).disposed(by: disposeBag)
        
        createPasswordTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.5, animations: {
                    self.passwordStrengthView.isHidden = false
                })
            }).disposed(by: disposeBag)
        
        createPasswordTextField.textField.rx.text.orEmpty.asDriver()
            .drive(onNext: { [weak self] text in
                guard let self = self else { return }
                let score = self.viewModel.getPasswordScore()
                self.passwordStrengthMeterView.setScore(score)
                self.createPasswordTextField.checkAccessoryImageView.isHidden = true
                if score < 2 {
                    self.passwordStrengthLabel.text = NSLocalizedString("Weak", comment: "")
                    self.passwordStrengthLabel.accessibilityLabel = NSLocalizedString("Password strength weak", comment: "")
                } else if score < 4 {
                    self.passwordStrengthLabel.text = NSLocalizedString("Medium", comment: "")
                    self.passwordStrengthLabel.accessibilityLabel = NSLocalizedString("Password strength medium", comment: "")
                } else {
                    self.passwordStrengthLabel.text = NSLocalizedString("Strong", comment: "")
                    self.passwordStrengthLabel.accessibilityLabel = NSLocalizedString("Password strength strong", comment: "")
                }
            }).disposed(by: disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.asDriver()
            .drive(onNext: { [weak self] text in
                guard let self = self else { return }
                self.confirmPasswordTextField.checkAccessoryImageView.isHidden = true
            }).disposed(by: disposeBag)
        
        createPasswordTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.5, animations: {
                    self.passwordStrengthView.isHidden = true
                    self.view.layoutIfNeeded()
                })
            }).disposed(by: disposeBag)
    }
    
    func setupValidation() {
        let checkImageOrNil: (Bool) -> UIImage? = { $0 ? #imageLiteral(resourceName: "ic_check"): nil }
        
        viewModel.characterCountValid.map(checkImageOrNil).drive(characterCountCheck.rx.image).disposed(by: disposeBag)
        viewModel.characterCountValid.drive(onNext: { [weak self] valid in
            self?.characterCountCheck.isAccessibilityElement = valid
            self?.characterCountCheck.accessibilityLabel = NSLocalizedString("Password criteria met", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsUppercaseLetter.map(checkImageOrNil).drive(uppercaseCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsUppercaseLetter.drive(onNext: { [weak self] valid in
            self?.uppercaseCheck.isAccessibilityElement = valid
            self?.uppercaseCheck.accessibilityLabel = NSLocalizedString("Password criteria met", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsLowercaseLetter.map(checkImageOrNil).drive(lowercaseCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsLowercaseLetter.drive(onNext: { [weak self] valid in
            self?.lowercaseCheck.isAccessibilityElement = valid
            self?.lowercaseCheck.accessibilityLabel = NSLocalizedString("Password criteria met", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsNumber.map(checkImageOrNil).drive(numberCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsNumber.drive(onNext: { [weak self] valid in
            self?.numberCheck.isAccessibilityElement = valid
            self?.numberCheck.accessibilityLabel = NSLocalizedString("Password criteria met", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsSpecialCharacter.map(checkImageOrNil).drive(specialCharacterCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsSpecialCharacter.drive(onNext: { [weak self] valid in
            self?.specialCharacterCheck.isAccessibilityElement = valid
            self?.specialCharacterCheck.accessibilityLabel = NSLocalizedString("Password criteria met", comment: "")
        }).disposed(by: disposeBag)
        
        // Password cannot match email
        viewModel.passwordMatchesUsername
            .drive(onNext: { [weak self] matches in
                if matches {
                    self?.createPasswordTextField.setError(NSLocalizedString("Password cannot match email", comment: ""))
                } else {
                    self?.createPasswordTextField.setError(nil)
                }
                self?.accessibilityErrorLabel()
                
            }).disposed(by: disposeBag)
        
        viewModel.confirmPasswordMatches.drive(onNext: { [weak self] matches in
            guard let self = self else { return }
            if self.confirmPasswordTextField.textField.hasText {
                if matches {
                    self.confirmPasswordTextField.setValidated(matches, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
                    self.confirmPasswordTextField.setError(nil)
                    self.accessibilityErrorLabel()
                } else {
                    self.confirmPasswordTextField.setError(NSLocalizedString("Passwords do not match", comment: ""))
                    self.accessibilityErrorLabel()
                    
                }
            } else {
                self.confirmPasswordTextField.setValidated(false)
                self.confirmPasswordTextField.setError(nil)
            }
        }).disposed(by: disposeBag)
        
        viewModel.createCredentialsContinueEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += firstNameTextField.getError()
        message += lastNameTextField.getError()
        message += createUsernameTextField.getError()
        message += createPasswordTextField.getError()
        message += confirmPasswordTextField.getError()

        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RegistrationSecurityQuestionsViewControllerNew {
            vc.viewModel = viewModel
        }
    }
    
    @IBAction func eyeToggleActionForPassword(_ sender: Any) {
        if createPasswordTextField.textField.isSecureTextEntry {
            createPasswordTextField.textField.isSecureTextEntry = false
            passwordEyeBall.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
            passwordEyeBall.accessibilityLabel = NSLocalizedString("Show password activated", comment: "")
        } else {
            createPasswordTextField.textField.isSecureTextEntry = true
            passwordEyeBall.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
            passwordEyeBall.accessibilityLabel = NSLocalizedString("Hide password activated", comment: "")
        }
    }
    
    @IBAction func eyeToggleActionForConfirmPassword(_ sender: Any) {
        if confirmPasswordTextField.textField.isSecureTextEntry {
            confirmPasswordTextField.textField.isSecureTextEntry = false
            confirmPasswordEyeBall.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
            confirmPasswordEyeBall.accessibilityLabel = NSLocalizedString("Show password activated", comment: "")
        } else {
            confirmPasswordTextField.textField.isSecureTextEntry = true
            confirmPasswordEyeBall.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
            confirmPasswordEyeBall.accessibilityLabel = NSLocalizedString("Hide password activated", comment: "")
        }
    }
}


// MARK: - TextField Delegate

extension RegistrationCreateCredentialsViewControllerNew: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        createPasswordTextField.textField.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
        confirmPasswordTextField.textField.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
        self.viewModel.hasStrongPassword = false
        
        if string.count == 0 { // Allow backspace
            return true
        }
        
        if string.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            return false
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if Environment.shared.opco.isPHI {
            if textField == firstNameTextField.textField {
                lastNameTextField.textField.becomeFirstResponder()
            } else if textField == lastNameTextField.textField {
                createUsernameTextField.textField.becomeFirstResponder()
            } else if textField == createUsernameTextField.textField {
                createPasswordTextField.textField.becomeFirstResponder()
            } else if textField == createPasswordTextField.textField {
                if confirmPasswordTextField.isUserInteractionEnabled {
                    confirmPasswordTextField.textField.becomeFirstResponder()
                } else {
                    createUsernameTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmPasswordTextField.textField {
                accountNicknameTextField.textField.becomeFirstResponder()
            } else if textField == accountNicknameTextField.textField {
                viewModel.createCredentialsContinueEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
                    .drive(onNext: { [weak self] enabled in
                        if enabled {
                            self?.onContinuePress()
                        } else {
                            self?.view.endEditing(true)
                        }
                    }).disposed(by: disposeBag)
            }
        } else {
            if textField == createUsernameTextField.textField {
                createPasswordTextField.textField.becomeFirstResponder()
            } else if textField == createPasswordTextField.textField {
                if confirmPasswordTextField.isUserInteractionEnabled {
                    confirmPasswordTextField.textField.becomeFirstResponder()
                } else {
                    createUsernameTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmPasswordTextField.textField {
                viewModel.createCredentialsContinueEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
                    .drive(onNext: { [weak self] enabled in
                        if enabled {
                            self?.onContinuePress()
                        } else {
                            self?.view.endEditing(true)
                        }
                    }).disposed(by: disposeBag)
            }
        }
        return false
    }
    
    func setupAccessibility() {
        eBillEnrollInstructions.isAccessibilityElement = false
        eBillCheckBox.isAccessibilityElement = true
        eBillCheckBox.accessibilityLabel = NSLocalizedString("I would like to enroll in Paperless eBill - a fast, easy, and secure way to receive and pay for bills online.", comment: "")
    }
}
