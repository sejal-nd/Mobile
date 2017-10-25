//
//  SmartEnergyRewardsHistoryViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class SmartEnergyRewardsHistoryViewController: UIViewController {
    
    var eventResults: [SERResult]! // Passed from HomeViewController/UsageViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Environment.sharedInstance.opco == .comEd ? NSLocalizedString("Total Peak Time Savings", comment: "") :
            NSLocalizedString("Total Smart Energy Rewards", comment: "")
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }

}
