//
//  AddBankAccountViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AddBankAccountViewController: UIViewController {
    
    // Checking/Savings Segmented Control (BGE ONLY)
    // Bank account holder name (BGE ONLY)
    // Routing Number with question mark
    // Confirm routing number (BGE ONLY)
    // Account number with question mark
    // Confirm account number
    // Nickname (Optional for ComEd/PECO, required for BGE)
    // One touch pay toggle

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
    @IBOutlet weak var accountHolderNameTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var confirmRoutingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var nicknameTextField: FloatLabelTextField!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Add Bank Account", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
        //viewModel.searchButtonEnabled().bind(to: nextButton).addDisposableTo(disposeBag)

        checkingSavingsSegmentedControl.items = [NSLocalizedString("Checking", comment: ""), NSLocalizedString("Savings", comment: "")]
        
        accountHolderNameTextField.textField.placeholder = NSLocalizedString("Bank Account Holder Name*", comment: "")
        routingNumberTextField.textField.placeholder = NSLocalizedString("Routing Number*", comment: "")
        confirmRoutingNumberTextField.textField.placeholder = NSLocalizedString("Confirm Routing Number*", comment: "")
        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        confirmAccountNumberTextField.textField.placeholder = NSLocalizedString("Confirm Account Number*", comment: "")
        nicknameTextField.textField.placeholder = Environment.sharedInstance.opco == .bge ? NSLocalizedString("Nickname*", comment: "") : NSLocalizedString("Nickname (Optional)", comment: "")

        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.text = NSLocalizedString("Turn on One Touch Pay to easily pay from the Home screen and set this payment account as default.", comment: "")
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        
        if Environment.sharedInstance.opco != .bge { // BGE only fields should be removed on ComEd/PECO
            checkingSavingsSegmentedControl.isHidden = true
            accountHolderNameTextField.isHidden = true
            confirmRoutingNumberTextField.isHidden = true
        }
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onNextPress() {
        print("NEXT")
    }
    
    @IBAction func onRoutingNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Routing Number", comment: ""), image: #imageLiteral(resourceName: "routing_number_info"), description: NSLocalizedString("This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.", comment: ""))
        navigationController?.modalPresentationStyle = .formSheet
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @IBAction func onAccountNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Account Number", comment: ""), image: #imageLiteral(resourceName: "account_number_info"), description: NSLocalizedString("This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.", comment: ""))
        navigationController?.modalPresentationStyle = .formSheet
        navigationController?.present(infoModal, animated: true, completion: nil)
    }

}
