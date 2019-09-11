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

class RegistrationCreateCredentialsViewController: KeyboardAvoidingStickyFooterViewController {

    let disposeBag = DisposeBag()

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var createUsernameTextField: FloatLabelTextField!
    @IBOutlet weak var createPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var confirmPasswordTextField: FloatLabelTextField!
        
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
    
    @IBOutlet weak var continueButton: PrimaryButton!
    
    var viewModel: RegistrationViewModel!
    
    lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        let suggestPasswordButton = UIBarButtonItem(title: "Suggest Password", style: .plain, target: self, action: #selector(suggestPassword))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        let items = [suggestPasswordButton, space]
        toolbar.setItems(items, animated: false)
        toolbar.sizeToFit()
        toolbar.tintColor = .actionBlue
        return toolbar
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("Please create your sign in credentials", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        passwordStrengthLabel.textColor = .deepGray
        passwordStrengthLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        mustAlsoContainLabel.textColor = .deepGray
        mustAlsoContainLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        for label in passwordRequirementLabels {
            label.textColor = .deepGray
            label.font = SystemFont.regular.of(textStyle: .subheadline)
        }
        
        setupValidation()
        prepareTextFieldsForInput()
        
        passwordStrengthView.isHidden = true
        
        if Environment.shared.opco == .bge || viewModel.accountType.value == "residential" {
            primaryProfileSwitchView.isHidden = true
        }
        
        primaryProfileLabel.textColor = .deepGray
        primaryProfileLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        primaryProfileCheckbox.rx.isChecked.bind(to: viewModel.primaryProfile).disposed(by: disposeBag)
        
        primaryProfileLabel.isAccessibilityElement = false
        primaryProfileCheckbox.isAccessibilityElement = true
        primaryProfileCheckbox.accessibilityLabel = NSLocalizedString("Set as primary profile for this account", comment: "")
    }
    
    // MARK: - Actions
    
    @IBAction func primaryProfileSwitchToggled(_ sender: Any) {
        viewModel.primaryProfile.value = !viewModel.primaryProfile.value
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.verifyUniqueUsername(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountSetup)
            FirebaseUtility.logEvent(.register, parameters: [EventParameter(parameterName: .action, value: .account_setup)])
            
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
                    self?.viewModel.newPassword.value = strongPassword
                    self?.viewModel.confirmPassword.value = strongPassword
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
        createUsernameTextField.textField.textContentType = .username
        createUsernameTextField.placeholder = NSLocalizedString("Email Address*", comment: "")
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
        
        if #available(iOS 12.0, *) {
            createPasswordTextField.textField.textContentType = .newPassword
            confirmPasswordTextField.textField.textContentType = .newPassword
            let rulesDescriptor = "required: lower, upper, digit, special; minlength: 8; maxlength: 16;"
            createPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
            confirmPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
        } else {
            createPasswordTextField.textField.inputAccessoryView = toolbar
            confirmPasswordTextField.textField.inputAccessoryView = toolbar
        }
        
        confirmPasswordTextField.placeholder = NSLocalizedString("Confirm Password*", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        
        createUsernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.username).disposed(by: disposeBag)
        createPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.newPassword).disposed(by: disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmPassword).disposed(by: disposeBag)
        
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
            self?.characterCountCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsUppercaseLetter.map(checkImageOrNil).drive(uppercaseCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsUppercaseLetter.drive(onNext: { [weak self] valid in
            self?.uppercaseCheck.isAccessibilityElement = valid
            self?.uppercaseCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsLowercaseLetter.map(checkImageOrNil).drive(lowercaseCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsLowercaseLetter.drive(onNext: { [weak self] valid in
            self?.lowercaseCheck.isAccessibilityElement = valid
            self?.lowercaseCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsNumber.map(checkImageOrNil).drive(numberCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsNumber.drive(onNext: { [weak self] valid in
            self?.numberCheck.isAccessibilityElement = valid
            self?.numberCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).disposed(by: disposeBag)
        viewModel.containsSpecialCharacter.map(checkImageOrNil).drive(specialCharacterCheck.rx.image).disposed(by: disposeBag)
        viewModel.containsSpecialCharacter.drive(onNext: { [weak self] valid in
            self?.specialCharacterCheck.isAccessibilityElement = valid
            self?.specialCharacterCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
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
        if let vc = segue.destination as? RegistrationSecurityQuestionsViewController {
            vc.viewModel = viewModel
        }
    }
    
}


// MARK: - TextField Delegate

extension RegistrationCreateCredentialsViewController: UITextFieldDelegate {
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
        return false
    }
    
}
