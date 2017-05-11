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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if(ServiceFactory.createAuthenticationService().isAuthenticated()) {
            ServiceFactory.createAuthenticationService().refreshAuthorization(completion: { (result: ServiceResult<Void>) in })
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            self.present(viewController!, animated: true, completion: nil)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                if !self.performingDeepLink { // Deep link cold-launched the app, so let our logic below handle it
                    self.performSegue(withIdentifier: "landingSegue", sender: self)
                }
            })
        }
        
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb { // Universal Link from Reset Password email
            self.performingDeepLink = true
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let landingVC = storyboard.instantiateViewController(withIdentifier: "landingViewController")
            let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController")
            navigationController?.setViewControllers([self, landingVC, loginVC], animated: true)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
