//
//  AccountNumberTooltipViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountNumberTooltipViewController: DismissableFormSheetViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = NSLocalizedString("Where to Look for Your Account Number", comment: "")
        titleLabel.textColor = .blackText
        
        switch Environment.sharedInstance.opco {
        case .bge:
            descriptionLabel.text = "Your Customer Account Number can be found in the lower right portion of your bill. Please enter 10-digits including leading zeros."
        case .comEd:
            descriptionLabel.text = "Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes."
        case .peco:
            descriptionLabel.text = "Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts."
        }
        
        descriptionLabel.setLineHeight(lineHeight: 25)
        descriptionLabel.textColor = .deepGray
    }

    @IBAction func onCloseButtonPress() {
        dismiss(animated: true, completion: nil)
    }

}
