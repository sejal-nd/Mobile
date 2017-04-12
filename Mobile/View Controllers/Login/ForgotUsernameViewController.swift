//
//  ForgotUsernameViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class ForgotUsernameViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var identifierDescriptionLabel: UILabel?
    @IBOutlet weak var identifierTextField: FloatLabelTextField?
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField?
    @IBOutlet weak var accountLookupToolButton: UIButton?
    
    let viewModel = ForgotUsernameViewModel()
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
        viewModel.nextButtonEnabled().bindTo(nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        instructionLabel.textColor = .darkJungleGreen
        instructionLabel.text = NSLocalizedString("Please help us validate your account", comment: "")
        identifierDescriptionLabel?.text = NSLocalizedString("Last 4 Digits of primary account holder’s Social Security Number, Business Tax ID, or BGE PIN", comment: "")
        
        phoneNumberTextField.textField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.textField.returnKeyType = .next
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bindTo(viewModel.phoneNumber).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.phoneNumber.value.characters.count > 0 {
                self.viewModel.phoneNumberHasTenDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.phoneNumberTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        identifierTextField?.textField.placeholder = NSLocalizedString("SSN/Business Tax ID/BGE Pin*", comment: "")
        identifierTextField?.textField.autocorrectionType = .no
        identifierTextField?.textField.returnKeyType = .done
        identifierTextField?.textField.delegate = self
        identifierTextField?.textField.rx.text.orEmpty.bindTo(viewModel.identifierNumber).addDisposableTo(disposeBag)
        identifierTextField?.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.identifierNumber.value.characters.count > 0 {
                self.viewModel.identifierHasFourDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.identifierTextField?.setError(NSLocalizedString("This number must be 4 digits long.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
                self.viewModel.identifierIsNumeric().single().subscribe(onNext: { numeric in
                    if !numeric {
                        self.identifierTextField?.setError(NSLocalizedString("This number must be numeric.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        identifierTextField?.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.identifierTextField?.setError(nil)
        }).addDisposableTo(disposeBag)
        
        accountNumberTextField?.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField?.textField.autocorrectionType = .no
        accountNumberTextField?.textField.returnKeyType = .done
        accountNumberTextField?.textField.delegate = self
        accountNumberTextField?.textField.isShowingAccessory = true
        accountNumberTextField?.textField.rx.text.orEmpty.bindTo(viewModel.accountNumber).addDisposableTo(disposeBag)
        
        accountLookupToolButton?.setTitle(NSLocalizedString("Account Lookup Tool", comment: ""), for: .normal)
        accountLookupToolButton?.setTitleColor(.mediumPersianBlue, for: .normal)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.isTranslucent = false

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
        view.endEditing(true)
        
        viewModel.validateAccount(onSuccess: { 
            print("success")
        }, onNeedAccountNumber: {
            self.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
        }, onError: { errorMessage in
            let alertController = UIAlertController(title: NSLocalizedString("Invalid Information", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: BGEAccountNumberViewController.self) {
            let vc = segue.destination as! BGEAccountNumberViewController
            vc.viewModel.phoneNumber.value = viewModel.phoneNumber.value
            vc.viewModel.identifierNumber.value = viewModel.identifierNumber.value
        } else if segue.destination.isKind(of: AccountLookupToolViewController.self) {
            let vc = segue.destination as! AccountLookupToolViewController
            vc.viewModel.phoneNumber.value = viewModel.phoneNumber.value
        }
    }
    

}

extension ForgotUsernameViewController: AccountLookupToolResultViewControllerDelegate {

    func accountLookupToolResultViewController(_ accountLookupToolResultViewController: AccountLookupToolResultViewController, didSelectAccount accountNumber: String, phoneNumber: String) {
        viewModel.phoneNumber.value = phoneNumber
        phoneNumberTextField.textField.text = phoneNumber
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd)
        
        viewModel.accountNumber.value = accountNumber
        accountNumberTextField?.textField.text = accountNumber
        accountNumberTextField?.textField.sendActions(for: .editingDidEnd)
    }
    
}

extension ForgotUsernameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneNumberTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 10 {
               return false
            }

            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if length - index > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            
            textField.sendActions(for: .valueChanged) // Send rx events
            
            return false
        } else if textField == identifierTextField?.textField {
            return newString.characters.count <= 4
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == phoneNumberTextField.textField {
            if let idTextField = identifierTextField {
                 idTextField.textField.becomeFirstResponder()
            } else {
                accountNumberTextField?.textField.becomeFirstResponder()
            }
           
        } else if textField == identifierTextField?.textField || textField == accountNumberTextField?.textField {
            viewModel.nextButtonEnabled().single().subscribe(onNext: { enabled in
                if enabled {
                    self.onNextPress()
                } else {
                    self.view.endEditing(true)
                }
            }).addDisposableTo(disposeBag)
        }
        return false
    }
}
