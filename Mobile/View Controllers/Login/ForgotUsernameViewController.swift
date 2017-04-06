//
//  ForgotUsernameViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class ForgotUsernameViewController: UIViewController {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var identifierDescriptionLabel: UILabel?
    @IBOutlet weak var identifierTextField: FloatLabelTextField?
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField?
    @IBOutlet weak var accountLookupToolButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        view.backgroundColor = .primaryColor
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton

        instructionLabel.textColor = .darkJungleGreen
        instructionLabel.text = NSLocalizedString("Please help us validate your account", comment: "")
        identifierDescriptionLabel?.text = NSLocalizedString("Last 4 Digits of primary account holder’s Social Security Number, Business Tax ID, or BGE PIN", comment: "")
        
        phoneNumberTextField.textField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.textField.returnKeyType = .next
        
        identifierTextField?.textField.placeholder = NSLocalizedString("SSN/Business Tax ID/BGE Pin*", comment: "")
        identifierTextField?.textField.autocorrectionType = .no
        identifierTextField?.textField.returnKeyType = .done
        
        accountNumberTextField?.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField?.textField.autocorrectionType = .no
        accountNumberTextField?.textField.returnKeyType = .done
        
        accountLookupToolButton?.setTitle(NSLocalizedString("Account Lookup Tool", comment: ""), for: .normal)
        accountLookupToolButton?.setTitleColor(.mediumPersianBlue, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.backgroundColor = .primaryColor
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "OpenSans-Bold", size: 18)!
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onNextPress() {
        print("next")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }



}
