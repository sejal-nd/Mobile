//
//  SplashViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    
    var performingDeepLink = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
    }
    
    let viewModel = SplashViewModel(authService: ServiceFactory.createAuthenticationService())
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //doLoginLogic()
        
        checkAppVersion()
    }

    func doLoginLogic() {
        if ServiceFactory.createAuthenticationService().isAuthenticated() {
            ServiceFactory.createAuthenticationService().refreshAuthorization(completion: { (result: ServiceResult<Void>) in
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
        }, onError: { errorMessage in
//            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
//            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    func handleOutOfDate(){
        let requireUpdateAlert = UIAlertController(title: nil , message: NSLocalizedString("There is a newer version of this application available. Tap OK to update now.", comment: ""), preferredStyle: .alert)
        requireUpdateAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id927221466"),
                UIApplication.shared.canOpenURL(url)
            {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }))

        present(requireUpdateAlert,animated: true, completion: nil)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb { // Universal Link from Reset Password email
            self.performingDeepLink = true
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
