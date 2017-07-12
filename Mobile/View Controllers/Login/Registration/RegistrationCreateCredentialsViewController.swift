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
import ToastSwiftFramework

class RegistrationCreateCredentialsViewController: UIViewController {

    let disposeBag = DisposeBag()

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var createUsernameTextField: FloatLabelTextField!
    @IBOutlet weak var confirmUsernameTextField: FloatLabelTextField!
    @IBOutlet weak var createPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var confirmPasswordTextField: FloatLabelTextField!
    
//    @IBOutlet weak var passwordConstraintsTextField: FloatLabelTextField!
    
    @IBOutlet var passwordRequirementLabels: [UILabel]!

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
    
    var viewModel: RegistrationViewModel!// = RegistrationViewModel(registrationService: ServiceFactory.createRegistrationService())
    
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
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please create your sign in credentials", comment: "")
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
    
    @IBAction func primaryProfileSwitchToggled(_ sender: Any) {
        viewModel.primaryProfile.value = !viewModel.primaryProfile.value
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.verifyUniqueUsername(onSuccess: {
            LoadingView.hide()
            self.performSegue(withIdentifier: "loadSecretQuestionsSegue", sender: self)
        }, onEmailAlreadyExists: {
            LoadingView.hide()
            self.createUsernameTextField.setError(NSLocalizedString("Email already exists. Please select a different email to login to view your account.", comment: ""))
            self.accessibilityErrorLabel()
            
        }, onError: { (title, message) in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }

    func setupValidation() {
        let checkImageOrNil: (Bool) -> UIImage? = { $0 ? #imageLiteral(resourceName: "ic_check"): nil }
        
        viewModel.characterCountValid().map(checkImageOrNil).bind(to: characterCountCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsUppercaseLetter().map(checkImageOrNil).bind(to: uppercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsLowercaseLetter().map(checkImageOrNil).bind(to: lowercaseCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsNumber().map(checkImageOrNil).bind(to: numberCheck.rx.image).addDisposableTo(disposeBag)
        viewModel.containsSpecialCharacter().map(checkImageOrNil).bind(to: specialCharacterCheck.rx.image).addDisposableTo(disposeBag)
        
        viewModel.newUsernameIsValidBool().asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
                self.confirmUsernameTextField.setEnabled(valid)
            }).addDisposableTo(disposeBag)
        
        viewModel.everythingValid().asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
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
                self.accessibilityErrorLabel()
                
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
                self.accessibilityErrorLabel()
                
            }).addDisposableTo(disposeBag)
        
        viewModel.doneButtonEnabled().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
    }

    func prepareTextFieldsForInput() {
        //
        passwordStrengthView.isHidden = true
        
        createUsernameTextField.textField.placeholder = NSLocalizedString("Email Address*", comment: "")
        createUsernameTextField.textField.returnKeyType = .next
        createUsernameTextField.textField.delegate = self
        createUsernameTextField.textField.isShowingAccessory = true
        createUsernameTextField.setError(nil)
        self.accessibilityErrorLabel()
        
        createUsernameTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        self.viewModel.newUsernameIsValid().subscribe(onNext: { errorMessage in
            self.createUsernameTextField.setError(errorMessage)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(self.disposeBag)
        
        createUsernameTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            if self.createUsernameTextField.errorState {
                self.createUsernameTextField.setError(nil)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        confirmUsernameTextField.textField.placeholder = NSLocalizedString("Confirm Email Address*", comment: "")
        confirmUsernameTextField.textField.returnKeyType = .next
        confirmUsernameTextField.textField.delegate = self
        confirmUsernameTextField.setEnabled(false)
        confirmUsernameTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
                
        self.viewModel.newPasswordIsValid().subscribe(onNext: { valid in
            self.createPasswordTextField.setValidated(valid)
        }).addDisposableTo(disposeBag)
        
        self.viewModel.usernameMatches().subscribe(onNext: { valid in
            if self.viewModel.confirmUsername.value.characters.count > 0 {
                self.confirmUsernameTextField.setValidated(valid)
                
                if !valid {
                    self.confirmUsernameTextField.setError(NSLocalizedString("Email address does not match", comment: ""))
                } else {
                    self.confirmUsernameTextField.setError(nil)
                }
            } else {
                self.confirmUsernameTextField.setError(nil)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(self.disposeBag)

        createPasswordTextField.textField.placeholder = NSLocalizedString("Password*", comment: "")
        createPasswordTextField.textField.isSecureTextEntry = true
        createPasswordTextField.textField.returnKeyType = .next
        createPasswordTextField.textField.delegate = self
        createPasswordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        confirmPasswordTextField.textField.placeholder = NSLocalizedString("Confirm Password*", comment: "")
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.textField.delegate = self
        confirmPasswordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        // Bind to the view model
        createUsernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.username).addDisposableTo(disposeBag)
        confirmUsernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmUsername).addDisposableTo(disposeBag)
        
        createPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.newPassword).addDisposableTo(disposeBag)
        confirmPasswordTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmPassword).addDisposableTo(disposeBag)
        
        createUsernameTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { _ in
                // If we displayed an inline error, clear it when user edits the text
                if self.createUsernameTextField.errorState {
                    self.createUsernameTextField.setError(nil)
                }
                self.accessibilityErrorLabel()
                
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
        
        let opCo = Environment.sharedInstance.opco
        
        if opCo == .bge || viewModel.accountType.value == "residential" {
            primaryProfileSwitchView.isHidden = true
        }
        
        primaryProfileLabel.font = SystemFont.regular.of(textStyle: .headline)
        primaryProfileSwitch.rx.isOn.bind(to: viewModel.primaryProfile).addDisposableTo(disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += createUsernameTextField.getError()
        message += createPasswordTextField.getError()
        message += confirmPasswordTextField.getError()
        message += confirmUsernameTextField.getError()
        self.nextButton.accessibilityLabel = NSLocalizedString(message, comment: "")
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RegistrationSecurityQuestionsViewController {
            vc.viewModel = viewModel
        }
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


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension RegistrationCreateCredentialsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.characters.count == 0 { // Allow backspace
            return true
        }
        
        if string.trimmingCharacters(in: .whitespacesAndNewlines).characters.count == 0 {
            return false
        }

//        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
//        
//        if textField == createUsernameTextField.textField || textField == confirmUsernameTextField?.textField {
//            return newString.characters.count <= viewModel.MAXUSERNAMECHARS + 10
//        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == createUsernameTextField.textField {
            if confirmUsernameTextField.isUserInteractionEnabled {
                confirmUsernameTextField.textField.becomeFirstResponder()
            } else {
                createPasswordTextField.textField.becomeFirstResponder()
            }
        } else if textField == confirmUsernameTextField.textField {
            createPasswordTextField.textField.becomeFirstResponder()
        } else if textField == createPasswordTextField.textField {
            if confirmPasswordTextField.isUserInteractionEnabled {
                confirmPasswordTextField.textField.becomeFirstResponder()
            } else {
                createUsernameTextField.textField.becomeFirstResponder()
            }
        } else if textField == confirmPasswordTextField.textField {
            viewModel.doneButtonEnabled().single().subscribe(onNext: { enabled in
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


