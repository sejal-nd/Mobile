//
//  LandingRegisterViewController.swift
//  EUMobile
//
//  Created by Tiwari, Anurag on 10/10/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

class LandingRegisterViewController: UIViewController {

    weak var delegate: RegistrationViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseUtility.logEvent(.register(parameters: [.register_mobile_landing]))
        title = NSLocalizedString("Register", comment: "")
        addCloseButton()
    }
  
    @IBAction func onContinuePress(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Login", bundle: Bundle.main)
        if let reportOutageVC = storyboard.instantiateViewController(withIdentifier: "RegistrationValidateAccountViewControllerNew") as? RegistrationValidateAccountViewControllerNew {
            reportOutageVC.delegate = delegate
            self.navigationController?.pushViewController(reportOutageVC, animated: true)
        }
    }
}


