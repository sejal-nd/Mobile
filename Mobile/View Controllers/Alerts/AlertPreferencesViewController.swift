//
//  AlertPreferencesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AlertPreferencesViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    
    let viewModel = AlertPreferencesViewModel()
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Alert Preferences", comment: "")
        
        if Environment.sharedInstance.opco == .bge {
            accountInfoBar.isHidden = true
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    


}
