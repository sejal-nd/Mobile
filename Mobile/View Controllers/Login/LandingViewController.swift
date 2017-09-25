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

        // TODO: Remove test code
        let infoModal = TutorialModalViewController()
        infoModal.addSlide(title: "Set Up Default Payment Account",
                                   text: "You can easily pay your bill in full from the Home " +
            "screen by setting a payment account as default.",
                                   animation: "otp_step1")
        infoModal.addSlide(title: "Tap On My Wallet",
                 text: "Navigate to the Bill screen and tap \"My Wallet.\" " +
                    "You can also tap the \"Set a default payment account\" button " +
            "on Home.",
                 animation: "otp_step2")
        infoModal.addSlide(title: "Turn On The Default Toggle",
                 text: "Create or edit a payment account and turn on the " +
            "\"Default Payment Account\" toggle.",
                 animation: "otp_step3")
        infoModal.addSlide(title: "Pay From The Home Screen!",
                 text: "You can now easily pay from the Home screen. This " +
                    "type of payment cannot be canceled and will pay your account " +
            "balance in full.",
                 animation: "otp_step4")
        self.navigationController?.present(infoModal, animated: true, completion: nil)
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
