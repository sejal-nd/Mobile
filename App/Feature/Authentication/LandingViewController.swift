//
//  LandingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import AuthenticationServices
import Lottie

#if canImport(SwiftUI)
import SwiftUI
#endif

class LandingViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var logoBackgroundView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var signInButton: PrimaryButton!
    @IBOutlet weak var registerButton: SecondaryButton!
    @IBOutlet weak var continueAsGuestButon: UIButton!
    @IBOutlet weak var tabletView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var debugButton: UIButton!
    @IBOutlet weak var videoView: UIView!

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    private var viewDidAppear = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.setTitle(NSLocalizedString("Sign In", comment: ""), for: .normal)
        signInButton.hasBlueAnimations = true
        registerButton.setTitle(NSLocalizedString("Register for Online Access", comment: ""), for: .normal)
        continueAsGuestButon.setTitle(NSLocalizedString("Continue as Guest", comment: ""), for: .normal)
        continueAsGuestButon.titleLabel?.font = .headlineSemibold
        
//        logoBackgroundView.backgroundColor = .primaryColor
        view.backgroundColor = .primaryColor
        
        // Version Label
        if let version = Bundle.main.versionNumber {
            versionLabel.text = "Version \(version)"
        } else {
            versionLabel.text = nil
        }
        
        // Debug Button
        switch Configuration.shared.environmentName {
        case .aut, .beta:
            debugButton.isHidden = false
            debugButton.isEnabled = true
        default:
            debugButton.isHidden = true
            debugButton.isEnabled = false
        }
        
        versionLabel.font = .footnote
        
        logoBackgroundView.alpha = 0
        videoView.alpha = 0
        tabletView.alpha = 0
        versionLabel.alpha = 0
        
        logoBackgroundView.addShadow(color: .primaryColorDark, opacity: 0.5, offset: CGSize(width: 0, height: 9), radius: 11)
        let a11yText = NSLocalizedString("%@, an Exelon Company", comment: "")
        logoImageView.accessibilityLabel = String(format: a11yText, Configuration.shared.opco.displayString)
        
        (UIApplication.shared.delegate as? AppDelegate)?.checkIOSVersion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always

        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        startBackgroundAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !UserDefaults.standard.bool(forKey: UserDefaultKeys.hasAcceptedTerms) {
            performSegue(withIdentifier: "termsPoliciesModalSegue", sender: self)
        }
        
        if !viewDidAppear {
            viewDidAppear = true
            UIView.animate(withDuration: 0.5) {
                self.logoBackgroundView.alpha = 1
                self.videoView.alpha = 1
                self.tabletView.alpha = 1
                self.versionLabel.alpha = 1
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        backgroundImageView.layer.removeAllAnimations()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func willResignActive() {
        backgroundImageView.layer.removeAllAnimations()
    }

    @objc private func didBecomeActive() {
        startBackgroundAnimation()
    }
    
    
    // MARK: - Actions
    
    @IBAction func onContinueAsGuestPress(_ sender: UIButton) {
        performSegue(withIdentifier: "UnauthenticatedUserSegue", sender: self)
    }
    
    @IBAction func onSignInPress() {
        getMaintenanceMode { [weak self] maintenanceMode in
            if let maintenanceMode = maintenanceMode, maintenanceMode.all {
                // Maint mode all is on
                (UIApplication.shared.delegate as? AppDelegate)?.showMaintenanceMode(maintenanceMode)
            } else {
                if FeatureFlagUtility.shared.bool(forKey: .isPkceAuthentication) {
                    // Present ASWebAuthentication
                    self?.signInButton.tintWhite = true
                    self?.signInButton.setLoading()
                    self?.signInButton.accessibilityLabel = NSLocalizedString("Loading", comment: "")
                    self?.signInButton.accessibilityViewIsModal = true
                    
                    PKCEAuthenticationService.default.presentLoginForm { [weak self] result in
                        guard let self = self else { return }
                        switch (result) {
                        case .success(let pkceResult):
                            if pkceResult.tokenResponse != nil {
                                self.handleLoginSuccess()
                            } else if pkceResult.redirect == "find_email" {
                                Log.info("redirect to find email flow")
                                self.signInButton.reset()
                                self.signInButton.setTitle("Sign In", for: .normal)
                                self.signInButton.accessibilityLabel = "Sign In"
                                self.signInButton.accessibilityViewIsModal = false
                                
                                FirebaseUtility.logEvent(.login(parameters: [.forgot_username_press]))
                                GoogleAnalytics.log(event: .forgotUsernameOffer)
                                
                                self.performSegue(withIdentifier: "forgotUsernameSegue", sender: self)
                            } else {
                                self.signInButton.reset()
                                self.signInButton.setTitle("Sign In", for: .normal)
                                self.signInButton.accessibilityLabel = "Sign In"
                                self.signInButton.accessibilityViewIsModal = false
                            }
                        case .failure(let error):
                            self.signInButton.reset()
                            self.signInButton.setTitle("Sign In", for: .normal)
                            self.signInButton.accessibilityLabel = "Sign In"
                            self.signInButton.accessibilityViewIsModal = false
                            
                            let sessionError = ASWebAuthenticationSessionError.Code(rawValue: (error as NSError).code)
                            if sessionError != ASWebAuthenticationSessionError.canceledLogin {
                                self.showErrorAlertWith(title: nil, message: error.localizedDescription)
                            }
                        }
                    }
                } else {
                    self?.performSegue(withIdentifier: "loginSegue", sender: self)
                }
            }
        }
    }
    
    func handleLoginSuccess() {
        self.getMaintenanceMode { maintenanceMode in
            if maintenanceMode?.all ?? false {
                (UIApplication.shared.delegate as? AppDelegate)?.showMaintenanceMode(maintenanceMode)
            } else if maintenanceMode?.storm ?? false {
                (UIApplication.shared.delegate as? AppDelegate)?.showStormMode()
            } else {
                self.signInButton.reset()
                self.signInButton.accessibilityLabel = "Sign In"
                self.signInButton.accessibilityViewIsModal = false
                
                self.signInButton.setSuccess {
                    FirebaseUtility.logEvent(.initialAuthenticatedScreenStart)
                    GoogleAnalytics.log(event: .loginComplete)

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
        }
    }
    
    func getMaintenanceMode(completion: @escaping (MaintenanceMode?) -> ()) {
        AnonymousService.maintenanceMode { (result: Result<MaintenanceMode, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let maintenanceMode):
                    completion(maintenanceMode)
                case .failure(_):
                    completion(nil)
                }
            }
        }
    }
    
    func showErrorAlertWith(title: String?, message: String) {
        Log.info("login failed")

        let errorAlert = UIAlertController(title: title != nil ? title : NSLocalizedString("Sign In Error", comment: ""), message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        present(errorAlert, animated: true, completion: nil)
    }
    
    func show2SVJustEnabled() {
        let twoSVEnabledAlert = InfoAlertController(title: NSLocalizedString("You are set up to use Two-Step Verification.", comment: ""),
                                                    message: NSLocalizedString("Two-Step Verification is now enabled. In the future, we'll notify you whenever someone attempts to log in to your account.", comment: ""),
                                                    icon: #imageLiteral(resourceName: "ic_confirmation_mini"))
        
        self.present(twoSVEnabledAlert, animated: true, completion: nil)
    }
    
    func show2SVReminder() {
        let action = InfoAlertAction(ctaText: NSLocalizedString("Enable Two-Step Verification", comment: ""))
        
        let alert = InfoAlertController(title: NSLocalizedString("Two-Step Verification is not enabled.", comment: ""),
                                        message: NSLocalizedString("To enable this feature or make changes, go to the more tab.", comment: ""),
                                        action: action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showFindEmailAlert(foundEmail: String) {
        let action = InfoAlertAction(ctaText: NSLocalizedString("Copy email to clipboard", comment: "")) {
            UIPasteboard.general.string = foundEmail
            self.view.showToast(NSLocalizedString("Email copied to clipboard", comment: ""))
        }
        
        let alert = InfoAlertController(title: NSLocalizedString("Email Found", comment: ""),
                                        message: NSLocalizedString("You may now use \(foundEmail) to login to your account", comment: ""),
                                        action: action)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onRegistrationInPress() {
        performSegue(withIdentifier: "registrationSegueNew", sender: self)
    }
    
    @IBAction func onDebugMenuPress(_ sender: Any) {
        switch Configuration.shared.environmentName {
        case .aut, .beta:
            if #available(iOS 14, *) {
                let debugViewHostingController = UIHostingController(rootView: DebugMenu() { [weak self] in
                    self?.dismiss(animated: true, completion: nil)
                })
                present(debugViewHostingController, animated: true, completion: nil)
            }
        default:
            break
        }
    }
    
    
    // MARK: - Helper

    private func startBackgroundAnimation() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Double.pi * 2 // negative can control direction
        rotationAnimation.duration = 180.0
        rotationAnimation.repeatCount = .infinity
        
        backgroundImageView.layer.add(rotationAnimation, forKey: nil)
        backgroundImageView.clipsToBounds = false
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let navController = segue.destination as? LargeTitleNavigationController,
           let vc = navController.viewControllers.first as? LandingRegisterViewController {
            vc.delegate = self
        }
    }
}


extension LandingViewController: RegistrationViewControllerDelegate {
    func registrationViewControllerDidRegister(_ registrationViewController: UIViewController) {
        if FeatureFlagUtility.shared.bool(forKey: .isB2CAuthentication) {
            if RxNotifications.shared.mfaBypass.value {
                RxNotifications.shared.mfaBypass.accept(false)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                    UIApplication.shared.keyWindow?.rootViewController?.view.showToast(NSLocalizedString("Two-Step Verification is not enabled.", comment: ""))
                })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5500), execute: {
                    UIApplication.shared.keyWindow?.rootViewController?.view.showToast(NSLocalizedString("Account registered", comment: ""))
                })
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                    UIApplication.shared.keyWindow?.rootViewController?.view.showToast(NSLocalizedString("Account registered", comment: ""))
                })
            }
        } else {
            performSegue(withIdentifier: "loginSegue", sender: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                UIApplication.shared.keyWindow?.rootViewController?.view.showToast(NSLocalizedString("Account registered", comment: ""))
            })
        }
    }
}

extension LandingViewController: ForgotUsernameResultViewControllerDelegate {
    func forgotUsernameResultViewController(_ forgotUsernameResultViewController: UIViewController, didUnmaskUsername username: String) {
        Log.info("unmasked email is \(username)")
        GoogleAnalytics.log(event: .forgotUsernameCompleteAutoPopup)
        
        DispatchQueue.main.async {
            self.showFindEmailAlert(foundEmail: username)
        }
    }
}

extension LandingViewController: AccountLookUpValidatePinViewControllerDelegate {
    func accountLookUpValidatePinViewController(_ accountLookUpValidatePinViewController: UIViewController, didUnmaskUsername username: String) {
        Log.info("unmasked email is \(username)")
        GoogleAnalytics.log(event: .forgotUsernameCompleteAutoPopup)
        
        DispatchQueue.main.async {
            self.showFindEmailAlert(foundEmail: username)
        }
    }
}
