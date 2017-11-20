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
    @IBOutlet weak var touchIDLabel: UILabel!
    @IBOutlet weak var touchIDButton: ButtonControl!
    @IBOutlet weak var loginFormViewHeightConstraint: NSLayoutConstraint!
    
    var viewModel = LoginViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService(), registrationService: ServiceFactory.createRegistrationService())
    var viewAlreadyAppeared = false
    var forgotUsernamePopulated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        // This is necessary to handle Touch ID prompt's cancel action -- do not remove
        NotificationCenter.default.rx.notification(.UIApplicationDidBecomeActive, object: nil)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.navigationController?.view.isUserInteractionEnabled = !self.viewModel.isLoggingIn
            })
            .disposed(by: disposeBag)
        
        view.backgroundColor = .primaryColor

        viewModel.touchIdEnabled.asDriver().drive(onNext: { [weak self] touchIDEnabled in
            guard let `self` = self else { return }
            if touchIDEnabled {
                self.touchIDButton.isHidden = false
                self.loginFormViewHeightConstraint.constant = 420
            } else {
                self.touchIDButton.isHidden = true
                self.loginFormViewHeightConstraint.constant = 390
            }
        }).disposed(by: disposeBag)
        
        loginFormView.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        loginFormView.layer.cornerRadius = 2
        
        keepMeSignedInLabel.font = SystemFont.regular.of(textStyle: .headline)
        keepMeSignedInLabel.text = NSLocalizedString("Keep me signed in", comment: "")
        
        usernameTextField.textField.placeholder = NSLocalizedString("Username / Email Address", comment: "")
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .next
        usernameTextField.textField.keyboardType = .emailAddress
        
        passwordTextField.textField.placeholder = NSLocalizedString("Password", comment: "")
        passwordTextField.textField.isSecureTextEntry = true
        passwordTextField.textField.returnKeyType = .done
        passwordTextField.textField.isShowingAccessory = true
        
        eyeballButton.accessibilityLabel = NSLocalizedString("Show password", comment: "")
    
        // Two-way data binding for the username/password fields
        viewModel.username.asDriver().drive(usernameTextField.textField.rx.text.orEmpty).disposed(by: disposeBag)
        viewModel.password.asDriver().drive(passwordTextField.textField.rx.text.orEmpty).disposed(by: disposeBag)
        viewModel.password.asDriver().drive(onNext: { [weak self] (password) in
            guard let `self` = self else { return }
            if let autofilledPw = self.viewModel.touchIDAutofilledPassword, password != autofilledPw {
                // The password field was successfully auto-filled from Touch ID, but then the user manually changed it,
                // presumably because the password has been changed and is now different than what's stored in the keychain.
                // Therefore, we disable Touch ID, and reset the UserDefaults flag to prompt to enable it upon the 
                // next successful login
                self.viewModel.disableTouchID()
                self.viewModel.setShouldPromptToEnableTouchID(true)
                self.viewModel.touchIDAutofilledPassword = nil
            }
        }).disposed(by: disposeBag)
        usernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.username).disposed(by: disposeBag)
        passwordTextField.textField.rx.text.orEmpty.bind(to: viewModel.password).disposed(by: disposeBag)
        
        // Update the text field appearance in case data binding autofilled text
        usernameTextField.textField.sendActions(for: .editingDidEnd)
        
        keepMeSignedInSwitch.rx.isOn.bind(to: viewModel.keepMeSignedIn).disposed(by: disposeBag)
        
        usernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver().drive(onNext: { [weak self] _ in
            self?.passwordTextField.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        passwordTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver().drive(onNext: { [weak self] _ in
            self?.onLoginPress()
        }).disposed(by: disposeBag)
        
//        // This hack (on editingDidBegin/editingDidEnd) prevents the automatic scrolling that happens when the password field is
//        // selected on a 4" phone. We want that disabled because of our custom logic in keyboardWillShow.
//        // MMS: REMOVED ON 5/24 because was breaking text field bottom bar appearence
//        passwordTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
//            let wrap = UIScrollView(frame: self.passwordTextField.textField.frame)
//            self.passwordTextField.textField.superview?.addSubview(wrap)
//            self.passwordTextField.textField.frame = CGRect(x: 0, y: 0, width: self.passwordTextField.textField.frame.size.width, height: self.passwordTextField.textField.frame.size.height)
//            wrap.addSubview(self.passwordTextField.textField)
//        }).disposed(by: disposeBag)
//        passwordTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
//            if let wrap = self.passwordTextField.textField.superview as? UIScrollView {
//                self.passwordTextField.textField.frame = CGRect(x: wrap.frame.origin.x, y: wrap.frame.origin.y, width: wrap.frame.size.width, height: wrap.frame.size.height)
//                wrap.superview?.addSubview(self.passwordTextField.textField)
//                wrap.removeFromSuperview()
//            }
//        }).disposed(by: disposeBag)
        
        forgotUsernameButton.tintColor = .actionBlue
        forgotPasswordButton.tintColor = .actionBlue
        
        touchIDLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        touchIDButton.accessibilityLabel = NSLocalizedString("Touch ID", comment: "")
        
        keepMeSignedInLabel.isAccessibilityElement = false
        keepMeSignedInSwitch.isAccessibilityElement = true
        keepMeSignedInSwitch.accessibilityLabel = keepMeSignedInLabel.text

        checkForMaintenanceMode(onCompletion: { [weak self] in
            // We wait until after the maintence mode check due to the issue with calling 2 anon functions at once. See "IMPORTANT NOTE!" in OMCApi.swift for more info
            if let guid = UserDefaults.standard.string(forKey: UserDefaultKeys.AccountVerificationDeepLinkGuid) {
                UserDefaults.standard.removeObject(forKey: UserDefaultKeys.AccountVerificationDeepLinkGuid) // Clear once consumed
                LoadingView.show()
                self?.viewModel.validateRegistration(guid: guid, onSuccess: { [weak self] in
                    LoadingView.hide()
                    self?.view.showToast(NSLocalizedString("Thank you for verifying your account", comment: ""))
                    Analytics().logScreenView(AnalyticsPageView.RegisterAccountVerify.rawValue)
                }, onError: { [weak self] title, message in
                    LoadingView.hide()
                    let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self?.present(alertVc, animated: true, completion: nil)
                })
            }
        })
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
        signInButton.reset()
        signInButton.accessibilityLabel = "Sign In";
        signInButton.accessibilityViewIsModal = false;
        passwordTextField.textField.text = ""
        passwordTextField.textField.sendActions(for: .editingChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewAlreadyAppeared {
            viewAlreadyAppeared = true
            navigationController?.view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
                // This delay is necessary to prevent deep link complications -- do not remove
                self.presentTouchIDPrompt()
            })
        }
    }
    
    @IBAction func onLoginPress() {
        Analytics().logSignIn(AnalyticsPageView.LoginOffer.rawValue,
                              keepSignedIn: String(describing: keepMeSignedInSwitch.isOn),
                              usedFingerprint: "false")
        
        if forgotUsernamePopulated {
            Analytics().logScreenView(AnalyticsPageView.ForgotUsernameCompleteAccountValidation.rawValue)
        }
        
        view.endEditing(true)
        navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button
        
        signInButton.setLoading()
        signInButton.accessibilityLabel = "Loading";
        signInButton.accessibilityViewIsModal = true;
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Loading", comment: ""))
        })
        
        viewModel.performLogin(onSuccess: { [weak self] (loggedInWithTempPassword: Bool) in
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Complete", comment: ""))
            guard let `self` = self else { return }
            self.signInButton.setSuccess(animationCompletion: { [weak self] in
                guard let `self` = self else { return }
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
                            touchIDAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.launchMainApp()
                            }))
                            touchIDAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.viewModel.storePasswordInTouchIDKeychain()
                                self?.launchMainApp()
                                Analytics().logScreenView(AnalyticsPageView.TouchIDEnable.rawValue)
                            }))
                            self.present(touchIDAlert, animated: true, completion: nil)
                            self.viewModel.setShouldPromptToEnableTouchID(false)
                        } else if lastLoggedInUsername != nil && lastLoggedInUsername != self.viewModel.username.value {
                            let message = String(format: NSLocalizedString("Touch ID settings for %@ will be disabled upon signing in as %@. Would you like to enable Touch ID for %@ at this time?", comment: ""), lastLoggedInUsername!, self.viewModel.username.value, self.viewModel.username.value)
                            
                            let differentAccountAlert = UIAlertController(title: NSLocalizedString("Enable Touch ID", comment: ""), message: message, preferredStyle: .alert)
                            differentAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.viewModel.disableTouchID()
                                self?.launchMainApp()
                            }))
                            differentAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.viewModel.storePasswordInTouchIDKeychain()
                                self?.launchMainApp()
                                Analytics().logScreenView(AnalyticsPageView.TouchIDEnable.rawValue)
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
        }, onRegistrationNotComplete: { [weak self] in
            guard let `self` = self else { return }
            self.navigationController?.view.isUserInteractionEnabled = true
            self.signInButton.reset()
            self.signInButton.accessibilityLabel = "Sign In";
            self.signInButton.accessibilityViewIsModal = false;
            
            let alertVC = UIAlertController(title: NSLocalizedString("Sign In Error", comment: ""), message: NSLocalizedString("The registration process has not been completed. You must click the link in the activation email to complete the process. Would you like the activation email resent?", comment: ""), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Resend", comment: ""), style: .default, handler: { [weak self] (action) in
                LoadingView.show()
                guard let `self` = self else { return }
                self.viewModel.resendValidationEmail(onSuccess: { [weak self] in
                    LoadingView.hide()
                    self?.view.showToast(NSLocalizedString("Verification email sent", comment: ""))
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    self?.showErrorAlertWith(title: NSLocalizedString("Error", comment: ""), message: errMessage)
                })
            }))
            self.present(alertVC, animated: true, completion: nil)
        }, onError: { [weak self] (title, message) in
            self?.navigationController?.view.isUserInteractionEnabled = true
            self?.showErrorAlertWith(title: title, message: message)
        })
    }
    
    @IBAction func onForgotUsernamePress() {
        Analytics().logScreenView(AnalyticsPageView.ForgotUsernameOffer.rawValue)
        if Environment.sharedInstance.opco == .bge {
            performSegue(withIdentifier: "forgotUsernameSegueBGE", sender: self)
        } else {
            performSegue(withIdentifier: "forgotUsernameSegue", sender: self)
        }
    }
    
    @IBAction func onForgotPasswordPress() {
        Analytics().logScreenView(AnalyticsPageView.ForgotPasswordOffer.rawValue)
        performSegue(withIdentifier: "forgotPasswordSegue", sender: self)
    }
    
    @IBAction func onEyeballPress(_ sender: UIButton) {
//        //TEST CODE - REMOVE BEFORE PUSHING
//        LoadingView.show()
//        viewModel.validateRegistration(guid: "6a5bed06-3ac4-4686-ba0d-dd317ea4b0fb", onSuccess: {
//            LoadingView.hide()
//            self.view.showToast(NSLocalizedString("Thank you for verifying your account", comment: ""))
//        }, onError: { title, message in
//            LoadingView.hide()
//            let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
//            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
//            self.present(alertVc, animated: true, completion: nil)
//        })
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
    
    @IBAction func onTouchIDPress() {
        navigationController?.view.isUserInteractionEnabled = false
        
        // This delay is necessary to make setting isUserInteractionEnabled work properly -- do not remove
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
            self.presentTouchIDPrompt()
        })
    }
    
    func launchMainApp() {
        Analytics().logScreenView(AnalyticsPageView.LoginComplete.rawValue)
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        present(viewController!, animated: true, completion: nil)
    }
    
    func showErrorAlertWith(title: String?, message: String) {
        signInButton.reset()
        signInButton.accessibilityLabel = "Sign In";
        signInButton.accessibilityViewIsModal = false;
        
        let errorAlert = UIAlertController(title: title != nil ? title : NSLocalizedString("Sign In Error", comment: ""), message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        present(errorAlert, animated: true, completion: nil)
    }
    
    func presentTouchIDPrompt() {
        viewModel.attemptLoginWithTouchID(onLoad: { [weak self] in // fingerprint was successful
            guard let `self` = self else { return }
            
            Analytics().logSignIn(AnalyticsPageView.LoginOffer.rawValue,
                                  keepSignedIn: String(describing: self.keepMeSignedInSwitch.isOn),
                                  usedFingerprint: "true")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Loading", comment: ""))
            })
            self.passwordTextField.textField.sendActions(for: .editingDidEnd) // Update the text field appearance
            self.signInButton.setLoading()
            self.signInButton.accessibilityLabel = "Loading";
            self.signInButton.accessibilityViewIsModal = true;
            self.touchIDButton.isEnabled = true
            self.navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button
            }, onDidNotLoad:  { [weak self] in
                self?.touchIDButton.isEnabled = true
                self?.navigationController?.view.isUserInteractionEnabled = true
            }, onSuccess: { [weak self] (loggedInWithTempPassword: Bool) in // fingerprint and subsequent login successful
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Complete", comment: ""))
                guard let `self` = self else { return }
                self.signInButton.setSuccess(animationCompletion: { [weak self] in
                    self?.navigationController?.view.isUserInteractionEnabled = true
                    self?.launchMainApp()
                })
            }, onError: { [weak self] (title, message) in // fingerprint successful but login failed
                self?.navigationController?.view.isUserInteractionEnabled = true
                self?.showErrorAlertWith(title: title, message: message + "\n\n" + NSLocalizedString("If you have changed your password recently, enter it manually and re-enable Touch ID", comment: ""))
        })
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
    
    func checkForMaintenanceMode(onCompletion: @escaping () -> Void) {
        viewModel.checkForMaintenance(onSuccess: { [weak self] isMaintenance in
            if isMaintenance {
                self?.navigationController?.view.isUserInteractionEnabled = true
                let ad = UIApplication.shared.delegate as! AppDelegate
                ad.showMaintenanceMode()
            } else {
                onCompletion()
            }
        }, onError: { errorMessage in
            onCompletion()
        })
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
            self.view.showToast(NSLocalizedString("Temporary password sent to your email", comment: ""))
            Analytics().logScreenView(AnalyticsPageView.ForgotPasswordComplete.rawValue)
        })
    }
}

extension LoginViewController: ForgotUsernameSecurityQuestionViewControllerDelegate {
    
    func forgotUsernameSecurityQuestionViewController(_ forgotUsernameSecurityQuestionViewController: ForgotUsernameSecurityQuestionViewController, didUnmaskUsername username: String) {
        viewModel.username.value = username
        Analytics().logScreenView(AnalyticsPageView.ForgotUsernameCompleteAutoPopup.rawValue)
        forgotUsernamePopulated = true
    }
}

extension LoginViewController: ChangePasswordViewControllerDelegate {
    
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: ChangePasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Password changed", comment: ""))
        })
    }
}
