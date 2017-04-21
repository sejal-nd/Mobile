//
//  WhatIsBudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WhatIsBudgetBillingViewController: DismissableFormSheetViewController {

    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var navTitleLabel: UILabel!
    @IBOutlet weak var navDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryColor

        xButton.imageView?.tintColor = .primaryColor
        
        navBar.layer.shadowRadius = 3
        navBar.layer.shadowColor = UIColor.black.cgColor
        navBar.layer.shadowOpacity = 0.2
        navBar.layer.shadowOffset = CGSize(width: 0, height: 1)
        navBar.layer.masksToBounds = false
        
        navTitleLabel.textColor = .darkJungleGreen
        navTitleLabel.text = NSLocalizedString("What is Budget Billing?", comment: "")
        
        navDescriptionLabel.textColor = .outerSpace
        navDescriptionLabel.setLineHeight(lineHeight: 25)
    }

    @IBAction func onXPress() {
        dismiss(animated: true, completion: nil)
    }
}
