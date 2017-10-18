//
//  UsageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UsageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Usage", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }


}
