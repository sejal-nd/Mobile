//
//  OpcoUpdateDetailViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UpdatesDetailViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    var opcoUpdate: OpcoUpdate! // Passed from AlertsViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        title = opcoUpdate.title
        
        label.textColor = .blackText
        label.font = OpenSans.regular.of(textStyle: .body)
        label.text = opcoUpdate.message
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }

}
