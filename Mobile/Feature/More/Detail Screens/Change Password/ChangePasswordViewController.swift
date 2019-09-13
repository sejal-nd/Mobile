//
//  ChangePasswordViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol ChangePasswordViewControllerDelegate: class {
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: ChangePasswordViewController)
}

class ChangePasswordViewController: KeyboardAvoidingStickyFooterViewController {
    
    weak var delegate: ChangePasswordViewControllerDelegate?
    weak var forgotPasswordDelegate: ForgotPasswordViewControllerDelegate?
    
    var tempPasswordWorkflow = false
    var resetPasswordWorkflow = false
    var resetPasswordUsername: String?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var havingTroubleView: UIView!
    @IBOutlet weak var havingTroubleLabel: UILabel!
    @IBOutlet weak var havingTroubleButton: UIButton!
    @IBOutlet weak var currentPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var newPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var confirmPasswordTextField: FloatLabelTextField!
    
    @IBOutlet weak var passwordStrengthView: UIView!
    @IBOutlet weak var passwordStrengthMeterView: PasswordStrengthMeterView!
    @IBOutlet weak var passwordStrengthLabel: UILabel!
    @IBOutlet weak var eyeballButton: UIButton!
    
    // Check ImageViews
    @IBOutlet weak var characterCountCheck: UIImageView!
    @IBOutlet weak var mustAlsoContainLabel: UILabel!
    @IBOutlet weak var uppercaseCheck: UIImageView!
    @IBOutlet weak var lowercaseCheck: UIImageView!
    @IBOutlet weak var numberCheck: UIImageView!
    @IBOutlet weak var specialCharacterCheck: UIImageView!
    
    @IBOutlet var passwordRequirementLabels: [UILabel]!
    
    @IBOutlet weak var submitButton: PrimaryButton!
    
    let disposeBag = DisposeBag()
    
    let viewModel = ChangePasswordViewModel(userDefaults: UserDefaults.standard, authService: ServiceFactory.createAuthenticationService(), biometricsService: ServiceFactory.createBiometricsService())
    
    let toolbar: UIToolbar = {
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
        
        title = NSLocalizedString("Change Password", comment: "")
        
        setupValidation()
        
        havingTroubleView.isHidden = true
        havingTroubleLabel.textColor = .blackText
        havingTroubleLabel.font = SystemFont.regular.of(textStyle: .headline)
        havingTroubleLabel.text = NSLocalizedString("Having trouble?", comment: "")
        havingTroubleButton.tintColor = .actionBlue
        havingTroubleButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        havingTroubleButton.setTitle(NSLocalizedString("Request a Temporary Password", comment: ""), for: .normal)
        
        passwordStrengthView.isHidden = true
        passwordStrengthLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        currentPasswordTextField.placeholder = tempPasswordWorkflow ? NSLocalizedString("Temporary Password", comment: "") : NSLocalizedString("Current Password", comment: "")
        currentPasswordTextField.textField.isSecureTextEntry = true
        currentPasswordTextField.textField.returnKeyType = .next
        currentPasswordTextField.textField.isShowingAccessory = true
        currentPasswordTextField.textField.textContentType = .password

        newPasswordTextField.placeholder = NSLocalizedString("New Password", comment: "")
        newPasswordTextField.textField.isSecureTextEntry = true
        newPasswordTextField.textField.returnKeyType = .next
        newPasswordTextField.textField.delegate = self
        
        if #available(iOS 12.0, *) {
            newPasswordTextField.textField.textContentType = .newPassword
            confirmPasswordTextField.textField.textContentType = .newPassword
            let rulesDescriptor = "required: lower, upper, digit, special; minlength: 8; maxlength: 16;"
            newPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
            confirmPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
        } else {
            newPasswordTextField.textField.inputAccessoryView = toolbar
            confirmPasswordTextField.textField.inputAccessoryView = toolbar
        }
        
        eyeballButton.accessibilityLabel = NSLocalizedString("Show password", comment: "")
        
        confirmPasswordTextField.placeholder = NSLocalizedString("Confirm Password", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        
        mustAlsoContainLabel.font = SystemFont.regular.of(textStyle: .headline)
        for label in passwordRequirementLabels {
            label.textColor = .deepGray
            label.font = SystemFont.regular.of(textStyle: .headline)
        }
        
        // Bind to the view model
        currentPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.currentPassword).disposed(by: disposeBag)
        newPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.newPassword).disposed(by: disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmPassword).disposed(by: disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(.editingChanged).asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            // If we displayed an inline error, clear it when user edits the text
            if self.currentPasswordTextField.errorState {
                self.currentPasswordTextField.setError(nil)
                self.accessibilityErrorLabel()
                
            }
        }).disposed(by: disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { [weak self] _ in
                self?.newPasswordTextField.textField.becomeFirstResponder()
            }).disposed(by: disposeBag)
        
        newPasswordTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.5) {
                    self.passwordStrengthView.isHidden = false
                }
            }).disposed(by: disposeBag)
        
        newPasswordTextField.textField.rx.text.orEmpty.asDriver().drive(onNext: { [weak self] text in
            guard let self = self else { return }
            let score = self.viewModel.passwordScore
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
        newPasswordTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.5, animations: {
                    self.passwordStrengthView.isHidden = true
                    self.view.layoutIfNeeded()
                })
            }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseUtility.logEvent(.changePasswordStart)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .changePasswordOffer)
    }
    
    // MARK: - Actions
    
    @IBAction func submitButtonPress(_ sender: Any? = nil) {
        
        FirebaseUtility.logEvent(.changePasswordSubmit)
        
        view.endEditing(true)
        
        // Hide password while loading
        if !currentPasswordTextField.textField.isSecureTextEntry {
            onEyeballPress(eyeballButton)
        }
        
        LoadingView.show()
        viewModel.changePassword(tempPasswordWorkflow: tempPasswordWorkflow,
                                 resetPasswordWorkflow: resetPasswordWorkflow,
                                 resetPasswordUsername: resetPasswordUsername,
                                 onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            self.delegate?.changePasswordViewControllerDidChangePassword(self)
            self.navigationController?.popViewController(animated: true)

            if self.viewModel.hasStrongPassword {
                GoogleAnalytics.log(event: .strongPasswordComplete)
                
                FirebaseUtility.logEvent(.more, parameters: [EventParameter(parameterName: .action, value: .strong_password_complete)])
            }
            
            FirebaseUtility.logEvent(.changePasswordNetworkComplete)
            
            GoogleAnalytics.log(event: .changePasswordDone)
                                    
            FirebaseUtility.logEvent(.more, parameters: [EventParameter(parameterName: .action, value: .change_password_complete)])

        }, onPasswordNoMatch: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            self.currentPasswordTextField.setError(NSLocalizedString("Incorrect current password", comment: ""))
            self.accessibilityErrorLabel()
            if self.resetPasswordWorkflow {
                self.havingTroubleView.isHidden = false
            }
        }, onError: { [weak self] (error: String) in
            LoadingView.hide()
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
                guard let self = self else { return }
                if self.resetPasswordWorkflow {
                    self.havingTroubleView.isHidden = false
                }
            }))
            self?.present(alert, animated: true)
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
                    self?.newPasswordTextField.textField.text = strongPassword
                    self?.confirmPasswordTextField.textField.text = strongPassword
                    self?.newPasswordTextField.textField.backgroundColor = .autoFillYellow
                    self?.confirmPasswordTextField.textField.backgroundColor = .autoFillYellow
                    self?.newPasswordTextField.textField.resignFirstResponder()
                },
                UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            ]
        )
    }
    
    @IBAction func onEyeballPress(_ sender: UIButton) {
        if currentPasswordTextField.textField.isSecureTextEntry {
            currentPasswordTextField.textField.isSecureTextEntry = false
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Show password activated", comment: "")
        } else {
            currentPasswordTextField.textField.isSecureTextEntry = true
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Hide password activated", comment: "")
        }
    }
    
    
    // MARK: - Helper
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += currentPasswordTextField.getError()
        message += newPasswordTextField.getError()
        message += confirmPasswordTextField.getError()
        
        if message.isEmpty {
            submitButton.accessibilityLabel = NSLocalizedString("Save Password", comment: "")
        } else {
            submitButton.accessibilityLabel = String(format: NSLocalizedString("%@ Save Password", comment: ""), message)
        }
    }
    
    func setupValidation() {
        let checkImageOrNil: (Bool) -> UIImage? = { $0 ? #imageLiteral(resourceName: "ic_check") : nil }
        
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
        viewModel.everythingValid.drive(onNext: { [weak self] valid in
            self?.newPasswordTextField.setValidated(valid, accessibilityLabel: valid ? NSLocalizedString("Minimum password criteria met", comment: "") : nil)
        }).disposed(by: disposeBag)
        
        // Password cannot match username
        viewModel.passwordMatchesUsername.drive(onNext: { [weak self] matches in
            if matches {
                self?.newPasswordTextField.setError(NSLocalizedString("Password cannot match username", comment: ""))
                self?.accessibilityErrorLabel()
            } else {
                self?.newPasswordTextField.setError(nil)
                self?.accessibilityErrorLabel()
                
            }
        }).disposed(by: disposeBag)
        
        viewModel.confirmPasswordMatches.drive(onNext: { [weak self] matches in
            guard let self = self else { return }
            if self.confirmPasswordTextField.textField.hasText {
                if matches {
                    self.confirmPasswordTextField.setValidated(matches, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
                } else {
                    self.confirmPasswordTextField.setError(NSLocalizedString("Passwords do not match", comment: ""))                    
                }
            } else {
                self.confirmPasswordTextField.setValidated(false)
                self.confirmPasswordTextField.setError(nil)
            }
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.doneButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    @IBAction func onRequestTempPasswordPress() {
        guard let username = resetPasswordUsername else { return }
        
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.submitForgotPassword(username: username, onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            self.forgotPasswordDelegate?.forgotPasswordViewControllerDidSubmit(self)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errorMessage in
            LoadingView.hide()
            guard let self = self else { return }
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
}


// MARK: - TextField Delegate

extension ChangePasswordViewController: UITextFieldDelegate {
    
    // Don't allow whitespace entry in the newPasswordTextField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        viewModel.hasStrongPassword = false
        newPasswordTextField.textField.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
        confirmPasswordTextField.textField.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
        
        if string.count == 0 { // Allow backspace
            return true
        }
        if string.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == newPasswordTextField.textField {
            if confirmPasswordTextField.isUserInteractionEnabled {
                confirmPasswordTextField.textField.becomeFirstResponder()
            }
        } else if textField == confirmPasswordTextField.textField {
            if submitButton.isEnabled {
                submitButtonPress()
            }
        }
        return false
    }
    
}
