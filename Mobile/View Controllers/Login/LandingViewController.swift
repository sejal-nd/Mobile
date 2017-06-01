//
//  LandingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController {

    @IBOutlet weak var signInButton: SecondaryButton!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var registerButton: SecondaryButton!
    @IBOutlet weak var skipForNowButon: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.setTitle(NSLocalizedString("Sign In", comment: ""), for: .normal)
        orLabel.text = NSLocalizedString("OR", comment: "")
        registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        skipForNowButon.setTitle(NSLocalizedString("SKIP FOR NOW", comment: ""), for: .normal)
        
        orLabel.font = SystemFont.regular.of(textStyle: .headline)
        skipForNowButon.titleLabel?.font = SystemFont.bold.of(textStyle: .title1)
        
        view.backgroundColor = .primaryColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!UserDefaults.standard.bool(forKey: UserDefaultKeys.HasAcceptedTerms)) {
            performSegue(withIdentifier: "termsPoliciesModalSegue", sender: self)
        }
        
    }
    
    @IBAction func onSkipForNowPress(_ sender: UIButton) {
//        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
//        self.present(viewController!, animated: true, completion: nil)
    }
    
    @IBAction func onSignInPress() {
        performSegue(withIdentifier: "loginSegue", sender: self)
    }
    
    @IBAction func onRegisterPress(_ sender: Any) {
        performSegue(withIdentifier: "loadRegisterSegue", sender: self)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb { // Universal Link from Reset Password email
            var loginAlreadyInNavStack = false
            for vc in (navigationController?.viewControllers)! {
                if vc.isKind(of: LoginViewController.self) {
                    loginAlreadyInNavStack = true
                    break
                }
            }
            if !loginAlreadyInNavStack {
                performSegue(withIdentifier: "loginSegue", sender: self)
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
 
}
