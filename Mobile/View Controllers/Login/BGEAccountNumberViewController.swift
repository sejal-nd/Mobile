//
//  BGEAccountNumberViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import MBProgressHUD

class BGEAccountNumberViewController: UIViewController {
    
    let viewModel = ForgotUsernameViewModel(authService: ServiceFactory.createAuthenticationService())

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
        viewModel.accountNumberHasTenDigits().bindTo(nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        instructionLabel.textColor = .darkJungleGreen
        instructionLabel.text = NSLocalizedString("The information entered is associated with multiple accounts. Please enter the account number you would like to proceed with.", comment: "")

        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.textField.returnKeyType = .done
        accountNumberTextField?.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bindTo(viewModel.accountNumber).addDisposableTo(disposeBag)
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.accountNumber.value.characters.count > 0 {
                self.viewModel.accountNumberHasTenDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.accountNumberTextField.setError(NSLocalizedString("Account number must be 10 digits long.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.accountNumberTextField.setError(nil)
        }).addDisposableTo(disposeBag)
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
        hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        hud.contentColor = .white
        
        viewModel.validateAccount(onSuccess: {
            hud.hide(animated: true)
            self.performSegue(withIdentifier: "forgotUsernameResultSegue", sender: self)
        }, onNeedAccountNumber: {
            // wont happen?
            hud.hide(animated: true)
        }, onError: { title, message in
            hud.hide(animated: true)
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: ForgotUsernameResultViewController.self) {
            let vc = segue.destination as! ForgotUsernameResultViewController
            vc.viewModel = viewModel
        }
    }
    
}

extension BGEAccountNumberViewController: UITextFieldDelegate {
    
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
