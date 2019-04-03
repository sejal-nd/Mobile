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

class RegistrationCreateCredentialsViewController: UIViewController {

    let disposeBag = DisposeBag()

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var createUsernameTextField: FloatLabelTextField!
    @IBOutlet weak var createPasswordContainerView: UIView!
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
    @IBOutlet weak var primaryProfileSwitch: Switch!
    
    var viewModel: RegistrationViewModel!
    
    var nextButton = UIBarButtonItem()
    
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
        
        setupNotificationCenter()
        
        title = NSLocalizedString("Register", comment: "")
        
        setupNavigationButtons()
        
        populateHelperLabels()
        
        setupValidation()
        
        prepareTextFieldsForInput()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    // MARK: - Actions
    
    @IBAction func primaryProfileSwitchToggled(_ sender: Any) {
        viewModel.primaryProfile.value = !viewModel.primaryProfile.value
    }
    
    @objc func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.verifyUniqueUsername(onSuccess: { [weak self] in
            LoadingView.hide()
            Analytics.log(event: .registerAccountSetup)
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
        
        Analytics.log(event: .strongPasswordOffer)
        
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

        passwordStrengthView.isHidden = true
        
        if #available(iOS 11.0, *) {
            createUsernameTextField.textField.textContentType = .username
        } else {
            createUsernameTextField.textField.textContentType = .emailAddress
        }
        
        createUsernameTextField.textField.placeholder = NSLocalizedString("Email Address*", comment: "")
        createUsernameTextField.setKeyboardType(.emailAddress)
        createUsernameTextField.textField.returnKeyType = .next
        createUsernameTextField.textField.delegate = self
        createUsernameTextField.textField.isShowingAccessory = true
        createUsernameTextField.setError(nil)
        accessibilityErrorLabel()
        
        createUsernameTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        viewModel.newUsernameIsValid.drive(onNext: { [weak self] errorMessage in
            self?.createUsernameTextField.setError(errorMessage)
            self?.accessibilityErrorLabel()
            
        }).disposed(by: self.disposeBag)
        
        createUsernameTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            if self.createUsernameTextField.errorState {
                self.createUsernameTextField.setError(nil)
            }
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.newPasswordIsValid.drive(onNext: { [weak self] valid in
            self?.createPasswordTextField.setValidated(valid, accessibilityLabel: NSLocalizedString("Minimum password criteria met", comment: ""))
        }).disposed(by: disposeBag)

        createPasswordTextField.textField.placeholder = NSLocalizedString("Password*", comment: "")
        createPasswordTextField.textField.isSecureTextEntry = true
        createPasswordTextField.textField.returnKeyType = .next
        createPasswordTextField.textField.delegate = self
        createPasswordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        if #available(iOS 12.0, *) {
            createPasswordTextField.textField.textContentType = .newPassword
            confirmPasswordTextField.textField.textContentType = .newPassword
            let rulesDescriptor = "required: lower, upper, digit, special; minlength: 8; maxlength: 16;"
            createPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
            confirmPasswordTextField.textField.passwordRules = UITextInputPasswordRules(descriptor: rulesDescriptor)
        } else if #available(iOS 11.0, *) {
            createPasswordTextField.textField.inputAccessoryView = toolbar
            confirmPasswordTextField.textField.inputAccessoryView = toolbar
        }
        
        confirmPasswordTextField.textField.placeholder = NSLocalizedString("Confirm Password*", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        confirmPasswordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        // Bind to the view model
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
                self.scrollView.setContentOffset(self.createPasswordContainerView.frame.origin, animated: true)
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
        
        let opCo = Environment.shared.opco
        
        if opCo == .bge || viewModel.accountType.value == "residential" {
            primaryProfileSwitchView.isHidden = true
        }
        
        primaryProfileLabel.font = SystemFont.regular.of(textStyle: .headline)
        primaryProfileSwitch.rx.isOn.bind(to: viewModel.primaryProfile).disposed(by: disposeBag)
        
        primaryProfileLabel.isAccessibilityElement = false
        primaryProfileSwitch.isAccessibilityElement = true
        primaryProfileSwitch.accessibilityLabel = NSLocalizedString("Set as primary profile for this account", comment: "")
        
    }
    
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupNavigationButtons() {
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
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
        
        viewModel.doneButtonEnabled.drive(nextButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please create your sign in credentials", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        passwordStrengthLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        mustAlsoContainLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        for label in passwordRequirementLabels {
            label.font = SystemFont.regular.of(textStyle: .subheadline)
        }
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += createUsernameTextField.getError()
        message += createPasswordTextField.getError()
        message += confirmPasswordTextField.getError()
        
        if message.isEmpty {
            nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            nextButton.accessibilityLabel = String(format: NSLocalizedString("%@ Next", comment: ""), message)
        }
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RegistrationSecurityQuestionsViewController {
            vc.viewModel = viewModel
        }
    }
 
    // MARK: - ScrollView
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        var safeAreaBottomInset: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeAreaBottomInset = view.safeAreaInsets.bottom
        }
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
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
            viewModel.doneButtonEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
                .drive(onNext: { [weak self] enabled in
                    if enabled {
                        self?.onNextPress()
                    } else {
                        self?.view.endEditing(true)
                    }
                }).disposed(by: disposeBag)
        }
        
        return false
    }
    
}
