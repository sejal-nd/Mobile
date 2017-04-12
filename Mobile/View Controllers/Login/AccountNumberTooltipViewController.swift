//
//  AccountNumberTooltipViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountNumberTooltipViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    //@IBOutlet weak var billImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = NSLocalizedString("Where to Look for Your Account Number", comment: "")
        titleLabel.textColor = .darkJungleGreen
        
        var descriptionText = ""
        switch Environment.sharedInstance.opco {
        case "BGE":
            descriptionText = "It is located in the upper right portion of your bill. Please enter all 10 digits, including leading zeros, but no dashes. If “SUMM” appears after your name on your bill, please enter any account from your list of individual accounts."
            break
        case "ComEd":
            descriptionText = "It is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes. If “SUMM” appears after your name on your bill, please enter any account from your list of individual accounts."
            break
        case "PECO":
            descriptionText = "It is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeros, but no dashes. If “SUMM” appears after your name on your bill, please enter any account from your list of individual accounts."
            break
        default:
            break
        }
        descriptionLabel.text = descriptionText
        descriptionLabel.setLineHeight(lineHeight: 25)
        descriptionLabel.textColor = .outerSpace
    }

    @IBAction func onCloseButtonPress() {
        dismiss(animated: true, completion: nil)
    }

}
