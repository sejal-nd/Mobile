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

class ChangePasswordViewController: UIViewController {
    
    weak var delegate: ChangePasswordViewControllerDelegate?
    
    var sentFromLogin = false
    
    @IBOutlet weak var scrollView: UIScrollView!
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
    
    let disposeBag = DisposeBag()
    
    let viewModel = ChangePasswordViewModel(userDefaults: UserDefaults.standard, authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService())
    
    var cancelButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Change Password", comment: "")
        
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDonePress))
        navigationItem.leftBarButtonItem = sentFromLogin ? nil : cancelButton!
        navigationItem.hidesBackButton = sentFromLogin
        navigationItem.rightBarButtonItem = doneButton!
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        setupValidation()
        
        passwordStrengthView.isHidden = true
        passwordStrengthLabel.font = SystemFont.regular.of(textStyle: .footnote)
        confirmPasswordTextField.setEnabled(false)
        
        currentPasswordTextField.textField.placeholder = sentFromLogin ? NSLocalizedString("Temporary Password", comment: "") : NSLocalizedString("Current Password", comment: "")
        currentPasswordTextField.textField.isSecureTextEntry = true
        currentPasswordTextField.textField.returnKeyType = .next
        currentPasswordTextField.textField.isShowingAccessory = true
        
        newPasswordTextField.textField.placeholder = NSLocalizedString("New Password", comment: "")
        newPasswordTextField.textField.isSecureTextEntry = true
        newPasswordTextField.textField.returnKeyType = .next
        newPasswordTextField.textField.delegate = self
        
        eyeballButton.accessibilityLabel = NSLocalizedString("Show password", comment: "")
        
        confirmPasswordTextField.textField.placeholder = NSLocalizedString("Confirm Password", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        confirmPasswordTextField.setEnabled(false)
        
        mustAlsoContainLabel.font = SystemFont.regular.of(textStyle: .headline)
        for label in passwordRequirementLabels {
            label.font = SystemFont.regular.of(textStyle: .headline)
        }
        
        // Bind to the view model
        currentPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.currentPassword).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.newPassword).addDisposableTo(disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmPassword).addDisposableTo(disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(UIControlEvents.editingChanged).subscribe(onNext: { _ in
            // If we displayed an inline error, clear it when user edits the text
            if self.currentPasswordTextField.errorState {
                self.currentPasswordTextField.setError(nil)
                self.accessibilityErrorLabel()
                
            }
        }).addDisposableTo(disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { _ in
                self.newPasswordTextField.textField.becomeFirstResponder()
            }).addDisposableTo(disposeBag)
        
        newPasswordTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { _ in
                UIView.animate(withDuration: 0.5) {
                    self.passwordStrengthView.isHidden = false
                }
            }).addDisposableTo(disposeBag)
        
        newPasswordTextField.textField.rx.text.orEmpty.subscribe(onNext: { text in
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
        }).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .drive(onNext: { _ in
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.5, animations: {
                    self.passwordStrengthView.isHidden = true
                    self.view.layoutIfNeeded()
                })
            }).addDisposableTo(disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += currentPasswordTextField.getError()
        message += newPasswordTextField.getError()
        message += confirmPasswordTextField.getError()
        
        if message.isEmpty {
            self.doneButton?.accessibilityLabel = NSLocalizedString("Done", comment: "")
        } else {
            self.doneButton?.accessibilityLabel = NSLocalizedString(message + " Done", comment: "")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if sentFromLogin {
            navigationController?.view.backgroundColor = .primaryColor
            navigationController?.navigationBar.barTintColor = .primaryColor
            navigationController?.navigationBar.isTranslucent = false
            
            let titleDict: [String: Any] = [
                NSForegroundColorAttributeName: UIColor.white,
                NSFontAttributeName: OpenSans.bold.of(size: 18)
            ]
            navigationController?.navigationBar.titleTextAttributes = titleDict
            
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onDonePress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.changePassword(sentFromLogin: sentFromLogin, onSuccess: {
            LoadingView.hide()
            self.delegate?.changePasswordViewControllerDidChangePassword(self)
            _ = self.navigationController?.popViewController(animated: true)
        }, onPasswordNoMatch: { _ in
            LoadingView.hide()
            self.currentPasswordTextField.setError(NSLocalizedString("Incorrect current password", comment: ""))
            self.accessibilityErrorLabel()
            
        }, onError: { (error: String) in
            LoadingView.hide()
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            self.present(alert, animated: true)
        })
    }
    
    @IBAction func onEyeballPress(_ sender: UIButton) {
        if currentPasswordTextField.textField.isSecureTextEntry {
            currentPasswordTextField.textField.isSecureTextEntry = false
            // Fixes iOS 9 bug where font would change after setting isSecureTextEntry = false //
            currentPasswordTextField.textField.font = nil
            currentPasswordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            // ------------------------------------------------------------------------------- //
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Show password activated", comment: "")
        } else {
            currentPasswordTextField.textField.isSecureTextEntry = true
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Hide password activated", comment: "")
        }
    }
    
    func setupValidation() {
        let checkImageOrNil: (Bool) -> UIImage? = { $0 ? #imageLiteral(resourceName: "ic_check") : nil }
        
        viewModel.characterCountValid().map(checkImageOrNil).bind(to: characterCountCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.characterCountValid().subscribe(onNext: { valid in
            self.characterCountCheck.isAccessibilityElement = valid
            self.characterCountCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).addDisposableTo(disposeBag)
        viewModel.containsUppercaseLetter().map(checkImageOrNil).bind(to: uppercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsUppercaseLetter().subscribe(onNext: { valid in
            self.uppercaseCheck.isAccessibilityElement = valid
            self.uppercaseCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).addDisposableTo(disposeBag)
        viewModel.containsLowercaseLetter().map(checkImageOrNil).bind(to: lowercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsLowercaseLetter().subscribe(onNext: { valid in
            self.lowercaseCheck.isAccessibilityElement = valid
            self.lowercaseCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).addDisposableTo(disposeBag)
        viewModel.containsNumber().map(checkImageOrNil).bind(to: numberCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsNumber().subscribe(onNext: { valid in
            self.numberCheck.isAccessibilityElement = valid
            self.numberCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).addDisposableTo(disposeBag)
        viewModel.containsSpecialCharacter().map(checkImageOrNil).bind(to: specialCharacterCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsSpecialCharacter().subscribe(onNext: { valid in
            self.specialCharacterCheck.isAccessibilityElement = valid
            self.specialCharacterCheck.accessibilityLabel = NSLocalizedString("Password criteria met for", comment: "")
        }).addDisposableTo(disposeBag)
        viewModel.everythingValid().subscribe(onNext: { valid in
            self.newPasswordTextField.setValidated(valid, accessibilityLabel: valid ? NSLocalizedString("Minimum password criteria met", comment: "") : nil)
            self.confirmPasswordTextField.setEnabled(valid)
        }).addDisposableTo(disposeBag)
        
        // Password cannot match username
        viewModel.passwordMatchesUsername().subscribe(onNext: { matches in
            if matches {
                self.newPasswordTextField.setError(NSLocalizedString("Password cannot match username", comment: ""))
                self.accessibilityErrorLabel()
                
            } else {
                self.newPasswordTextField.setError(nil)
                self.accessibilityErrorLabel()
                
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.confirmPasswordMatches().subscribe(onNext: { matches in
            if self.confirmPasswordTextField.textField.hasText {
                if matches {
                    self.confirmPasswordTextField.setValidated(matches, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
                } else {
                    self.confirmPasswordTextField.setError(NSLocalizedString("Passwords do not match", comment: ""))
                    self.accessibilityErrorLabel()
                    
                }
            } else {
                self.confirmPasswordTextField.setValidated(false)
                self.confirmPasswordTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.doneButtonEnabled().bind(to: doneButton!.rx.isEnabled).addDisposableTo(disposeBag)
    }
    
    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
}

extension ChangePasswordViewController: UITextFieldDelegate {
    
    // Don't allow whitespace entry in the newPasswordTextField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.characters.count == 0 { // Allow backspace
            return true
        }
        if string.trimmingCharacters(in: .whitespacesAndNewlines).characters.count == 0 {
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
            if self.doneButton!.isEnabled {
                self.onDonePress()
            }
        }
        return false
    }
    
}
