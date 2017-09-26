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
    @IBOutlet weak var continueAsGuestButon: UIButton!
    @IBOutlet weak var tabletView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    
    var fadeIn = false

    override func viewDidLoad() {
        super.viewDidLoad()

        signInButton.setTitle(NSLocalizedString("Sign In", comment: ""), for: .normal)
        orLabel.text = NSLocalizedString("OR", comment: "")
        registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        continueAsGuestButon.setTitle(NSLocalizedString("CONTINUE AS GUEST", comment: ""), for: .normal)

        orLabel.font = SystemFont.regular.of(textStyle: .headline)
        continueAsGuestButon.titleLabel?.font = SystemFont.bold.of(textStyle: .title1)

        view.backgroundColor = .primaryColor

        if fadeIn {
            tabletView.alpha = 0
        }
        
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            versionLabel.text = String(format: NSLocalizedString("Version %@", comment: ""), version)
        } else {
            versionLabel.text = nil
        }
        
        versionLabel.font = OpenSans.regular.of(textStyle: .footnote)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!UserDefaults.standard.bool(forKey: UserDefaultKeys.HasAcceptedTerms)) {
            performSegue(withIdentifier: "termsPoliciesModalSegue", sender: self)
        }

        UIView.animate(withDuration: 0.33, animations: {
            self.tabletView.alpha = 1
        })
    }
    
    @IBAction func onContinueAsGuestPress(_ sender: UIButton) {
        performSegue(withIdentifier: "UnauthenticatedUserSegue", sender: self)
    }
    
    @IBAction func onSignInPress() {
        performSegue(withIdentifier: "loginSegue", sender: self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
 
}
