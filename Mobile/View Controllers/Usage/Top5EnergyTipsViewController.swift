//
//  Top5EnergyTipsViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class Top5EnergyTipsViewController: DismissableFormSheetViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = .blackText
        
    }

    @IBAction func xPressed(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
