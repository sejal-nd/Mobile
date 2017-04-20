//
//  WhatIsBudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WhatIsBudgetBillingViewController: UIViewController {

    @IBOutlet weak var xButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        xButton.imageView?.tintColor = .primaryColor
    }

    @IBAction func onXPress() {
        dismiss(animated: true, completion: nil)
    }
}
