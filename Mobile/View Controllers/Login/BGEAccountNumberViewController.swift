//
//  BGEAccountNumberViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class BGEAccountNumberViewController: UIViewController {
    
    let viewModel = ForgotUsernameViewModel()

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
        viewModel.accountNumberNotEmpty().bindTo(nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        instructionLabel.textColor = .darkJungleGreen
        instructionLabel.text = NSLocalizedString("The information entered is associated with multiple accounts. Please enter the account number you would like to proceed with.", comment: "")

        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        //accountNumberTextField.textField.keyboardType = .numberPad
        accountNumberTextField.textField.returnKeyType = .done
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bindTo(viewModel.accountNumber).addDisposableTo(disposeBag)
    }

    func onNextPress() {
        view.endEditing(true)
        
        viewModel.validateAccount(onSuccess: { 
            print("success!")
        }, onNeedAccountNumber: {
            // wont happen?
        }, onError: { errorMessage in
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    

}
