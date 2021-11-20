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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseUtility.logScreenView(.unauthMoveValidationView(className: self.className))
    }
    
    private func initialSetup() {
        
        addCloseButton()
        ssnTextField.placeholder = NSLocalizedString("SSN/Business Tax ID/BGE Pin*", comment: "")
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
        
        continueButton.accessibilityLabel = NSLocalizedString("Continue Move Request", comment: "")
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
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default)
        { [weak self] _ in
            guard let `self` = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)
        { [weak self] _ in
            guard let `self` = self else { return }
            self.loadAccounts()
        }
        FirebaseUtility.logEvent(.unauthMoveService(parameters: [.api_error]))
        DispatchQueue.main.async {
            self.presentAlert(title: NSLocalizedString("We're experiencing technical issues", comment: ""),
                               message: NSLocalizedString("We can't retrieve the data you requested.\nPlease try again later.", comment: ""),
                               style: .alert,
                               actions: [cancelAction, okAction])
        }
    }
    
    private func showLoginFailedError() {
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default)
        { [weak self] _ in
            guard let `self` = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        let contactUsAction = UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default)
        { _ in
            UIApplication.shared.openPhoneNumberIfCan("1-800-685-0123")
        }
        FirebaseUtility.logEvent(.unauthMoveService(parameters: [.validation_error]))
        DispatchQueue.main.async {
            self.presentAlert(title: NSLocalizedString("That doesn't match our records.", comment: ""),
                               message: NSLocalizedString("Please try again.\nIf you need assistance, contact Customer Service at 1-800-685-0123.", comment: ""),
                               style: .alert,
                               actions: [cancelAction, contactUsAction])
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
        
        self.view.endEditing(true)
        loadAccounts()
    }
    
    func loadAccounts() {
        
        LoadingView.show()
        viewModel.loadAccounts { [weak self] in
            guard let `self` = self else { return }
            LoadingView.hide()
            if self.viewModel.isAccountResidential {
                if self.viewModel.accounts.count > 1 {
                    let storyboard = UIStoryboard(name: "ISUMUnauthMove", bundle: nil)
                    let accountSelectionViewController = storyboard.instantiateViewController(withIdentifier: "UnauthenticatedMoveAccountSelectionViewController") as! UnauthenticatedMoveAccountSelectionViewController
                    accountSelectionViewController.viewModel = UnauthenticatedMoveAccountSelectionViewModel(unauthMoveData: self.viewModel.getUnauthMoveFlowData())
                    self.navigationController?.pushViewController(accountSelectionViewController, animated: true)
                } else {
                    let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                    let moveServiceViewController = storyboard.instantiateViewController(withIdentifier: "MoveLandingViewController") as! MoveLandingViewController
                    moveServiceViewController.viewModel.unauthMoveData = self.viewModel.getUnauthMoveFlowData()
                    self.navigationController?.pushViewController(moveServiceViewController, animated: true)
                }
            } else {
                UIApplication.shared.openUrlIfCan(self.viewModel.moveServiceWebURL)
            }
        } onError: { [weak self] error in
            LoadingView.hide()
            if error == .accountNotFound {
                self?.showLoginFailedError()
            } else {
                self?.showAPIError()
            }
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
