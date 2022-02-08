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
    
    private var playerLayer: AVPlayerLayer!
    private var avPlayer: AVPlayer?
    private var avPlayerPlaybackTime = CMTime.zero
    
    private var viewDidAppear = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.setTitle(NSLocalizedString("Sign In", comment: ""), for: .normal)
        signInButton.hasBlueAnimations = true
        if Configuration.shared.opco == .peco {
            registerButton.setTitle(NSLocalizedString("Register for Online Access", comment: ""), for: .normal)
        } else {
            registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        }
        continueAsGuestButon.setTitle(NSLocalizedString("Continue as Guest", comment: ""), for: .normal)
        continueAsGuestButon.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        logoBackgroundView.backgroundColor = .primaryColor
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
        
        versionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        logoBackgroundView.alpha = 0
        videoView.alpha = 0
        tabletView.alpha = 0
        versionLabel.alpha = 0
        
        logoBackgroundView.addShadow(color: .primaryColorDark, opacity: 0.5, offset: CGSize(width: 0, height: 9), radius: 11)
        let a11yText = NSLocalizedString("%@, an Exelon Company", comment: "")
        logoImageView.accessibilityLabel = String(format: a11yText, Configuration.shared.opco.displayString)
        
        backgroundVideoSetup()
        
        (UIApplication.shared.delegate as? AppDelegate)?.checkIOSVersion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        backgroundVideoResume(at: avPlayerPlaybackTime)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        avPlayer?.play()
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let player = avPlayer else { return }
        player.pause()
        avPlayerPlaybackTime = player.currentTime()
        avPlayer = nil
    }
    
    
    // MARK: - Actions
    
    @IBAction func onContinueAsGuestPress(_ sender: UIButton) {
        performSegue(withIdentifier: "UnauthenticatedUserSegue", sender: self)
    }
    
    @IBAction func onSignInPress() {
        
        if FeatureFlagUtility.shared.bool(forKey: .isPkceAuthentication) {
            // Present ASWebAuthentication
            signInButton.tintWhite = true
            signInButton.setLoading()
            signInButton.accessibilityLabel = NSLocalizedString("Loading", comment: "")
            signInButton.accessibilityViewIsModal = true
            
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
            performSegue(withIdentifier: "loginSegue", sender: self)
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
    
    private func backgroundVideoSetup() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        
        view.sendSubviewToBack(videoView)
        let movieUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "landing_video-Flavor\(Configuration.shared.opco.rawValue)", ofType: "mp4")!)
        let asset = AVAsset(url: movieUrl)
        let avPlayerItem = AVPlayerItem(asset: asset)
        avPlayer = AVPlayer(playerItem: avPlayerItem)
        avPlayer?.isMuted = true
        
        playerLayer = AVPlayerLayer(player: avPlayer)
        playerLayer.videoGravity = .resizeAspectFill
        
        let videoWidth: CGFloat
        let videoHeight: CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            // On iPad, the video needs to be square to account for screen rotation
            let widthAndHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            videoWidth = widthAndHeight
            videoHeight = widthAndHeight
        } else {
            videoWidth = UIScreen.main.bounds.width
            videoHeight = UIScreen.main.bounds.height
        }
        playerLayer.frame = CGRect(x: 0, y: 0, width: videoWidth, height: videoHeight)
        
        videoView.layer.addSublayer(playerLayer)
        
        avPlayer?.seek(to: .zero)
        avPlayer?.actionAtItemEnd = .none
        
        NotificationCenter.default.rx.notification(.AVPlayerItemDidPlayToEndTime)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: {
                ($0.object as? AVPlayerItem)?.seek(to: .zero, completionHandler: nil)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.avPlayer?.play()
            })
            .disposed(by: disposeBag)
    }
    
    private func backgroundVideoResume(at playbackTime: CMTime) {
        let movieUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "landing_video-Flavor\(Configuration.shared.opco.rawValue)", ofType: "mp4")!)
        let asset = AVAsset(url: movieUrl)
        let avPlayerItem = AVPlayerItem(asset: asset)
        avPlayer = AVPlayer(playerItem: avPlayerItem)
        avPlayer?.isMuted = true
        avPlayer?.seek(to: playbackTime)
        avPlayer?.actionAtItemEnd = .none
        
        guard let avPlayer = avPlayer else { return }
        playerLayer.player = avPlayer
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let navController = segue.destination as? LargeTitleNavigationController,
           let vc = navController.viewControllers.first as? RegistrationValidateAccountViewControllerNew {
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
