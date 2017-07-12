//
//  ForgotUsernameBGEAccountNumberViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class ForgotUsernameBGEAccountNumberViewController: UIViewController {
    
    let viewModel = ForgotUsernameViewModel(authService: ServiceFactory.createAuthenticationService())

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    var nextButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
        viewModel.accountNumberHasTenDigits().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("The information entered is associated with multiple accounts. Please enter the account number you would like to proceed with.", comment: "")

        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.textField.returnKeyType = .done
        accountNumberTextField?.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.accountNumber.value.characters.count > 0 {
                self.viewModel.accountNumberHasTenDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.accountNumberTextField.setError(NSLocalizedString("Account number must be 10 digits long.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.accountNumberTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
    }
    
    private func accessibilityErrorLabel() {
        self.nextButton.accessibilityLabel = NSLocalizedString(accountNumberTextField.getError(), comment: "")
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.validateAccount(onSuccess: {
            LoadingView.hide()
            self.performSegue(withIdentifier: "forgotUsernameResultSegue", sender: self)
        }, onNeedAccountNumber: { // Should not happen here
            LoadingView.hide()
        }, onError: { title, message in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Where to Look for Your Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: NSLocalizedString("Your Customer Account Number can be found in the lower right portion of your bill. Please enter 10-digits including leading zeros.", comment: ""))
        self.navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ForgotUsernameResultViewController {
            vc.viewModel = viewModel
        }
    }
    
}

extension ForgotUsernameBGEAccountNumberViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 10
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.accountNumberHasTenDigits().single().subscribe(onNext: { valid in
            if valid {
                self.onNextPress()
            } else {
                self.view.endEditing(true)
            }
        }).addDisposableTo(disposeBag)
        
        return false
    }
    
}
