//
//  LandingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryColor
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!UserDefaults.standard.bool(forKey: UserDefaultKeys.HasAcceptedTerms)) {
            performSegue(withIdentifier: "termsPoliciesModalSegue", sender: self)
        }
        
    }
    
    @IBAction func onSkipForNowPress(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.present(viewController!, animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
 
}
