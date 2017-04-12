//
//  LoginViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ToastSwiftFramework

// PECO:
// User_0005084051@test.com / Password1
// kat@test.com / Password1

// BGE:
// multprem02 / Password1
// multprem03 / Abc12345

class LoginViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var opcoLogo: UIImageView!
    @IBOutlet weak var loginFormView: UIView!
    @IBOutlet weak var usernameTextField: FloatLabelTextField!
    @IBOutlet weak var passwordTextField: FloatLabelTextField!
    @IBOutlet weak var keepMeSignedInSwitch: Switch!
    @IBOutlet weak var keepMeSignedInLabel: UILabel!
    @IBOutlet weak var signInButton: PrimaryButton!
    @IBOutlet weak var forgotUsernameButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    var viewModel = LoginViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService())
    var passwordAutofilledFromTouchID = false
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        view.backgroundColor = .primaryColor
        
        loginFormView.layer.shadowColor = UIColor.black.cgColor
        loginFormView.layer.shadowOpacity = 0.15
        loginFormView.layer.shadowRadius = 4
        loginFormView.layer.shadowOffset = CGSize(width: 0, height: 0)
        loginFormView.layer.masksToBounds = false
        loginFormView.layer.cornerRadius = 2
        
        keepMeSignedInLabel.text = NSLocalizedString("Keep me signed in", comment: "")
        
        usernameTextField.textField.placeholder = NSLocalizedString("Username / Email Address", comment: "")
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .next
        
        passwordTextField.textField.placeholder = NSLocalizedString("Password", comment: "")
        passwordTextField.textField.isSecureTextEntry = true
        passwordTextField.textField.returnKeyType = .done
    
        // Two-way data binding for the username/password fields
        viewModel.username.asObservable().bindTo(usernameTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
        viewModel.password.asObservable().bindTo(passwordTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
        viewModel.password.asObservable().subscribe(onNext: { (password) in
            if self.passwordAutofilledFromTouchID {
                // The password field was successfully auto-filled from Touch ID, but then the user manually changed it,
                // presumably because the password has been changed and is now different than what's stored in the keychain.
                // Therefore, we disable Touch ID, and reset the UserDefaults flag to prompt to enable it upon the 
                // next successful login
                self.viewModel.disableTouchID()
                self.viewModel.setShouldPromptToEnableTouchID(true)
                self.passwordAutofilledFromTouchID = false
            }
        }).addDisposableTo(disposeBag)
        usernameTextField.textField.rx.text.orEmpty.bindTo(viewModel.username).addDisposableTo(disposeBag)
        passwordTextField.textField.rx.text.orEmpty.bindTo(viewModel.password).addDisposableTo(disposeBag)
        
        // Update the text field appearance in case data binding autofilled text
        usernameTextField.textField.sendActions(for: .editingDidEnd)
        
        keepMeSignedInSwitch.rx.isOn.bindTo(viewModel.keepMeSignedIn).addDisposableTo(disposeBag)
        
        usernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.passwordTextField.textField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        passwordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.onLoginPress()
        }).addDisposableTo(disposeBag)
        
        forgotUsernameButton.tintColor = UIColor.mediumPersianBlue
        forgotPasswordButton.tintColor = UIColor.mediumPersianBlue
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = true
        
        setNeedsStatusBarAppearanceUpdate()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.attemptLoginWithTouchID(onLoad: { // fingerprint was successful
            self.passwordTextField.textField.sendActions(for: .editingDidEnd) // Update the text field appearance
            self.passwordAutofilledFromTouchID = true // be sure to set this to true after the above line because will send an rx event on the text observer
            
            self.signInButton.setLoading()
            self.navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button
        }, onSuccess: { // fingerprint and subsequent login successful
            self.signInButton.setSuccess(animationCompletion: { () in
                self.navigationController?.view.isUserInteractionEnabled = true
                self.launchMainApp()
            })
        }, onError: { (errorMessage) in // fingerprint successful but login failed
            self.navigationController?.view.isUserInteractionEnabled = true
            self.showErrorAlertWithMessage(errorMessage + "\n\n" + NSLocalizedString("If you have changed your password recently, enter it manually and re-enable Touch ID", comment: ""))
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func onLoginPress() {
        view.endEditing(true)
        navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button

        signInButton.setLoading()
        viewModel.performLogin(onSuccess: {
            self.signInButton.setSuccess(animationCompletion: { () in
                
                // Get the last username that logged in first, and then store the one currently logging in
                let lastLoggedInUsername: String? = self.viewModel.getStoredUsername()
                self.viewModel.storeUsername()
                
                if self.viewModel.isDeviceTouchIDCompatible() {
                    if self.viewModel.shouldPromptToEnableTouchID() {
                        let touchIDAlert = UIAlertController(title: NSLocalizedString("Enable Touch ID", comment: ""), message: NSLocalizedString("Would you like to use Touch ID to sign in from now on?", comment: ""), preferredStyle: .alert)
                        touchIDAlert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .default, handler: { (action) in
                            self.launchMainApp()
                        }))
                        touchIDAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { (action) in
                            self.viewModel.storePasswordInTouchIDKeychain()
                            self.launchMainApp()
                        }))
                        self.present(touchIDAlert, animated: true, completion: nil)
                        self.viewModel.setShouldPromptToEnableTouchID(false)
                    } else if lastLoggedInUsername != nil && lastLoggedInUsername != self.viewModel.username.value {
                        let message = String(format: NSLocalizedString("Touch ID settings for %@ will be disabled upon signing in as %@. Would you like to enable Touch ID for %@ at this time?", comment: ""), lastLoggedInUsername!.obfuscate(), self.viewModel.username.value.obfuscate(), self.viewModel.username.value)
                        
                        let differentAccountAlert = UIAlertController(title: NSLocalizedString("Enable Touch ID", comment: ""), message: message, preferredStyle: .alert)
                        differentAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action) in
                            self.viewModel.disableTouchID()
                            self.launchMainApp()
                        }))
                        differentAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { (action) in
                            self.viewModel.storePasswordInTouchIDKeychain()
                            self.launchMainApp()
                        }))
                        self.present(differentAccountAlert, animated: true, completion: nil)
                    } else {
                        self.launchMainApp()
                    }
                } else {
                    self.launchMainApp()
                }
                
            })
        }, onError: { (errorMessage) in
            self.navigationController?.view.isUserInteractionEnabled = true
            self.showErrorAlertWithMessage(errorMessage)
        })
    }
    
    @IBAction func onForgotUsernamePress() {
        if Environment.sharedInstance.opco == "BGE" {
            performSegue(withIdentifier: "forgotUsernameSegueBGE", sender: self)
        } else {
            performSegue(withIdentifier: "forgotUsernameSegue", sender: self)
        }
    }
    
    @IBAction func onForgotPasswordPress() {
        performSegue(withIdentifier: "forgotPasswordSegue", sender: self)
    }
    
    func launchMainApp() {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.present(viewController!, animated: true, completion: nil)
    }
    
    func showErrorAlertWithMessage(_ errorMessage: String) {
        signInButton.setFailure()
        
        let errorAlert = UIAlertController(title: NSLocalizedString("Sign In Error", comment: ""), message: errorMessage, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(errorAlert, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        
        let rect = signInButton.convert(signInButton.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Other
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t;
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: ForgotPasswordViewController.self) {
            let vc = segue.destination as! ForgotPasswordViewController
            vc.delegate = self
        }
    }
    
}

extension LoginViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        opcoLogo.alpha = lerp(1, 0, scrollView.contentOffset.y / 50.0)
    }
    
}

extension LoginViewController: ForgotPasswordViewControllerDelegate {
    
    func forgotPasswordViewControllerDidSubmit(_ forgotPasswordViewController: ForgotPasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            var toastStyle = ToastManager.shared.style
            toastStyle.verticalPadding = 10
            toastStyle.horizontalPadding = 44
            toastStyle.cornerRadius = 30
            self.view.makeToast(NSLocalizedString("An email has been sent with a\ntemporary password", comment: ""), duration: 3.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 50), style: toastStyle)
        })
    }
}

extension LoginViewController: SecurityQuestionViewControllerDelegate {
    
    func securityQuestionViewController(_ securityQuestionViewController: SecurityQuestionViewController, didUnmaskUsername username: String) {
        self.viewModel.username.value = username
    }
}
