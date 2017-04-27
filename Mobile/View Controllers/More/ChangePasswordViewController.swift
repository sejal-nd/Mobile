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
import MBProgressHUD

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
    
    @IBOutlet weak var expandingPasswordStrengthContainerView: UIView!
    @IBOutlet weak var passwordStrengthMeterView: PasswordStrengthMeterView!
    @IBOutlet weak var passwordStrengthLabel: UILabel!
    @IBOutlet weak var eyeballButton: UIButton!
    
    @IBOutlet weak var passwordRequirementsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmPasswordHeightConstraint: NSLayoutConstraint!
    
    // Check ImageViews
    @IBOutlet weak var characterCountCheck: UIImageView!
    @IBOutlet weak var uppercaseCheck: UIImageView!
    @IBOutlet weak var lowercaseCheck: UIImageView!
    @IBOutlet weak var numberCheck: UIImageView!
    @IBOutlet weak var specialCharacterCheck: UIImageView!
    
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
        
        expandingPasswordStrengthContainerView.isHidden = true
        passwordRequirementsViewHeightConstraint.constant = 0
        confirmPasswordHeightConstraint.constant = 0
        
        currentPasswordTextField.textField.placeholder = sentFromLogin ? NSLocalizedString("Temporary Password", comment: "") : NSLocalizedString("Current Password", comment: "")
        currentPasswordTextField.textField.isSecureTextEntry = true
        currentPasswordTextField.textField.returnKeyType = .next
        currentPasswordTextField.addSubview(eyeballButton)
        currentPasswordTextField.textField.isShowingAccessory = true
        
        newPasswordTextField.textField.placeholder = NSLocalizedString("New Password", comment: "")
        newPasswordTextField.textField.isSecureTextEntry = true
        newPasswordTextField.textField.returnKeyType = .next
        newPasswordTextField.textField.delegate = self
        
        confirmPasswordTextField.textField.placeholder = NSLocalizedString("Confirm Password", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        confirmPasswordTextField.setEnabled(false)
        
        // Bind to the view model
        currentPasswordTextField.textField.rx.text.orEmpty.bindTo(viewModel.currentPassword).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.text.orEmpty.bindTo(viewModel.newPassword).addDisposableTo(disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bindTo(viewModel.confirmPassword).addDisposableTo(disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(UIControlEvents.editingChanged).subscribe(onNext: { _ in
            // If we displayed an inline error, clear it when user edits the text
            if self.currentPasswordTextField.errorState {
                self.currentPasswordTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.newPasswordTextField.textField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        
        newPasswordTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.expandingPasswordStrengthContainerView.isHidden = false
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.passwordRequirementsViewHeightConstraint.constant = 254
                self.confirmPasswordHeightConstraint.constant = 30
                self.view.layoutIfNeeded()
            })
        }).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.text.orEmpty.subscribe(onNext: { text in
            let score = self.viewModel.getPasswordScore()
            self.passwordStrengthMeterView.setScore(score)
            if score < 2 {
                self.passwordStrengthLabel.text = NSLocalizedString("Weak", comment: "")
            } else if score < 4 {
                self.passwordStrengthLabel.text = NSLocalizedString("Medium", comment: "")
            } else {
                self.passwordStrengthLabel.text = NSLocalizedString("Strong", comment: "")
            }
        }).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.passwordRequirementsViewHeightConstraint.constant = 0
                self.confirmPasswordHeightConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.expandingPasswordStrengthContainerView.isHidden = true
            })
        }).addDisposableTo(disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if sentFromLogin {
            navigationController?.view.backgroundColor = .primaryColor
            navigationController?.navigationBar.barTintColor = .primaryColor
            navigationController?.navigationBar.isTranslucent = false
            
            let titleDict: [String: Any] = [
                NSForegroundColorAttributeName: UIColor.white,
                NSFontAttributeName: OpenSans.bold.ofSize(18)
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
        
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
        hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        hud.contentColor = .white
        
        viewModel.changePassword(onSuccess: {
            hud.hide(animated: true)
            if self.sentFromLogin {
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                self.present(viewController!, animated: true, completion: nil)
            } else {
                self.delegate?.changePasswordViewControllerDidChangePassword(self)
                _ = self.navigationController?.popViewController(animated: true)
            }
        }, onPasswordNoMatch: { _ in
            hud.hide(animated: true)
            self.currentPasswordTextField.setError(NSLocalizedString("Incorrect current password", comment: ""))
        }, onError: { (error: String) in
            hud.hide(animated: true)
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
            currentPasswordTextField.textField.font = UIFont.systemFont(ofSize: 18)
            // ------------------------------------------------------------------------------- //
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball_active"), for: .normal)
        } else {
            currentPasswordTextField.textField.isSecureTextEntry = true
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
        }
    }
    
    func setupValidation() {
        viewModel.characterCountValid().map(!).bindTo(characterCountCheck.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.containsUppercaseLetter().map(!).bindTo(uppercaseCheck.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.containsLowercaseLetter().map(!).bindTo(lowercaseCheck.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.containsNumber().map(!).bindTo(numberCheck.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.containsSpecialCharacter().map(!).bindTo(specialCharacterCheck.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.everythingValid().subscribe(onNext: { valid in
            self.newPasswordTextField.setValidated(valid)
            self.confirmPasswordTextField.setEnabled(valid)
        }).addDisposableTo(disposeBag)
        
        // Password cannot match username
        viewModel.passwordMatchesUsername().subscribe(onNext: { matches in
            if matches {
                self.newPasswordTextField.setError(NSLocalizedString("Passsword cannot match username", comment: ""))
            } else {
                self.newPasswordTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.confirmPasswordMatches().subscribe(onNext: { matches in
            if self.confirmPasswordTextField.textField.hasText {
                if matches {
                    self.confirmPasswordTextField.setValidated(matches)
                } else {
                    self.confirmPasswordTextField.setError(NSLocalizedString("Passwords do not match", comment: ""))
                }
            } else {
                self.confirmPasswordTextField.setValidated(false)
                self.confirmPasswordTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.doneButtonEnabled().bindTo(doneButton!.rx.isEnabled).addDisposableTo(disposeBag)
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
