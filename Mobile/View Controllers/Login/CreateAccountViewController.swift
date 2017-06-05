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
    
//    @IBOutlet weak var passwordConstraintsTextField: FloatLabelTextField!
    
    @IBOutlet var passwordRequirementLabels: [UILabel]!

    @IBOutlet weak var eyeballButton: UIButton!
    @IBOutlet weak var passwordStrengthLabel: UILabel!
    @IBOutlet weak var passwordStrengthView: UIView!
    @IBOutlet weak var passwordStrengthMeterView: PasswordStrengthMeterView!
    
    @IBOutlet weak var characterCountCheck: UIImageView!
    @IBOutlet weak var uppercaseCheck: UIImageView!
    @IBOutlet weak var lowercaseCheck: UIImageView!
    @IBOutlet weak var numberCheck: UIImageView!
    @IBOutlet weak var specialCharacterCheck: UIImageView!
    
    var viewModel = RegistrationViewModel()
    
    var nextButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationCenter()
        
        title = NSLocalizedString("Register", comment: "")
        
        setupNavigationButtons()
        
        populateHelperLabels()
        
        setupValidation()
        
        prepareTextFieldsForInput()
    }

    /// Helpers
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupNavigationButtons() {
        let cancelButton = UIBarButtonItem(title: NSLocalizedString("Back", comment: ""), style: .done, target: self, action: #selector(onBackPress))
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        viewModel.nextButtonEnabled().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please help us validate your account", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
    }
    
    //
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func onEyeballPress(_ sender: UIButton) {
        if createPasswordTextField.textField.isSecureTextEntry {
            createPasswordTextField.textField.isSecureTextEntry = false
            // Fixes iOS 9 bug where font would change after setting isSecureTextEntry = false //
            createPasswordTextField.textField.font = nil
            createPasswordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            // ------------------------------------------------------------------------------- //
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
        } else {
            createPasswordTextField.textField.isSecureTextEntry = true
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
        }
    }
    
    func onBackPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.verifyUniqueUsername(onSuccess: {
            LoadingView.hide()
            
            self.performSegue(withIdentifier: "loadSecretQuestionsSegue", sender: self)

        }, onError: { (title, message) in
            LoadingView.hide()
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        })
        
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
    }

    func setupValidation() {
        let checkImageOrNil: (Bool) -> UIImage? = { $0 ? #imageLiteral(resourceName: "ic_check"): nil }
        
        viewModel.characterCountValid().map(checkImageOrNil).bind(to: characterCountCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsUppercaseLetter().map(checkImageOrNil).bind(to: uppercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsLowercaseLetter().map(checkImageOrNil).bind(to: lowercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsNumber().map(checkImageOrNil).bind(to: numberCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsSpecialCharacter().map(checkImageOrNil).bind(to: specialCharacterCheck.rx.image).addDisposableTo(disposeBag)

        viewModel.newUsernameIsValid().skip(1).asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
                if valid {
                    self.confirmUsernameTextField.setEnabled(valid)
                } else {
                    if !self.createUsernameTextField.isFirstResponder {
                        self.createUsernameTextField.setError(NSLocalizedString("Username must be a valid email address (xx@xxx.xxx)", comment: ""))
                    }
                }
            }).addDisposableTo(disposeBag)
        
        viewModel.usernameMatches().asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
                self.confirmUsernameTextField.setValidated(valid)

                if !valid {
                    self.confirmUsernameTextField.setError(NSLocalizedString("Username does not match", comment: ""))
                }
            }).addDisposableTo(disposeBag)
        
        viewModel.everythingValid().asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
                self.createPasswordTextField.setValidated(valid)
                self.confirmPasswordTextField.setEnabled(valid)
            }).addDisposableTo(disposeBag)
        
        
        // Password cannot match username
        viewModel.passwordMatchesUsername().asDriver(onErrorJustReturn: false)
            .drive(onNext: { matches in
                if matches {
                    self.createPasswordTextField.setError(NSLocalizedString("Password cannot match username", comment: ""))
                } else {
                    self.createPasswordTextField.setError(nil)
                }
            }).addDisposableTo(disposeBag)
        
        viewModel.confirmPasswordMatches().asDriver(onErrorJustReturn: false)
            .drive(onNext: { matches in
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
        
//        viewModel.usernameMax255Characters().asDriver(onErrorJustReturn: false)
//            .drive(onNext: { isOverMax in
//                if isOverMax {
//                    let text = viewModel.username.substring(to:254)
//                    
//                    viewModel.username = text
//                }
//            })
        
        viewModel.doneButtonEnabled().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
    }

    func prepareTextFieldsForInput() {
        //
        passwordStrengthView.isHidden = true
        
        createUsernameTextField.textField.placeholder = NSLocalizedString("Username/Email Address*", comment: "")
        createUsernameTextField.textField.returnKeyType = .next
        createUsernameTextField.textField.delegate = self
        createUsernameTextField.textField.isShowingAccessory = true
        createUsernameTextField.setError(nil)
        createUsernameTextField.becomeFirstResponder()
        
        confirmUsernameTextField.textField.placeholder = NSLocalizedString("Confirm Username/Email Address*", comment: "")
        confirmUsernameTextField.textField.returnKeyType = .next
        confirmUsernameTextField.textField.delegate = self
        confirmUsernameTextField.setEnabled(false)
        
        createPasswordTextField.textField.placeholder = NSLocalizedString("Password*", comment: "")
        createPasswordTextField.textField.isSecureTextEntry = true
        createPasswordTextField.textField.returnKeyType = .done
        createPasswordTextField.textField.delegate = self
        createPasswordTextField.addSubview(eyeballButton)
        
        confirmPasswordTextField.textField.placeholder = NSLocalizedString("Confirm Password*", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        
        // Bind to the view model
        createUsernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.username).addDisposableTo(disposeBag)
        confirmUsernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmUsername).addDisposableTo(disposeBag)
        
        createPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.newPassword).addDisposableTo(disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmPassword).addDisposableTo(disposeBag)
        
        createUsernameTextField.textField.rx.controlEvent(UIControlEvents.editingChanged).asDriver()
            .drive(onNext: { _ in
                // If we displayed an inline error, clear it when user edits the text
                if self.createUsernameTextField.errorState {
                    self.createUsernameTextField.setError(nil)
                }
            }).addDisposableTo(disposeBag)
        
        createUsernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { _ in
                self.createPasswordTextField.textField.becomeFirstResponder()
            }).addDisposableTo(disposeBag)
        
        createPasswordTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { _ in
                UIView.animate(withDuration: 0.5) {
                    self.passwordStrengthView.isHidden = false
                }
            }).addDisposableTo(disposeBag)
        
        createPasswordTextField.textField.rx.text.orEmpty.asDriver()
            .drive(onNext: { text in
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
        
        createPasswordTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .drive(onNext: { _ in
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.5, animations: {
                    self.passwordStrengthView.isHidden = true
                    self.view.layoutIfNeeded()
                })
            }).addDisposableTo(disposeBag)
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


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension CreateAccountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == createUsernameTextField?.textField || textField == confirmUsernameTextField?.textField {
            return newString.characters.count <= viewModel.MAXUSERNAMECHARS
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == createUsernameTextField.textField {
            if confirmUsernameTextField.isUserInteractionEnabled {
                confirmUsernameTextField.becomeFirstResponder()
            } else {
                createPasswordTextField.becomeFirstResponder()
            }
            
        } else if textField == confirmUsernameTextField.textField {
            createPasswordTextField.becomeFirstResponder()
        
        } else if textField == createPasswordTextField.textField {
            if confirmPasswordTextField.isUserInteractionEnabled {
                confirmPasswordTextField.becomeFirstResponder()
            } else {
                createUsernameTextField.becomeFirstResponder()
            }

        } else if textField == confirmPasswordTextField.textField {
            viewModel.nextButtonEnabled().single().subscribe(onNext: { enabled in
                if enabled {
                    self.onNextPress()
                } else {
                    self.view.endEditing(true)
                }
            }).addDisposableTo(disposeBag)
        }
        
        return false
    }
}


