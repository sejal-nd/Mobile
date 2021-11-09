//
//  UnauthIdentityVerificationViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 30/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class UnauthIdentityVerificationViewController: KeyboardAvoidingStickyFooterViewController {

    @IBOutlet weak var ssnTextField: FloatLabelTextField!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var continueButton: PrimaryButton!

    let viewModel = UnauthIdentityVerificationViewModel()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        initialSetup()
    }
    
    private func initialSetup() {
        
        addCloseButton()
        ssnTextField.placeholder = NSLocalizedString("SSN/Tax ID/BGE Pin*", comment: "")
        ssnTextField.textField.isSecureTextEntry = true
        ssnTextField.textField.delegate = self
        ssnTextField.textField.keyboardType = .phonePad
        ssnTextField.textField.returnKeyType = .done
        ssnTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(ssnDonePressed))

        phoneNumberTextField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.keyboardType = .numberPad
        phoneNumberTextField.textField.returnKeyType = .done
        phoneNumberTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(phoneNumberDonePressed))
    }
    
    @objc func phoneNumberDonePressed() {
        
        phoneNumberTextField.textField.resignFirstResponder()
    }
    
    @objc func ssnDonePressed() {
        
        ssnTextField.textField.resignFirstResponder()
    }
    
    private func validateSSN() {
        
        if let ssn = ssnTextField.textField.text, !viewModel.isValidSSN(ssn) {
            ssnTextField.setError("SSN/Business Tax ID/BGE Pin must be 4 digits")
        } else {
            ssnTextField.setError(nil)
        }
        viewModel.ssn = ssnTextField.textField.text ?? ""
        self.continueButton.isEnabled = viewModel.validation()
    }
    
    private func validatePhoneNumber() {
        
        if let phoneNumber = phoneNumberTextField.textField.text, !viewModel.isValidPhoneNumber(phoneNumber) {
            phoneNumberTextField.setError("phone number must be 10 digits.")
        } else {
            phoneNumberTextField.setError(nil)
        }
        viewModel.phoneNumber = phoneNumberTextField.textField.text ?? ""
        self.continueButton.isEnabled = viewModel.validation()
    }
    
    private func showAPIError() {
        
        let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
        { [weak self] _ in
            guard let `self` = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        DispatchQueue.main.async {
            self.presentAlert(title: NSLocalizedString("We're experiencing technical issues ", comment: ""),
                               message: NSLocalizedString("We can't retrieve the data you requested. Please try again later. ", comment: ""),
                               style: .alert,
                               actions: [exitAction])
        }
    }

    
    @IBAction func showHideSSNText(sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.setImage(UIImage(named: "ic_eyeball"), for: .normal)
            ssnTextField.textField.isSecureTextEntry = false
        } else {
            sender.setImage(UIImage(named:"ic_eyeball_disabled"), for: .normal)
            ssnTextField.textField.isSecureTextEntry = true
        }
    }
    
    @IBAction func onContinueTapped(_ sender: UIButton) {
        
        LoadingView.show()
        self.view.endEditing(true)
        viewModel.loadAccounts { [weak self] in
            guard let `self` = self else { return }
            LoadingView.hide()
            if self.viewModel.isAccountResidential {
                if self.viewModel.accounts.count > 1 {
                    //TODO: Navigate to Account Selection
                    let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                    let moveServiceViewController = storyboard.instantiateViewController(withIdentifier: "MoveLandingViewController") as! MoveLandingViewController
                    self.navigationController?.pushViewController(moveServiceViewController, animated: true)

                } else {
                    let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                    let moveServiceViewController = storyboard.instantiateViewController(withIdentifier: "MoveLandingViewController") as! MoveLandingViewController
                    self.navigationController?.pushViewController(moveServiceViewController, animated: true)
                }
            } else {
                UIApplication.shared.openUrlIfCan(self.viewModel.moveServiceWebURL)
            }
        } onError: { [weak self] _ in
            LoadingView.hide()
            self?.showAPIError()
        }

    }
}

extension UnauthIdentityVerificationViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        switch textField {
            
        case ssnTextField.textField:
            let isValid = viewModel.isValidSSN(ssn: newString, inputString: string)
            if isValid {
                self.viewModel.ssn = newString
                ssnTextField.setError(nil)
            }
            self.continueButton.isEnabled = viewModel.validation()
            return isValid
            
        case phoneNumberTextField.textField:
            let isValid = viewModel.isValidPhoneNumber(phoneNumber: newString, inputString: string)
            if isValid {
                self.viewModel.phoneNumber = newString
                phoneNumberTextField.setError(nil)
            }
            self.continueButton.isEnabled = viewModel.validation()
            return isValid
        default:
            return false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == ssnTextField.textField {
            validateSSN()
        }
        if textField == phoneNumberTextField.textField {
            validatePhoneNumber()
        }
    }
}
