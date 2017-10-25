//
//  SmartEnergyRewardsHistoryViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TotalSavingsViewController: UIViewController {
    
    var eventResults: [SERResult]! // Passed from HomeViewController/UsageViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Total Savings", comment: "")
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }

}
