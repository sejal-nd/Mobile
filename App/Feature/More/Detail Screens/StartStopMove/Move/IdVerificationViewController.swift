//
//  IDVerificationViewController.swift
//  EUMobile
//
//  Created by Aman Vij on 21/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

protocol IdVerificationDelegate {
    func getIdVerification(_ id: IdVerification)
}

class IdVerificationViewController: KeyboardAvoidingStickyFooterViewController {
    
    @IBOutlet weak var ssnTextField: FloatLabelTextField!
    @IBOutlet weak var driverLicenseTextField: FloatLabelTextField!
    @IBOutlet weak var employmentStatusHintLabel: UILabel!
    @IBOutlet weak var employmentStatusLabel: UILabel!
    @IBOutlet weak var employmentStatusView: UIView!
    @IBOutlet weak var employmentStatusStackView: UIStackView!
    @IBOutlet weak var dobTextField: FloatLabelTextField!
    @IBOutlet weak var continueButton: PrimaryButton!

    private var datePicker: UIDatePicker!
    private var blurEffectView: UIVisualEffectView!
    private var datePickerConstraints: NSLayoutConstraint!
    var isLaunchedFromReviewScreen: Bool = false

    var viewModel: IdVerificationViewModel!
    var delegate: IdVerificationDelegate!
    
    private var hideSSNText:Bool = true
    var dateAlert: UIAlertController!

    override func viewDidLoad() {
        super.viewDidLoad()

        if isLaunchedFromReviewScreen {
            viewModel.setIDVerification(viewModel.moveDataFlow)
        }
        configureTextFields()
    }
    
    private func configureTextFields(){
        
        self.navigationItem.hidesBackButton = true
        let backButtonIconName = isLaunchedFromReviewScreen ? "ic_close" : "ic_back"
        let backButtonAccesibilityLabelText = isLaunchedFromReviewScreen ? "Close" : "Back"
        let newBackButton = UIBarButtonItem(image: UIImage(named: backButtonIconName), style: UIBarButtonItem.Style.plain, target: self, action: #selector(FinalMailingAddressViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        if isLaunchedFromReviewScreen {
            continueButton.setTitle(NSLocalizedString("Save Changes", comment: ""), for: .normal)
        } else {
            continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        }
        
        ssnTextField.placeholder = NSLocalizedString("SSN/Business Tax ID", comment: "")
        ssnTextField.textField.isSecureTextEntry = true
        ssnTextField.textField.delegate = self
        ssnTextField.textField.keyboardType = .numberPad
        ssnTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(ssnDonePressed))

        driverLicenseTextField.placeholder = NSLocalizedString("Driver's License/State ID", comment: "")
        driverLicenseTextField.textField.delegate = self
        driverLicenseTextField.textField.keyboardType = .default
        driverLicenseTextField.textField.returnKeyType = .done

        employmentStatusView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
        employmentStatusStackView.isHidden = true

        dobTextField.placeholder = NSLocalizedString("Date of Birth*", comment: "")
        
        ssnTextField.textField.text = self.viewModel.moveDataFlow.idVerification?.ssn
        driverLicenseTextField.textField.text = self.viewModel.moveDataFlow.idVerification?.driverLicenseNumber
        if let dateOfBirth = viewModel.moveDataFlow.idVerification?.dateOfBirth {
            self.dobTextField.textField.text = DateFormatter.mmDdYyyyFormatter.string(from: dateOfBirth)
        }
        if let employmentStatus = viewModel.idVerification.employmentStatus {
            self.employmentStatusLabel.text = employmentStatus.0
            self.employmentStatusStackView.isHidden = false
            self.employmentStatusHintLabel.isHidden = true
            self.continueButton.isEnabled = self.viewModel.validation() 
        }
    }
    
    @objc func ssnDonePressed() {
        ssnTextField.textField.resignFirstResponder()
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if isLaunchedFromReviewScreen {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func validateSSN() {
        
        if let ssn = ssnTextField.textField.text, !viewModel.isValidSSN(ssn: ssn){
            ssnTextField.setError("Social Security Number or Tax ID must be 9 digits")
        } else {
            ssnTextField.setError(nil)
        }
        viewModel.idVerification.ssn = ssnTextField.textField.text
        self.continueButton.isEnabled = viewModel.validation()
    }
    
    func showDatePicker() {
        
        let datePicker = UIDatePicker()
        datePicker.date = viewModel.idVerification.dateOfBirth ?? Date()
        datePicker.datePickerMode = .date
        datePicker.locale = .current
        datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        datePicker.preferredDatePickerStyle = .inline

        dateAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        dateAlert.view.addSubview(datePicker)
        datePicker.center = CGPoint(x: dateAlert.view.center.x, y: 180)
        dateAlert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            self.handleDateSelection(sender: datePicker)
        }))
        dateAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        dateAlert.view.heightAnchor.constraint(equalToConstant: 440).isActive = true
        self.present(dateAlert, animated: true, completion: nil)
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
        
        self.ssnTextField.textField.resignFirstResponder()
        self.driverLicenseTextField.textField.resignFirstResponder()
        PickerView.showStringPicker(
            withTitle: "Select Employment Status", data: ["Employed more than 3 years", "Employed less than 3 years", "Retired", "Receives Assistance", "Other"], selectedIndex: 0,
            onDone: { [weak self] value, index in
                self?.employmentStatusLabel.text = value
                self?.employmentStatusStackView.isHidden = false
                self?.employmentStatusHintLabel.isHidden = true
                self?.viewModel.idVerification.employmentStatus = (value, index)
                self?.continueButton.isEnabled = self?.viewModel.validation() ?? false
            },
            onCancel: nil)
    }
    
    @objc func handleDateSelection(sender: UIDatePicker) {
        
        dateAlert.dismiss(animated: true, completion: nil)
        viewModel.idVerification.dateOfBirth = sender.date
        self.dobTextField.textField.text = DateFormatter.mmDdYyyyFormatter.string(from: sender.date)
        
        if viewModel.validateAge(selectedDate: sender.date) {
            dobTextField.setError(nil)
            self.viewModel.idVerification.dateOfBirth = sender.date
        } else {
            self.viewModel.idVerification.dateOfBirth = nil
            dobTextField.setError("Applicants must be 18 or older in order to request and maintain a BGE account.")
        }
        self.continueButton.isEnabled = viewModel.validation()
    }
    
    @IBAction func onDOBClicked(_ sender: Any) {
        
        self.ssnTextField.textField.resignFirstResponder()
        self.driverLicenseTextField.textField.resignFirstResponder()
        showDatePicker()
    }
    
    @IBAction func onContinueClicked(_ sender: Any) {
        if isLaunchedFromReviewScreen {
            delegate.getIdVerification(viewModel.idVerification)
            self.dismiss(animated: true, completion: nil)
        } else {
            let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
            let reviewStopServiceViewController = storyboard.instantiateViewController(withIdentifier: "ReviewMoveServiceViewController") as! ReviewMoveServiceViewController
            viewModel.moveDataFlow.idVerification = viewModel.idVerification
            reviewStopServiceViewController.moveFlowData = viewModel.moveDataFlow
            self.navigationController?.pushViewController(reviewStopServiceViewController, animated: true)

        }
    }
}

extension IdVerificationViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        switch textField {
        case ssnTextField.textField:
            let isValidSSN = viewModel.isValidSSN(ssn: newString, inputString: string)
            if isValidSSN {
                self.viewModel.idVerification.ssn = newString
            }
            self.continueButton.isEnabled = viewModel.validation()
            return isValidSSN
        case driverLicenseTextField.textField:
            return viewModel.isValidDrivingLicense(drivingLicense: driverLicenseTextField.textField.text ?? "", inputString: string)
        default:
            return false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == ssnTextField.textField {
            validateSSN()
        }
        if textField == driverLicenseTextField.textField {
            self.viewModel.idVerification.driverLicenseNumber = driverLicenseTextField.textField.text
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == ssnTextField.textField {
            ssnTextField.setError(nil)
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
