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
import Toast_Swift

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
    @IBOutlet weak var biometricImageView: UIImageView!
    @IBOutlet weak var biometricLabel: UILabel!
    @IBOutlet weak var biometricButton: ButtonControl!
    @IBOutlet weak var loginFormViewHeightConstraint: NSLayoutConstraint!
    
    var viewModel = LoginViewModel(authService: ServiceFactory.createAuthenticationService(), biometricsService: ServiceFactory.createBiometricsService(), registrationService: ServiceFactory.createRegistrationService())
    var viewAlreadyAppeared = false
    var forgotUsernamePopulated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // This is necessary to handle the Touch/Face ID cancel action -- do not remove
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification, object: nil)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.navigationController?.view.isUserInteractionEnabled = !self.viewModel.isLoggingIn
                
                if !self.viewModel.isDeviceBiometricCompatible() { // In case user tapped "Don't Allow" on Face ID Permissions dialog
                    self.viewModel.biometricsEnabled.value = false
                }
            })
            .disposed(by: disposeBag)
        
        view.backgroundColor = .primaryColor

        viewModel.biometricsEnabled.asDriver().drive(onNext: { [weak self] enabled in
            guard let self = self else { return }
            if enabled {
                self.biometricButton.isHidden = false
                self.loginFormViewHeightConstraint.constant = 420
            } else {
                self.biometricButton.isHidden = true
                self.loginFormViewHeightConstraint.constant = 390
            }
        }).disposed(by: disposeBag)
        
        loginFormView.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        loginFormView.layer.cornerRadius = 10
        
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
        
        if #available(iOS 11.0, *) {
            usernameTextField.textField.textContentType = .username
            passwordTextField.textField.textContentType = .password
        }

        eyeballButton.accessibilityLabel = NSLocalizedString("Show password", comment: "")
    
        // Two-way data binding for the username/password fields
        viewModel.username.asDriver().drive(usernameTextField.textField.rx.text.orEmpty).disposed(by: disposeBag)
        viewModel.password.asDriver().drive(passwordTextField.textField.rx.text.orEmpty).disposed(by: disposeBag)
        viewModel.password.asDriver().drive(onNext: { [weak self] password in
            guard let self = self else { return }
            if password.isEmpty { return } // This driver fires upon maintenance mode dismissal, where we don't want this stuff to happen
            if let autofilledPw = self.viewModel.biometricsAutofilledPassword, password != autofilledPw {
                // The password field was successfully auto-filled from biometrics, but then the user manually changed it,
                // presumably because the password has been changed and is now different than what's stored in the keychain.
                // Therefore, we disable biometrics, and reset the UserDefaults flag to prompt to enable it upon the
                // next successful login
                self.viewModel.disableBiometrics()
                self.viewModel.setShouldPromptToEnableBiometrics(true)
                self.viewModel.biometricsAutofilledPassword = nil
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
                
        forgotUsernameButton.tintColor = .actionBlue
        forgotPasswordButton.tintColor = .actionBlue
        
        let biometricsString = viewModel.biometricsString()
        if biometricsString == "Face ID" { // Touch ID icon is default
            biometricImageView.image = #imageLiteral(resourceName: "ic_faceid")
        }
        biometricLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        biometricLabel.text = biometricsString
        biometricButton.accessibilityLabel = biometricsString
        
        keepMeSignedInLabel.isAccessibilityElement = false
        keepMeSignedInSwitch.isAccessibilityElement = true
        keepMeSignedInSwitch.accessibilityLabel = keepMeSignedInLabel.text
        
        viewModel.checkForMaintenance(onCompletion: { [weak self] in
            if let guid = UserDefaults.standard.string(forKey: UserDefaultKeys.accountVerificationDeepLinkGuid) {
                UserDefaults.standard.removeObject(forKey: UserDefaultKeys.accountVerificationDeepLinkGuid) // Clear once consumed
                LoadingView.show()
                self?.viewModel.validateRegistration(guid: guid, onSuccess: { [weak self] in
                    LoadingView.hide()
                    self?.view.showToast(NSLocalizedString("Thank you for verifying your account", comment: ""))
                    Analytics.log(event: .registerAccountVerify)
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
        signInButton.accessibilityLabel = "Sign In"
        signInButton.accessibilityViewIsModal = false
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
                self.presentBiometricsPrompt()
            })
        }
    }
    
    @IBAction func onLoginPress() {
        Analytics.log(event: .loginOffer,
                        dimensions: [.keepMeSignedIn: keepMeSignedInSwitch.isOn ? "true":"false",
                                     .fingerprintUsed: "disabled"])

        if forgotUsernamePopulated {
            Analytics.log(event: .forgotUsernameCompleteAccountValidation)
        }

        view.endEditing(true)
        navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button

        signInButton.setLoading()
        signInButton.accessibilityLabel = "Loading"
        signInButton.accessibilityViewIsModal = true

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
            UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Loading", comment: ""))
        })

        // Hide password while loading
        if !passwordTextField.textField.isSecureTextEntry {
            onEyeballPress(eyeballButton)
        }

        viewModel.performLogin(onSuccess: { [weak self] (loggedInWithTempPassword: Bool, isStormMode: Bool) in
            UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Complete", comment: ""))
            guard let self = self else { return }
            self.signInButton.setSuccess(animationCompletion: { [weak self] in
                guard let self = self else { return }
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
                    if self.viewModel.isDeviceBiometricCompatible() {
                        let biometricsString = self.viewModel.biometricsString()!
                        if self.viewModel.shouldPromptToEnableBiometrics() {
                            let biometricsAlert = UIAlertController(title: String(format: NSLocalizedString("Enable %@", comment: ""), biometricsString),
                                                                    message: String(format: NSLocalizedString("Would you like to use %@ to sign in from now on?", comment: ""), biometricsString),
                                                                    preferredStyle: .alert)
                            biometricsAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.launchMainApp(isStormMode: isStormMode)
                            }))
                            biometricsAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.viewModel.storePasswordInSecureEnclave()
                                self?.launchMainApp(isStormMode: isStormMode)
                                Analytics.log(event: .touchIDEnable)
                            }))
                            self.present(biometricsAlert, animated: true, completion: nil)
                            self.viewModel.setShouldPromptToEnableBiometrics(false)
                        } else if lastLoggedInUsername != nil && lastLoggedInUsername != self.viewModel.username.value {
                            let message = String(format: NSLocalizedString("%@ settings for %@ will be disabled upon signing in as %@. Would you like to enable %@ for %@ at this time?", comment: ""), biometricsString, lastLoggedInUsername!, self.viewModel.username.value, biometricsString, self.viewModel.username.value)

                            let differentAccountAlert = UIAlertController(title: String(format: NSLocalizedString("Enable %@", comment: ""), biometricsString), message: message, preferredStyle: .alert)
                            differentAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.viewModel.disableBiometrics()
                                self?.launchMainApp(isStormMode: isStormMode)
                            }))
                            differentAccountAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.viewModel.storePasswordInSecureEnclave()
                                self?.launchMainApp(isStormMode: isStormMode)
                                Analytics.log(event: .touchIDEnable)
                            }))
                            self.present(differentAccountAlert, animated: true, completion: nil)
                        } else {
                            self.launchMainApp(isStormMode: isStormMode)
                        }
                    } else {
                        self.launchMainApp(isStormMode: isStormMode)
                    }
                }
            })
        }, onRegistrationNotComplete: { [weak self] in
            guard let self = self else { return }
            self.navigationController?.view.isUserInteractionEnabled = true
            self.signInButton.reset()
            self.signInButton.accessibilityLabel = "Sign In"
            self.signInButton.accessibilityViewIsModal = false

            let alertVC = UIAlertController(title: NSLocalizedString("Sign In Error", comment: ""), message: NSLocalizedString("The registration process has not been completed. You must click the link in the activation email to complete the process. Would you like the activation email resent?", comment: ""), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Resend", comment: ""), style: .default, handler: { [weak self] (action) in
                LoadingView.show()
                guard let self = self else { return }
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
        Analytics.log(event: .forgotUsernameOffer)
        if Environment.shared.opco == .bge {
            performSegue(withIdentifier: "forgotUsernameSegueBGE", sender: self)
        } else {
            performSegue(withIdentifier: "forgotUsernameSegue", sender: self)
        }
    }
    
    @IBAction func onForgotPasswordPress() {
        Analytics.log(event: .forgotPasswordOffer)
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
    
    @IBAction func onBiometricsButtonPress() {
        navigationController?.view.isUserInteractionEnabled = false
        
        // This delay is necessary to make setting isUserInteractionEnabled work properly -- do not remove
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
            self.presentBiometricsPrompt()
        })
    }
    
    func launchMainApp(isStormMode: Bool) {
        Analytics.log(event: .loginComplete)

        if isStormMode {
            (UIApplication.shared.delegate as? AppDelegate)?.showStormMode()
        } else {
            guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController,
                let navController = self.navigationController else {
                    return
            }
            navController.setNavigationBarHidden(true, animated: false)
            navController.setViewControllers([viewController], animated: false)
        }
    }
    
    func showErrorAlertWith(title: String?, message: String) {
        signInButton.reset()
        signInButton.accessibilityLabel = "Sign In"
        signInButton.accessibilityViewIsModal = false
        
        let errorAlert = UIAlertController(title: title != nil ? title : NSLocalizedString("Sign In Error", comment: ""), message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        present(errorAlert, animated: true, completion: nil)
    }
    
    func presentBiometricsPrompt() {
        viewModel.attemptLoginWithBiometrics(onLoad: { [weak self] in // Face/Touch ID was successful
            guard let self = self else { return }
            
            Analytics.log(event: .loginOffer,
                                 dimensions: [.keepMeSignedIn: self.keepMeSignedInSwitch.isOn ? "true":"false",
                                              .fingerprintUsed: "enabled"])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Loading", comment: ""))
            })
            self.passwordTextField.textField.sendActions(for: .editingDidEnd) // Update the text field appearance
            self.signInButton.setLoading()
            self.signInButton.accessibilityLabel = "Loading"
            self.signInButton.accessibilityViewIsModal = true
            self.biometricButton.isEnabled = true
            self.navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button
            
            // Hide password while loading
            if !self.passwordTextField.textField.isSecureTextEntry {
                self.onEyeballPress(self.eyeballButton)
            }
        }, onDidNotLoad:  { [weak self] in
            self?.biometricButton.isEnabled = true
            self?.navigationController?.view.isUserInteractionEnabled = true
        }, onSuccess: { [weak self] (loggedInWithTempPassword: Bool, isStormMode: Bool) in // Face/Touch ID and subsequent login successful
            UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Complete", comment: ""))
            guard let self = self else { return }
            self.signInButton.setSuccess(animationCompletion: { [weak self] in
                self?.navigationController?.view.isUserInteractionEnabled = true
                self?.launchMainApp(isStormMode: isStormMode)
            })
        }, onError: { [weak self] (title, message) in // Face/Touch ID successful but login failed
            guard let self = self else { return }
            self.navigationController?.view.isUserInteractionEnabled = true
            self.showErrorAlertWith(title: title, message: message + "\n\n" + String(format: NSLocalizedString("If you have changed your password recently, enter it manually and re-enable %@", comment: ""), self.viewModel.biometricsString()!))
        })
    }
    
    // MARK: - Keyboard
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        var safeAreaBottomInset: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeAreaBottomInset = self.view.safeAreaInsets.bottom
        }
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets

        let screenHeight = UIScreen.main.bounds.size.height
        if self.passwordTextField.textField.isFirstResponder && screenHeight == 568 { // Handle oddity that only occurs on iPhone 5 size
            self.scrollView.contentOffset = CGPoint(x: 0, y: 162)
        } else {
            let rect = signInButton.convert(signInButton.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rect, animated: true)
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Other
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t
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
        if scrollView.contentOffset.y > 20 {
            opcoLogo.alpha = lerp(1, 0, (scrollView.contentOffset.y - 20.0) / 20.0)
        } else {
            opcoLogo.alpha = 1
        }
    }
    
}

extension LoginViewController: ForgotPasswordViewControllerDelegate {
    
    func forgotPasswordViewControllerDidSubmit(_ forgotPasswordViewController: ForgotPasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Temporary password sent to your email", comment: ""))
            Analytics.log(event: .forgotPasswordComplete)
        })
    }
}

extension LoginViewController: ForgotUsernameSecurityQuestionViewControllerDelegate {
    
    func forgotUsernameSecurityQuestionViewController(_ forgotUsernameSecurityQuestionViewController: ForgotUsernameSecurityQuestionViewController, didUnmaskUsername username: String) {
        viewModel.username.value = username
        Analytics.log(event: .forgotUsernameCompleteAutoPopup)
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
