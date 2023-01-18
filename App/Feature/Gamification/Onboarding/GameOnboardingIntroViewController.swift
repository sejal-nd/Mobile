//
//  GameOnboardingIntroViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameOnboardingIntroViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    var accountDetail: AccountDetail! // Passed from HomeViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        closeButton.tintColor = .actionBrand
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        
        label.textColor = .neutralDarker
        label.font = .title3
        label.text = NSLocalizedString("In order to personalize your experience, we’d like to ask you a few questions!", comment: "")
    }
    
    @IBAction func onClosePress() {
        dismissModal()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? GameOnboardingStep1ViewController {
            vc.accountDetail = accountDetail
        }
    }
    
}
