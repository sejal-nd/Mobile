//
//  CreateAccountViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ToastSwiftFramework

class CreateAccountViewController: UIViewController {

    let disposeBag = DisposeBag()

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var createUsernameTextField: FloatLabelTextField!
    @IBOutlet weak var confirmUsernameTextField: FloatLabelTextField!
    @IBOutlet weak var createPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var confirmPasswordTextField: FloatLabelTextField!
    
    @IBOutlet weak var eyeballButton: UIButton!
    
    @IBOutlet weak var passwordConstraintsTextField: FloatLabelTextField!
    
    @IBOutlet var passwordRequirementLabels: [UILabel]!

    @IBOutlet weak var passwordStrengthView: UIView!
    @IBOutlet weak var passwordStrengthMeterView: PasswordStrengthMeterView!
    
    @IBOutlet weak var characterCountCheck: UIImageView!
    @IBOutlet weak var uppercaseCheck: UIImageView!
    @IBOutlet weak var lowercaseCheck: UIImageView!
    @IBOutlet weak var numberCheck: UIImageView!
    @IBOutlet weak var specialCharacterCheck: UIImageView!
    
    var viewModel = RegistrationViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationCenter()
        
        title = NSLocalizedString("Register", comment: "")
        
        setupNavigationButtons()
        
        populateHelperLabels()
        
        prepareTextFieldsForInput()
    }

    /// Helpers
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .back, target: self, action: #selector(onCancelPress))
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        viewModel.nextButtonEnabled().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please help us validate your account", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
    }
    
    func prepareTextFieldsForInput() {
        passwordStrengthView.isHidden = true
        confirmPasswordTextField.setEnabled(false)
        
        createUsernameTextField.textField.placeholder = NSLocalizedString("Username/Email Address*", comment: "")
        createUsernameTextField.textField.isSecureTextEntry = true
        createUsernameTextField.textField.returnKeyType = .next
        createUsernameTextField.addSubview(eyeballButton)
        createUsernameTextField.textField.isShowingAccessory = true
        
        confirmUsernameTextField.textField.placeholder = NSLocalizedString("Confirm Username/Email Address*", comment: "")
        confirmUsernameTextField.textField.isSecureTextEntry = true
        confirmUsernameTextField.textField.returnKeyType = .next
        confirmUsernameTextField.textField.delegate = self
        
        createPasswordTextField.textField.placeholder = NSLocalizedString("Password*", comment: "")
        createPasswordTextField.textField.isSecureTextEntry = true
        createPasswordTextField.textField.returnKeyType = .done
        createPasswordTextField.textField.delegate = self
        createPasswordTextField.setEnabled(false)
        
        confirmPasswordTextField.textField.placeholder = NSLocalizedString("Confirm Password*", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        confirmPasswordTextField.setEnabled(false)

    }
    
    //
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onDonePress() {
        view.endEditing(true)
        
        LoadingView.show()
//        viewModel.changePassword(onSuccess: {
//            LoadingView.hide()
//            if self.sentFromLogin {
//                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
//                self.present(viewController!, animated: true, completion: nil)
//            } else {
//                self.delegate?.changePasswordViewControllerDidChangePassword(self)
//                _ = self.navigationController?.popViewController(animated: true)
//            }
//        }, onPasswordNoMatch: { _ in
//            LoadingView.hide()
//            self.currentPasswordTextField.setError(NSLocalizedString("Incorrect current password", comment: ""))
//        }, onError: { (error: String) in
//            LoadingView.hide()
//            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
//            self.present(alert, animated: true)
//        })
        LoadingView.hide()
    }

    @IBAction func onEyeballPress(_ sender: UIButton) {
        if currentPasswordTextField.textField.isSecureTextEntry {
            currentPasswordTextField.textField.isSecureTextEntry = false
            // Fixes iOS 9 bug where font would change after setting isSecureTextEntry = false //
            currentPasswordTextField.textField.font = nil
            currentPasswordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            // ------------------------------------------------------------------------------- //
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
        } else {
            currentPasswordTextField.textField.isSecureTextEntry = true
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
        }
    }

    func setupValidation() {
        let checkImageOrNil: (Bool) -> UIImage? = { $0 ? #imageLiteral(resourceName: "ic_check"): nil }
        
        viewModel.characterCountValid().map(checkImageOrNil).bind(to: characterCountCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsUppercaseLetter().map(checkImageOrNil).bind(to: uppercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsLowercaseLetter().map(checkImageOrNil).bind(to: lowercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsNumber().map(checkImageOrNil).bind(to: numberCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsSpecialCharacter().map(checkImageOrNil).bind(to: specialCharacterCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.everythingValid().subscribe(onNext: { valid in
            self.newPasswordTextField.setValidated(valid)
            self.confirmPasswordTextField.setEnabled(valid)
        }).addDisposableTo(disposeBag)
        
        // Password cannot match username
        viewModel.passwordMatchesUsername().subscribe(onNext: { matches in
            if matches {
                self.newPasswordTextField.setError(NSLocalizedString("Password cannot match username", comment: ""))
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
        
        viewModel.doneButtonEnabled().bind(to: doneButton!.rx.isEnabled).addDisposableTo(disposeBag)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
