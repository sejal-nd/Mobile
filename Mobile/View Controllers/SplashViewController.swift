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
    @IBOutlet weak var errorTextView: DataDetectorTextView!
    @IBOutlet weak var retryButton: ButtonControl!
    
    var performDeepLink = false
    var keepMeSignedIn: Bool = false
    
    var loadingTimer = Timer()
    
    let viewModel = SplashViewModel(authService: ServiceFactory.createAuthenticationService())
    
    var bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
        
        loadingLabel.font = OpenSans.semibold.of(size: 18)
        loadingLabel.text = NSLocalizedString("We’re Working on Loading the App…", comment: "")
        
        errorViewBackground.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        errorViewBackground.layer.cornerRadius = 2
        
        errorTitleLabel.textColor = .deepGray
        errorTitleLabel.text = viewModel.errorTitleText
        
        errorTextView.textContainerInset = .zero
        errorTextView.textContainer.lineFragmentPadding = 0
        errorTextView.tintColor = .actionBlue // For the phone numbers
        errorTextView.attributedText = viewModel.errorLabelText

        NotificationCenter.default.rx.notification(.UIApplicationDidBecomeActive, object: nil)
            .skip(1) // Ignore the initial notification that fires, causing a double call to checkAppVersion
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.checkAppVersion(callback: {
                    self?.doLoginLogic()
                })
            })
            .disposed(by: bag)
        
        if ServiceFactory.createAuthenticationService().isAuthenticated() {
            ServiceFactory.createAuthenticationService().refreshAuthorization(completion: { [weak self] (result: ServiceResult<Void>) in
                guard let `self` = self else { return }
                switch (result) {
                case .Success:
                    self.keepMeSignedIn = true
                    self.imageView.isHidden = false
                    self.splashAnimationContainer.isHidden = true
                case .Failure:
                    self.keepMeSignedIn = false
                    self.imageView.isHidden = true
                    self.splashAnimationContainer.isHidden = false
                }
            })
        } else {
            imageView.isHidden = true
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(loadingTimerExpired), userInfo: nil, repeats: false)
        checkAppVersion(callback: {
            self.doLoginLogic()
        })
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
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            self.present(viewController!, animated: true, completion: nil)
        } else {
            let navigate = {
                if self.performDeepLink {
                    let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    let landingVC = storyboard.instantiateViewController(withIdentifier: "landingViewController")
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController")
                    self.navigationController?.setViewControllers([landingVC, loginVC], animated: false)
                    self.performDeepLink = false // Reset state
                } else {
                    self.performSegue(withIdentifier: "landingSegue", sender: self)
                }
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
    
    func checkAppVersion(callback:@escaping()->Void) {
        viewModel.checkAppVersion(onSuccess: { [weak self] isOutOfDate in
            if isOutOfDate {
                self?.handleOutOfDate()
            } else {
                callback()
            }
        }, onError: { [weak self] _ in
            self?.splashAnimationContainer.isHidden = true
            self?.loadingContainerView.isHidden = true
            self?.errorView.isHidden = false
        })
    }
    
    func handleOutOfDate(){
        let requireUpdateAlert = UIAlertController(title: nil , message: NSLocalizedString("There is a newer version of this application available. Tap OK to update now.", comment: ""), preferredStyle: .alert)
        requireUpdateAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [weak self] action in
            if let url = self?.viewModel.appStoreLink, UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success: Bool) in })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }))
        present(requireUpdateAlert,animated: true, completion: nil)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb { // Universal Link from Reset Password email
            self.performDeepLink = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Timeout and Error States

    @objc func loadingTimerExpired() {
        loadingContainerView.isHidden = false
    }
    
    @IBAction func onRetryPress(_ sender: Any) {
        errorView.isHidden = true
        loadingContainerView.isHidden = false
        checkAppVersion(callback: {
            self.doLoginLogic()
        })
    }
    
}
