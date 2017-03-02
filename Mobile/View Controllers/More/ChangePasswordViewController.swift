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

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var currentPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var newPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var confirmPasswordTextField: FloatLabelTextField!
    
    @IBOutlet weak var passwordStrengthMeterView: PasswordStrengthMeterView!
    @IBOutlet weak var passwordStrengthLabel: UILabel!
    
    @IBOutlet weak var passwordRequirementsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmPasswordHeightConstraint: NSLayoutConstraint!
    
    // Check ImageViews
    @IBOutlet weak var characterCountCheck: UIImageView!
    @IBOutlet weak var uppercaseCheck: UIImageView!
    @IBOutlet weak var lowercaseCheck: UIImageView!
    @IBOutlet weak var numberCheck: UIImageView!
    @IBOutlet weak var specialCharacterCheck: UIImageView!
    
    let disposeBag = DisposeBag()
    
    let viewModel = ChangePasswordViewModel(authService: ServiceFactory.createAuthenticationService())
    
    var cancelButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDonePress))
        navigationItem.leftBarButtonItem = cancelButton!
        navigationItem.rightBarButtonItem = doneButton!

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        setupValidation()

        passwordRequirementsViewHeightConstraint.constant = 0
        confirmPasswordHeightConstraint.constant = 0
        
        currentPasswordTextField.textField.placeholder = "Current Password"
        currentPasswordTextField.textField.isSecureTextEntry = true
        currentPasswordTextField.textField.returnKeyType = .next
        
        newPasswordTextField.textField.placeholder = "New Password"
        newPasswordTextField.textField.isSecureTextEntry = true
        newPasswordTextField.textField.returnKeyType = .next
        
        confirmPasswordTextField.textField.placeholder = "Confirm Password"
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.setEnabled(false)
        
        currentPasswordTextField.textField.rx.text.orEmpty.bindTo(viewModel.currentPassword).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.text.orEmpty.bindTo(viewModel.newPassword).addDisposableTo(disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bindTo(viewModel.confirmPassword).addDisposableTo(disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.newPasswordTextField.textField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        
        newPasswordTextField.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { _ in
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
                self.passwordStrengthLabel.text = "Weak"
            } else if score < 4 {
                self.passwordStrengthLabel.text = "Medium"
            } else {
                self.passwordStrengthLabel.text = "Strong"
            }
        }).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { _ in
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.passwordRequirementsViewHeightConstraint.constant = 0
                self.confirmPasswordHeightConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            if self.confirmPasswordTextField.isUserInteractionEnabled {
                self.confirmPasswordTextField.textField.becomeFirstResponder()
            }
        }).addDisposableTo(disposeBag)
        

        confirmPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            if self.doneButton!.isEnabled {
                self.onDonePress()
            }
        }).addDisposableTo(disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onDonePress() {
        print("Done")
        // TODO: Call change password API
        // TODO: If successful and Touch ID enabled, update password in keychain
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
                self.newPasswordTextField.setError("Passsword cannot match username")
            } else {
                self.newPasswordTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.confirmPasswordMatches().subscribe(onNext: { matches in
            if self.confirmPasswordTextField.textField.hasText {
                if matches {
                    self.confirmPasswordTextField.setValidated(matches)
                } else {
                    self.confirmPasswordTextField.setError("Passwords do not match")
                }
            } else {
                self.confirmPasswordTextField.setValidated(false)
                self.confirmPasswordTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.doneButtonEnabled().bindTo(doneButton!.rx.isEnabled).addDisposableTo(disposeBag)
    }
    
    // MARK: Scroll View
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        var tabBarHeight: CGFloat = 0
        if let tabController = tabBarController {
            tabBarHeight = tabController.tabBar.frame.size.height
        }
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height - tabBarHeight, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
}
