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

class LoginViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
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
    @IBOutlet weak var eyeballButton: UIButton!
    @IBOutlet weak var touchIDImage: UIImageView!
    @IBOutlet weak var touchIDLabel: UILabel!
    @IBOutlet weak var touchIDView: UIView!
    @IBOutlet weak var loginFormViewHeightConstraint: NSLayoutConstraint!
    
    var viewModel = LoginViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService(), registrationService: ServiceFactory.createRegistrationService())
    var passwordAutofilledFromTouchID = false
    var viewAlreadyAppeared = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(verifyAccountNotificationReceived), name: NSNotification.Name.DidTapAccountVerificationDeepLink, object: nil)
        
        view.backgroundColor = .primaryColor
        
        if !viewModel.isTouchIDEnabled() {
            touchIDView.isHidden = true
            loginFormViewHeightConstraint.constant = 390
        }
        
        loginFormView.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        loginFormView.layer.cornerRadius = 2
        
        keepMeSignedInLabel.font = SystemFont.regular.of(textStyle: .headline)
        keepMeSignedInLabel.text = NSLocalizedString("Keep me signed in", comment: "")
        
        usernameTextField.textField.placeholder = NSLocalizedString("Username / Email Address", comment: "")
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .next
        
        passwordTextField.textField.placeholder = NSLocalizedString("Password", comment: "")
        passwordTextField.textField.isSecureTextEntry = true
        passwordTextField.textField.returnKeyType = .done
        passwordTextField.textField.isShowingAccessory = true
        
        eyeballButton.accessibilityLabel = NSLocalizedString("Show password", comment: "")
    
        // Two-way data binding for the username/password fields
        viewModel.username.asObservable().bind(to: usernameTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
        viewModel.password.asObservable().bind(to: passwordTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
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
        usernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.username).addDisposableTo(disposeBag)
        passwordTextField.textField.rx.text.orEmpty.bind(to: viewModel.password).addDisposableTo(disposeBag)
        
        // Update the text field appearance in case data binding autofilled text
        usernameTextField.textField.sendActions(for: .editingDidEnd)
        
        keepMeSignedInSwitch.rx.isOn.bind(to: viewModel.keepMeSignedIn).addDisposableTo(disposeBag)
        
        usernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.passwordTextField.textField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        passwordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.onLoginPress()
        }).addDisposableTo(disposeBag)
        
//        // This hack (on editingDidBegin/editingDidEnd) prevents the automatic scrolling that happens when the password field is
//        // selected on a 4" phone. We want that disabled because of our custom logic in keyboardWillShow.
//        // MMS: REMOVED ON 5/24 because was breaking text field bottom bar appearence
//        passwordTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
//            let wrap = UIScrollView(frame: self.passwordTextField.textField.frame)
//            self.passwordTextField.textField.superview?.addSubview(wrap)
//            self.passwordTextField.textField.frame = CGRect(x: 0, y: 0, width: self.passwordTextField.textField.frame.size.width, height: self.passwordTextField.textField.frame.size.height)
//            wrap.addSubview(self.passwordTextField.textField)
//        }).addDisposableTo(disposeBag)
//        passwordTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
//            if let wrap = self.passwordTextField.textField.superview as? UIScrollView {
//                self.passwordTextField.textField.frame = CGRect(x: wrap.frame.origin.x, y: wrap.frame.origin.y, width: wrap.frame.size.width, height: wrap.frame.size.height)
//                wrap.superview?.addSubview(self.passwordTextField.textField)
//                wrap.removeFromSuperview()
//            }
//        }).addDisposableTo(disposeBag)
        
        forgotUsernameButton.tintColor = .actionBlue
        forgotPasswordButton.tintColor = .actionBlue
        
        touchIDLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        touchIDLabel.isAccessibilityElement = false // The button itself will read "Touch ID"
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
        
        
        // Reset the view for when user pops back from ChangePasswordViewController
        self.signInButton.reset()
        self.passwordTextField.textField.text = ""
        self.passwordTextField.textField.sendActions(for: .editingChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewAlreadyAppeared {
            viewAlreadyAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
                // This delay is necessary to prevent deep link complications -- do not remove
                self.presentTouchIDPrompt()
            })
        }
    }
    
    @IBAction func onLoginPress() {
        view.endEditing(true)
        navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button

        signInButton.setLoading()
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Loading", comment: ""))
        viewModel.performLogin(onSuccess: { (loggedInWithTempPassword: Bool) in
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Complete", comment: ""))
            self.signInButton.setSuccess(animationCompletion: { () in
                self.navigationController?.view.isUserInteractionEnabled = true
                
                // Get the last username that logged in first, and then store the one currently logging in
                let lastLoggedInUsername: String? = self.viewModel.getStoredUsername()
                self.viewModel.storeUsername()
                
                if loggedInWithTempPassword {
                    let storyboard = UIStoryboard(name: "More", bundle: nil)
                    let changePwVc = storyboard.instantiateViewController(withIdentifier: "changePassword") as! ChangePasswordViewController
                    changePwVc.delegate = self
                    changePwVc.sentFromLogin = true
                    self.navigationController?.pushViewController(changePwVc, animated: true)
                } else {
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
                            let message = String(format: NSLocalizedString("Touch ID settings for %@ will be disabled upon signing in as %@. Would you like to enable Touch ID for %@ at this time?", comment: ""), lastLoggedInUsername!, self.viewModel.username.value, self.viewModel.username.value)
                            
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
                }
            })
        }, onError: { (title, message) in
            self.navigationController?.view.isUserInteractionEnabled = true
            self.showErrorAlertWith(title: title, message: message)
        })
    }
    
    @IBAction func onForgotUsernamePress() {
        if Environment.sharedInstance.opco == .bge {
            performSegue(withIdentifier: "forgotUsernameSegueBGE", sender: self)
        } else {
            performSegue(withIdentifier: "forgotUsernameSegue", sender: self)
        }
    }
    
    @IBAction func onForgotPasswordPress() {
        performSegue(withIdentifier: "forgotPasswordSegue", sender: self)
    }
    
    @IBAction func onEyeballPress(_ sender: UIButton) {
        if passwordTextField.textField.isSecureTextEntry {
            passwordTextField.textField.isSecureTextEntry = false
            // Fixes iOS 9 bug where font would change after setting isSecureTextEntry = false //
            passwordTextField.textField.font = nil
            passwordTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            // ------------------------------------------------------------------------------- //
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Show password activated", comment: "")
        } else {
            passwordTextField.textField.isSecureTextEntry = true
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Hide password activated", comment: "")
        }
    }
    
    @IBAction func onTouchIDPress(_ sender: UIButton) {
        touchIDImage.alpha = 1.0
        touchIDLabel.alpha = 1.0
        presentTouchIDPrompt()
    }
    
    @IBAction func onTouchIDTouchDown(_ sender: UIButton) {
        touchIDImage.alpha = 0.5
        touchIDLabel.alpha = 0.5
    }
    
    @IBAction func onTouchIDTouchCancel(_ sender: UIButton) {
        touchIDImage.alpha = 1.0
        touchIDLabel.alpha = 1.0
    }
    
    func launchMainApp() {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.present(viewController!, animated: true, completion: nil)
    }
    
    func showErrorAlertWith(title: String?, message: String) {
        signInButton.reset()
        let errorAlert = UIAlertController(title: title != nil ? title : NSLocalizedString("Sign In Error", comment: ""), message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(errorAlert, animated: true, completion: nil)
    }
    
    func presentTouchIDPrompt() {
        viewModel.attemptLoginWithTouchID(onLoad: { // fingerprint was successful
            self.passwordTextField.textField.sendActions(for: .editingDidEnd) // Update the text field appearance
            self.passwordAutofilledFromTouchID = true // be sure to set this to true after the above line because will send an rx event on the text observer
            
            self.signInButton.setLoading()
            self.navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button
        }, onSuccess: { (loggedInWithTempPassword: Bool) in // fingerprint and subsequent login successful
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Complete", comment: ""))
            self.signInButton.setSuccess(animationCompletion: { () in
                self.navigationController?.view.isUserInteractionEnabled = true
                self.launchMainApp()
            })
        }, onError: { (title, message) in // fingerprint successful but login failed
            self.navigationController?.view.isUserInteractionEnabled = true
            self.showErrorAlertWith(title: title, message: message + "\n\n" + NSLocalizedString("If you have changed your password recently, enter it manually and re-enable Touch ID", comment: ""))
        })
    }
    
    func verifyAccountNotificationReceived(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let guid = userInfo["guid"] as? String {
                LoadingView.show()
                viewModel.validateRegistration(guid: guid, onSuccess: {
                    LoadingView.hide()
                    self.view.makeToast(NSLocalizedString("Thank you for verifying your account", comment: ""), duration: 5.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 50))
                }, onError: { errMessage in
                    LoadingView.hide()
                    let alertVc = UIAlertController(title: NSLocalizedString("Could Not Verify Account", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
                })
            }
        }
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
        view.endEditing(true)
        if let vc = segue.destination as? ForgotPasswordViewController {
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
            self.view.makeToast(NSLocalizedString("Temporary password sent to your email", comment: ""), duration: 5.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 50))
        })
    }
}

extension LoginViewController: SecurityQuestionViewControllerDelegate {
    
    func securityQuestionViewController(_ securityQuestionViewController: SecurityQuestionViewController, didUnmaskUsername username: String) {
        self.viewModel.username.value = username
    }
}

extension LoginViewController: ChangePasswordViewControllerDelegate {
    
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: ChangePasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.makeToast(NSLocalizedString("Password changed", comment: ""), duration: 5.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 50))
        })
    }
}
