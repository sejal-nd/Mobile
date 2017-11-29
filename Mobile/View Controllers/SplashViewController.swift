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
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var imageView: UIView!
    
    var performDeepLink = false
    var bag = DisposeBag()
    var lottieAnimation: LOTAnimationView?
    var keepMeSignedIn: Bool = false
    
    let viewModel = SplashViewModel(authService: ServiceFactory.createAuthenticationService())

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
        
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
                    self.animationView.isHidden = true
                case .Failure:
                    self.keepMeSignedIn = false
                    self.imageView.isHidden = true
                    self.animationView.isHidden = false
                }
            })
        } else {
            imageView.isHidden = true
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkAppVersion(callback: {
            self.doLoginLogic()
        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !keepMeSignedIn && lottieAnimation == nil {
            lottieAnimation = LOTAnimationView(name: "splash")
            lottieAnimation!.frame = CGRect(x: 0, y: 0, width: animationView.frame.size.width, height: animationView.frame.size.height)
            lottieAnimation!.loopAnimation = false
            lottieAnimation!.contentMode = .scaleAspectFit
            animationView.addSubview(lottieAnimation!)
            lottieAnimation!.play()
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
            
            if self.lottieAnimation == nil || !self.lottieAnimation!.isAnimationPlaying {
                navigate()
            } else {
                self.lottieAnimation!.completionBlock = { _ in
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
        }, onError: { _ in
            callback()
        })
    }
    
    func getAppStoreLink() -> String{
        if Environment.sharedInstance.opco == .bge {
            return "https://itunes.apple.com/us/app/bge-an-exelon-company/id1274170174?ls=1&mt=8"
        } else if Environment.sharedInstance.opco == .peco {
            return "https://itunes.apple.com/us/app/peco-an-exelon-company/id1274171957?ls=1&mt=8"
        } else {
            //TODO once we get ComEd link
        }
        return ""
    }
    
    func handleOutOfDate(){
        let requireUpdateAlert = UIAlertController(title: nil , message: NSLocalizedString("There is a newer version of this application available. Tap OK to update now.", comment: ""), preferredStyle: .alert)
        requireUpdateAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            let appStoreLink = self.getAppStoreLink()
            
            /* First create a URL, then check whether there is an installed app that can
             open it on the device. */
            if let url = URL(string: appStoreLink), UIApplication.shared.canOpenURL(url) {
                // Attempt to open the URL.
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: {(success: Bool) in
                        if success {
                            dLog("Launching \(url) was successful")
                        }})
                } else {
                    if let url = URL(string: "https://itunes.apple.com/us/app/exelon-link/id927221466?mt=8"){
                        UIApplication.shared.openURL(url)
                    }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LandingViewController {
            vc.fadeIn = !keepMeSignedIn
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
