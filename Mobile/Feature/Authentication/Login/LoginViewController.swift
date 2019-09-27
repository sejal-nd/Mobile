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

class LoginViewController: UIViewController, UIGestureRecognizerDelegate {

    let disposeBag = DisposeBag()

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backgroundViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var fakeNavBarView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var opcoLogoView: UIView!
    @IBOutlet weak var opcoLogo: UIImageView!
    @IBOutlet weak var loginFormView: UIView!
    @IBOutlet weak var usernameTextField: FloatLabelTextField!
    @IBOutlet weak var passwordTextField: FloatLabelTextField!
    @IBOutlet weak var keepMeSignedInCheckbox: Checkbox!
    @IBOutlet weak var keepMeSignedInLabel: UILabel!
    @IBOutlet weak var signInButton: PrimaryButton!
    @IBOutlet weak var forgotUsernamePasswordButton: UIButton!
    @IBOutlet weak var eyeballButton: UIButton!
    @IBOutlet weak var biometricImageView: UIImageView!
    @IBOutlet weak var biometricLabel: UILabel!
    @IBOutlet weak var biometricButton: ButtonControl!

    var viewModel = LoginViewModel(authService: ServiceFactory.createAuthenticationService(), biometricsService: ServiceFactory.createBiometricsService(), registrationService: ServiceFactory.createRegistrationService())
    var viewAlreadyAppeared = false
    var forgotUsernamePopulated = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

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

        view.backgroundColor = .white
        backgroundView.backgroundColor = .primaryColor
        fakeNavBarView.backgroundColor = .primaryColor
        opcoLogoView.backgroundColor = .primaryColor

        scrollView?.rx.contentOffset.asDriver()
            .map { $0.y }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] yOffset in
                guard let self = self else { return }
                let breakHeight = self.opcoLogoView.frame.size.height - 110
                if yOffset <= 0 {
                    self.backgroundViewBottomConstraint.constant = yOffset
                }
                if yOffset > breakHeight {
                    self.opcoLogo.alpha = self.lerp(1, 0, (yOffset - breakHeight) / 10.0)
                } else {
                    self.opcoLogo.alpha = 1
                }
            })
            .disposed(by: disposeBag)

        viewModel.biometricsEnabled.asDriver().not().drive(biometricButton.rx.isHidden).disposed(by: disposeBag)

        keepMeSignedInLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        keepMeSignedInLabel.textColor = .deepGray
        keepMeSignedInLabel.text = NSLocalizedString("Keep me signed in", comment: "")

        usernameTextField.placeholder = NSLocalizedString("Username / Email Address", comment: "")
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .next
        usernameTextField.textField.keyboardType = .emailAddress
        usernameTextField.textField.textContentType = .username

        passwordTextField.placeholder = NSLocalizedString("Password", comment: "")
        passwordTextField.textField.isSecureTextEntry = true
        passwordTextField.textField.returnKeyType = .done
        passwordTextField.textField.isShowingAccessory = true
        passwordTextField.textField.textContentType = .password

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

        keepMeSignedInCheckbox.rx.isChecked.bind(to: viewModel.keepMeSignedIn).disposed(by: disposeBag)

        usernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver().drive(onNext: { [weak self] _ in
            self?.passwordTextField.textField.becomeFirstResponder()
        }).disposed(by: disposeBag)
        passwordTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver().drive(onNext: { [weak self] _ in
            self?.onLoginPress()
        }).disposed(by: disposeBag)

        forgotUsernamePasswordButton.tintColor = .actionBlue
        forgotUsernamePasswordButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        forgotUsernamePasswordButton.titleLabel?.numberOfLines = 0
        forgotUsernamePasswordButton.titleLabel?.textAlignment = .center
        UIView.performWithoutAnimation { // Prevents ugly setTitle animation
            self.forgotUsernamePasswordButton.setTitle(NSLocalizedString("Forgot your username or password?", comment: ""), for: .normal)
            self.forgotUsernamePasswordButton.layoutIfNeeded()
        }

        let biometricsString = viewModel.biometricsString()
        if biometricsString == "Face ID" { // Touch ID icon is default
            biometricImageView.image = #imageLiteral(resourceName: "ic_faceid")
        }
        biometricLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        biometricLabel.text = biometricsString
        biometricButton.accessibilityLabel = biometricsString

        keepMeSignedInLabel.isAccessibilityElement = false
        keepMeSignedInCheckbox.isAccessibilityElement = true
        keepMeSignedInCheckbox.accessibilityLabel = keepMeSignedInLabel.text

        viewModel.checkForMaintenance(onCompletion: { [weak self] in
            if let guid = UserDefaults.standard.string(forKey: UserDefaultKeys.accountVerificationDeepLinkGuid) {
                UserDefaults.standard.removeObject(forKey: UserDefaultKeys.accountVerificationDeepLinkGuid) // Clear once consumed
                LoadingView.show()
                self?.viewModel.validateRegistration(guid: guid, onSuccess: { [weak self] in
                    LoadingView.hide()
                    self?.view.showToast(NSLocalizedString("Thank you for verifying your account", comment: ""))
                    GoogleAnalytics.log(event: .registerAccountVerify)
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

        FirebaseUtility.logEvent(.loginPageStart)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.interactivePopGestureRecognizer?.delegate = self

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
    
    @IBAction func onBackPress() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onLoginPress() {
        view.endEditing(true)

        if Environment.shared.environmentName != .aut { // Otherwise all our mock data usernames would fail
            if Environment.shared.opco != .bge && !viewModel.usernameIsValidEmailAddress {
                // ComEd/PECO only email validation. If not valid email then fail before making the call
                let message = NSLocalizedString("FN-FAIL-LOGIN", tableName: "ErrorMessages", comment: "")
                showErrorAlertWith(title: nil, message: message)
                return
            }
            
            if !viewModel.passwordMeetsRequirements {
                let alert = UIAlertController(
                    title: NSLocalizedString("Sign In Error", comment: ""),
                    message: NSLocalizedString("To provide increased protection of your account, passwords must now meet new complexity standards.", comment: ""),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Change Password", comment: ""), style: .default, handler: { _ in
                    let storyboard = UIStoryboard(name: "More", bundle: nil)
                    let changePwVc = storyboard.instantiateViewController(withIdentifier: "changePassword") as! ChangePasswordViewController
                    changePwVc.delegate = self
                    changePwVc.forgotPasswordDelegate = self
                    changePwVc.resetPasswordWorkflow = true
                    changePwVc.resetPasswordUsername = self.viewModel.username.value
                    self.navigationController?.pushViewController(changePwVc, animated: true)
                }))
                present(alert, animated: true, completion: nil)
                return
            }
        }

        FirebaseUtility.logEvent(.keepMeSignedIn, parameters: [EventParameter(parameterName: .value, value: nil, providedValue: keepMeSignedInCheckbox.isChecked.description)])
        
        GoogleAnalytics.log(event: .loginOffer, dimensions: [
            .keepMeSignedIn: keepMeSignedInCheckbox.isChecked ? "true" : "false",
            .fingerprintUsed: "disabled"
        ])

        if forgotUsernamePopulated {
            GoogleAnalytics.log(event: .forgotUsernameCompleteAccountValidation)
        }

        navigationController?.view.isUserInteractionEnabled = false // Blocks entire screen including back button

        signInButton.setLoading()
        signInButton.accessibilityLabel = NSLocalizedString("Loading", comment: "")
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
                    changePwVc.tempPasswordWorkflow = true
                    self.navigationController?.pushViewController(changePwVc, animated: true)
                } else {
                    if self.viewModel.isDeviceBiometricCompatible() {
                        let biometricsString = self.viewModel.biometricsString()!
                        if self.viewModel.shouldPromptToEnableBiometrics() {
                            let biometricsAlert = UIAlertController(title: String(format: NSLocalizedString("Enable %@", comment: ""), biometricsString),
                                                                    message: String(format: NSLocalizedString("Would you like to use %@ to sign in from now on?", comment: ""), biometricsString),
                                                                    preferredStyle: .alert)
                            biometricsAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { [weak self] (action) in
                                FirebaseUtility.logEvent(.biometricsToggle, parameters: [EventParameter(parameterName: .value, value: nil, providedValue: false.description)])
                                self?.launchMainApp(isStormMode: isStormMode)
                            }))
                            biometricsAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) in
                                self?.viewModel.storePasswordInSecureEnclave()
                                self?.launchMainApp(isStormMode: isStormMode)
                                FirebaseUtility.logEvent(.biometricsToggle, parameters: [EventParameter(parameterName: .value, value: nil, providedValue: true.description)])
                                GoogleAnalytics.log(event: .touchIDEnable)
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
                                GoogleAnalytics.log(event: .touchIDEnable)
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

    @IBAction func onForgotUsernamePasswordPress() {
        view.endEditing(true)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Forgot Username", comment: ""), style: .default, handler: { _ in
            self.forgotUsername()
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Forgot Password", comment: ""), style: .default, handler: { _ in
            self.forgotPassword()
        }))
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))

        if let popoverController = actionSheet.popoverPresentationController { // iPad popover
            let width = self.forgotUsernamePasswordButton.frame.size.width
            popoverController.sourceView = self.forgotUsernamePasswordButton
            popoverController.sourceRect = CGRect(x: width / 2, y: 0, width: 0, height: 0)
            popoverController.permittedArrowDirections = .down
        }

        present(actionSheet, animated: true, completion: nil)
    }

    func forgotUsername() {
        FirebaseUtility.logEvent(.login, parameters: [EventParameter(parameterName: .action, value: .forgot_username_press)])
        GoogleAnalytics.log(event: .forgotUsernameOffer)
        performSegue(withIdentifier: "forgotUsernameSegue", sender: self)
    }

    func forgotPassword() {
        FirebaseUtility.logEvent(.login, parameters: [EventParameter(parameterName: .action, value: .forgot_password_press)])
        GoogleAnalytics.log(event: .forgotPasswordOffer)
        performSegue(withIdentifier: "forgotPasswordSegue", sender: self)
    }

    @IBAction func onEyeballPress(_ sender: UIButton) {
        FirebaseUtility.logEvent(.login, parameters: [EventParameter(parameterName: .action, value: .show_password)])
        
        if passwordTextField.textField.isSecureTextEntry {
            passwordTextField.textField.isSecureTextEntry = false
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Show password activated", comment: "")
        } else {
            passwordTextField.textField.isSecureTextEntry = true
            eyeballButton.setImage(#imageLiteral(resourceName: "ic_eyeball_disabled"), for: .normal)
            eyeballButton.accessibilityLabel = NSLocalizedString("Hide password activated", comment: "")
        }
    }

    @IBAction func onBiometricsButtonPress() {
        FirebaseUtility.logEvent(.login, parameters: [EventParameter(parameterName: .action, value: .biometrics_press)])
        
        navigationController?.view.isUserInteractionEnabled = false

        // This delay is necessary to make setting isUserInteractionEnabled work properly -- do not remove
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
            self.presentBiometricsPrompt()
        })
    }

    func launchMainApp(isStormMode: Bool) {
        FirebaseUtility.setUserPropety(.isBiometricsEnabled, value: viewModel.biometricsEnabled.value.description)
        FirebaseUtility.setUserPropety(.isKeepMeSignedInEnabled, value: viewModel.keepMeSignedIn.value.description)

        FirebaseUtility.logEvent(.loginAccountNetworkComplete)
        GoogleAnalytics.log(event: .loginComplete)

        if isStormMode {
            (UIApplication.shared.delegate as? AppDelegate)?.showStormMode()
        } else {
            guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController,
                let navController = self.navigationController else {
                    return
            }
            navController.navigationBar.prefersLargeTitles = false
            navController.navigationItem.largeTitleDisplayMode = .never
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

            GoogleAnalytics.log(event: .loginOffer,
                                 dimensions: [.keepMeSignedIn: self.keepMeSignedInCheckbox.isChecked ? "true":"false",
                                              .fingerprintUsed: "enabled"])

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Loading", comment: ""))
            })
            self.passwordTextField.textField.sendActions(for: .editingDidEnd) // Update the text field appearance
            self.signInButton.setLoading()
            self.signInButton.accessibilityLabel = NSLocalizedString("Loading", comment: "")
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

        let safeAreaBottomInset = view.safeAreaInsets.bottom
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets

        let rect = signInButton.convert(signInButton.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: true)
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - Other

    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        if let navController = segue.destination as? LargeTitleNavigationController,
            let vc = navController.viewControllers.first as? ForgotPasswordViewController {
            vc.delegate = self
        }
    }

}

extension LoginViewController: ForgotPasswordViewControllerDelegate {

    func forgotPasswordViewControllerDidSubmit(_ viewController: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Temporary password sent to your email", comment: ""))
            GoogleAnalytics.log(event: .forgotPasswordComplete)
        })
    }
}

extension LoginViewController: ForgotUsernameSecurityQuestionViewControllerDelegate {

    func forgotUsernameSecurityQuestionViewController(_ forgotUsernameSecurityQuestionViewController: ForgotUsernameSecurityQuestionViewController, didUnmaskUsername username: String) {
        viewModel.username.value = username
        GoogleAnalytics.log(event: .forgotUsernameCompleteAutoPopup)
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
