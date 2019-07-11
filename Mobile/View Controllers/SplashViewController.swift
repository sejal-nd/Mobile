//
//  SplashViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Lottie

class SplashViewController: UIViewController{
    @IBOutlet weak var imageView: UIView!
    
    @IBOutlet weak var splashAnimationContainer: UIView!
    var splashAnimationView: LOTAnimationView?
    
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var loadingAnimationContainer: UIView!
    var loadingAnimationView: LOTAnimationView?
    @IBOutlet weak var loadingLabel: UILabel!
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorViewBackground: UIView!
    @IBOutlet weak var errorTitleLabel: UILabel!
    @IBOutlet weak var errorTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var retryButton: ButtonControl!
    
    var performDeepLink = false
    var keepMeSignedIn = false
    var shortcutItem = ShortcutItem.none
    
    var loadingTimer = Timer()
    
    let viewModel = SplashViewModel(authService: ServiceFactory.createAuthenticationService())
    
    var bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
        
        loadingLabel.font = OpenSans.semibold.of(size: 18)
        loadingLabel.text = NSLocalizedString("We’re Working on Loading the App…", comment: "")
        
        errorViewBackground.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        errorViewBackground.layer.cornerRadius = 10
        
        errorTitleLabel.textColor = .deepGray
        errorTitleLabel.text = viewModel.errorTitleText
        
        errorTextView.tintColor = .actionBlue // For the phone numbers
        errorTextView.attributedText = viewModel.errorLabelText

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification, object: nil)
            .skip(1) // Ignore the initial notification that fires, causing a double call to checkAppVersion
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.checkAppVersion { [weak self] in
                    self?.doLoginLogic()
                }
            })
            .disposed(by: bag)
        
        if ServiceFactory.createAuthenticationService().isAuthenticated() {
            self.keepMeSignedIn = true
            self.imageView.isHidden = false
            self.splashAnimationContainer.isHidden = true
        } else {
            imageView.isHidden = true
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(loadingTimerExpired), userInfo: nil, repeats: false)
        checkAppVersion { [weak self] in
            self?.doLoginLogic()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !keepMeSignedIn && splashAnimationView == nil {
            splashAnimationView = LOTAnimationView(name: "splash")
            splashAnimationView!.frame.size = splashAnimationContainer.frame.size
            splashAnimationView!.loopAnimation = false
            splashAnimationView!.contentMode = .scaleAspectFit
            splashAnimationContainer.addSubview(splashAnimationView!)
            splashAnimationView!.play()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                UIAccessibility.post(notification: .announcement, argument: Environment.shared.opco.taglineString)
            }
        }
        
        if loadingAnimationView == nil {
            loadingAnimationView = LOTAnimationView(name: "full_screen_loading")
            loadingAnimationView!.frame.size = loadingAnimationContainer.frame.size
            loadingAnimationView!.loopAnimation = true
            loadingAnimationContainer.addSubview(loadingAnimationView!)
            loadingAnimationView!.play()
        }
    }

    func doLoginLogic() {
        bag = DisposeBag() // Disposes our UIApplicationDidBecomeActive subscription - important because that subscription is fired after Touch/Face ID alert prompt is dismissed
        
        if keepMeSignedIn {
            viewModel.checkStormMode { [weak self] isStormMode in
                guard let this = self else { return }
                this.loadingTimer.invalidate()
                
                if isStormMode {
                    (UIApplication.shared.delegate as? AppDelegate)?.showStormMode()
                } else {
                    guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController,
                        let navController = this.navigationController else {
                            return
                    }
                    
                    if #available(iOS 11.0, *) {
                        navController.navigationBar.prefersLargeTitles = false
                        navController.navigationItem.largeTitleDisplayMode = .never
                    }
                    
                    navController.setViewControllers([viewController], animated: false)
                    if this.shortcutItem != .none {
                        NotificationCenter.default.post(name: .didTapOnShortcutItem, object: this.shortcutItem)
                    }
                }
                
                this.checkIOSVersion()
            }
        } else {
            loadingTimer.invalidate()
            
            let navigate = { [weak self] in
                guard let self = self else { return }
                if self.performDeepLink {
                    let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    let landingVC = storyboard.instantiateViewController(withIdentifier: "landingViewController")
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController")
                    self.navigationController?.setViewControllers([landingVC, loginVC], animated: false)
                    self.performDeepLink = false // Reset state
                } else if self.shortcutItem == .reportOutage {
                    let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
                    let landing = loginStoryboard.instantiateViewController(withIdentifier: "landingViewController")
                    let unauthenticatedUser = loginStoryboard.instantiateViewController(withIdentifier: "unauthenticatedUserViewController")
                    guard let unauthenticatedOutageValidate = loginStoryboard
                        .instantiateViewController(withIdentifier: "unauthenticatedOutageValidateAccountViewController")
                        as? UnauthenticatedOutageValidateAccountViewController else {
                            return
                    }
                    
                    let vcArray = [landing, unauthenticatedUser, unauthenticatedOutageValidate]
                    
                    GoogleAnalytics.log(event: .reportAnOutageUnAuthOffer)
                    unauthenticatedOutageValidate.analyticsSource = AnalyticsOutageSource.report
                    
                    self.navigationController?.setViewControllers(vcArray, animated: true)
                } else if self.shortcutItem == .alertPreferences {
                    let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
                    let landing = loginStoryboard.instantiateViewController(withIdentifier: "landingViewController")
                    let login = loginStoryboard.instantiateViewController(withIdentifier: "loginViewController")
                    
                    self.navigationController?.setViewControllers([landing, login], animated: false)
                    
                    let alert = UIAlertController(title: NSLocalizedString("You must be signed in to adjust alert preferences.", comment: ""),
                                                  message: NSLocalizedString("You can turn the \"Keep me signed in\" toggle ON for your convenience.", comment: ""),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    landing.present(alert, animated: true, completion: nil)
                } else {
                    self.performSegue(withIdentifier: "landingSegue", sender: self)
                }
                self.checkIOSVersion()
            }
            
            if self.splashAnimationView == nil || !self.splashAnimationView!.isAnimationPlaying {
                navigate()
            } else {
                self.splashAnimationView!.completionBlock = { _ in
                    navigate()
                }
            }
        }
    }
    
    func checkAppVersion(callback: @escaping() -> Void) {
        viewModel.checkAppVersion(onSuccess: { [weak self] isOutOfDate in
            if isOutOfDate {
                self?.handleOutOfDate()
            } else {
                callback()
            }
        }, onError: { [weak self] _ in
            self?.loadingTimer.invalidate()
            self?.imageView.isHidden = true
            self?.splashAnimationContainer.isHidden = true
            self?.loadingContainerView.isHidden = true
            self?.errorView.isHidden = false
        })
    }
    
    func checkIOSVersion() {
        // Warn iOS 9 users that we will soon not support their iOS version
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.doNotShowIOS9VersionWarningAgain) == false &&
            UIDevice.current.systemVersion.compare("10.0", options: NSString.CompareOptions.numeric) == .orderedAscending {
            NotificationCenter.default.post(name: .shouldShowIOSVersionWarning, object: nil)
        }
    }
    
    func handleOutOfDate() {
        let requireUpdateAlert = UIAlertController(title: nil , message: NSLocalizedString("There is a newer version of this application available. Tap OK to update now.", comment: ""), preferredStyle: .alert)
        requireUpdateAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
            UIApplication.shared.openUrlIfCan(Environment.shared.opco.appStoreLink)
        })
        present(requireUpdateAlert,animated: true, completion: nil)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb { // Universal Link from Reset Password email
            performDeepLink = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Timeout and Error States

    @objc func loadingTimerExpired() {
        imageView.isHidden = true
        splashAnimationContainer.isHidden = true
        loadingContainerView.isHidden = false
    }
    
    @IBAction func onRetryPress(_ sender: Any) {
        errorView.isHidden = true
        loadingContainerView.isHidden = false
        checkAppVersion { [weak self] in
            self?.doLoginLogic()
        }
    }
    
}
