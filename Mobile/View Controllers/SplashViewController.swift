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

class SplashViewController: UIViewController{
    
    var performingDeepLink = false
    var bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
        NotificationCenter.default.rx.notification(.UIApplicationDidBecomeActive, object: nil)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.checkAppVersion()
            })
            .disposed(by: bag)
    }
    
    let viewModel = SplashViewModel(authService: ServiceFactory.createAuthenticationService())
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAppVersion()
    }    
    
    func doLoginLogic() {
        bag = DisposeBag() // Disposes our UIApplicationDidBecomeActive subscription - important because that subscription is fired after Touch ID alert prompt is dismissed
        if ServiceFactory.createAuthenticationService().isAuthenticated() {
            ServiceFactory.createAuthenticationService().refreshAuthorization(completion: { [weak self] (result: ServiceResult<Void>) in
                guard let `self` = self else { return }
                switch (result) {
                case .Success:
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                    self.present(viewController!, animated: true, completion: nil)
                case .Failure:
                    self.performSegue(withIdentifier: "landingSegue", sender: self)
                }
            })
            
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                if !self.performingDeepLink { // Deep link cold-launched the app, so let our logic below handle it
                    self.performSegue(withIdentifier: "landingSegue", sender: self)
                } else {
                    self.performingDeepLink = false // Reset state
                }
            })
        }
    }
    
    func checkAppVersion() {
        viewModel.checkAppVersion(onSuccess: { [weak self] isOutOfDate in
            if isOutOfDate {
                self?.handleOutOfDate()
            } else {
                self?.doLoginLogic()
            }
        }, onError: { [weak self] _ in
            self?.doLoginLogic()
        })
    }
    
    func handleOutOfDate(){
        let requireUpdateAlert = UIAlertController(title: nil , message: NSLocalizedString("There is a newer version of this application available. Tap OK to update now.", comment: ""), preferredStyle: .alert)
        requireUpdateAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            let appStoreLink = "https://itunes.apple.com/us/app/apple-store/id927221466?mt=8"
            
            /* First create a URL, then check whether there is an installed app that can
             open it on the device. */
            if let url = URL(string: appStoreLink), UIApplication.shared.canOpenURL(url) {
                // Attempt to open the URL.
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: {(success: Bool) in
                        if success {
                            print("Launching \(url) was successful")
                        }})
                } else {
                    if let url = URL(string: "https://itunes.apple.com/us/app/exelon-link/id927221466?mt=8"){
                        print(url)
                        UIApplication.shared.openURL(url)
                    }
                }
            }
        }))

        present(requireUpdateAlert,animated: true, completion: nil)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb { // Universal Link from Reset Password email
            performingDeepLink = true
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let landingVC = storyboard.instantiateViewController(withIdentifier: "landingViewController")
            let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController")
            navigationController?.setViewControllers([landingVC, loginVC], animated: false)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
