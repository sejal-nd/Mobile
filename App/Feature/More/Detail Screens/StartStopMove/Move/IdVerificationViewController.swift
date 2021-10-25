//
//  IDVerificationViewController.swift
//  EUMobile
//
//  Created by Aman Vij on 21/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class IdVerificationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var ssnTextField: FloatLabelTextField!
    @IBOutlet weak var driverLicenseTextField: FloatLabelTextField!
    @IBOutlet weak var employmentStatusHintLabel: UILabel!
    @IBOutlet weak var employmentStatusLabel: UILabel!
    @IBOutlet weak var employmentStatusView: UIView!
    @IBOutlet weak var employmentStatusStackView: UIStackView!
    @IBOutlet weak var dobView: UIView!
    @IBOutlet weak var dobStackView: UIStackView!
    @IBOutlet weak var dobHintLabel: UILabel!
    @IBOutlet weak var dobLabel: UILabel!
    
    private var datePicker: UIDatePicker!
    private var blurEffectView: UIVisualEffectView!
    private var datePickerConstraints: NSLayoutConstraint!
    
    private var hideSSNText:Bool = true
    var moveDataFlow: MoveServiceFlowData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTextFields()
    }
    
    private func configureTextFields(){
        ssnTextField.placeholder = NSLocalizedString("SSN/Business Tax ID", comment: "")
        ssnTextField.textField.isSecureTextEntry = true
        ssnTextField.textField.delegate = self
        ssnTextField.textField.keyboardType = .numberPad
        
        driverLicenseTextField.placeholder = NSLocalizedString("Driver's License/State ID", comment: "")
        driverLicenseTextField.textField.delegate = self
        driverLicenseTextField.textField.keyboardType = .namePhonePad
        
        employmentStatusView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
        employmentStatusStackView.isHidden = true
        dobView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
        dobStackView.isHidden = true
    }
    
    @objc func ssnDonePressed() {
        ssnTextField.textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case ssnTextField.textField:
            //            let isNumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
            let isValidTextCount = ssnTextField.textField.text?.count < 9
            let char = string.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            if isBackSpace == -92 {
                return true
            }
            return isValidTextCount
        case driverLicenseTextField.textField:
            let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: [])
            let isValidTextCount = driverLicenseTextField.textField.text?.count < 15
            let char = string.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            if isBackSpace == -92 {
                return true
            }
            if regex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count)) != nil {
                return false
            }
            return isValidTextCount
        default:
            return false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == ssnTextField.textField {
            ssnTextField.textField.becomeFirstResponder()
            validateSSN()
        }
        //        continueButton.isEnabled = viewModel.canEnableContinue
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == ssnTextField.textField {
            ssnTextField.setError(nil)
        }
    }
    
    private func validateSSN() {
        if (ssnTextField.textField.text?.count > 0 && ssnTextField.textField.text?.count <= 9 ){
            ssnTextField.setError("Error: Social Security Number or Tax ID must be 9 digits")
        }
    }
    
    @IBAction func onToolTipClicked(_ sender: Any) {
        
        let alertViewController = InfoAlertController(title: NSLocalizedString("Verifying Your Identity", comment: ""),
                                                      message: "In case we can’t identify you by your social security number, we can use your: \n\nDriver’s license number \nState ID number \nPassport number")
        present(alertViewController, animated: true)
    }
    
    @IBAction func showHideSSNText(sender: UIButton) {
        if hideSSNText {
            sender.setImage(UIImage(named: "ic_eyeball"), for: .normal)
            ssnTextField.textField.isSecureTextEntry = false
        } else {
            sender.setImage(UIImage(named:"ic_eyeball_disabled"), for: .normal)
            ssnTextField.textField.isSecureTextEntry = true
        }
        hideSSNText = !hideSSNText
    }
    
    @IBAction func onEmploymentStatusClicked(_ sender: Any){
        PickerView.showStringPicker(
            withTitle: "Select Employment Status", data: ["Employed more than 3 years", "Employed less than 3 years", "Retired", "Receives Assistance", "Other"], selectedIndex: 0,
            onDone: { [weak self] value, index in
                self?.employmentStatusLabel.text = value
                self?.employmentStatusStackView.isHidden = false
                self?.employmentStatusHintLabel.isHidden = true
            },
            onCancel: nil)
    }
    
    @IBAction func showDatePicker() {
        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
        let datePickerViewController = storyboard.instantiateViewController(withIdentifier: "DatePickerViewController") as! DatePickerViewController
        datePickerViewController.modalPresentationStyle = .fullScreen
        datePickerViewController.delegate = self
        self.present(datePickerViewController, animated: true, completion: nil)
    }
    
    private func validateAge(selectedDate: Date) -> Bool {
        let minAge = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        if (selectedDate > minAge){
            return true
        } else{
            return false
        }
    }
    
    @IBAction func onContinueClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
        let reviewStopServiceViewController = storyboard.instantiateViewController(withIdentifier: "ReviewMoveServiceViewController") as! ReviewMoveServiceViewController
        reviewStopServiceViewController.moveFlowData = moveDataFlow
        self.navigationController?.pushViewController(reviewStopServiceViewController, animated: true)
    }
}

extension IdVerificationViewController: DateViewDelegate {
    func getSelectedDate(_ date: Date) {
        self.dobLabel.text = DateFormatter.mmDdYyyyFormatter.string(from: date)
        self.dobStackView.isHidden = false
        self.dobHintLabel.isHidden = true
        self.validateAge(selectedDate: date)
    }
}
